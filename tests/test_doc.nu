use std/assert
use std/testing *

use ../numd
# the render helpers are exported for unit testing but kept out of the public API by mod.nu
use ../numd/doc.nu *

# =============================================================================
# Tests for numd doc
# =============================================================================

@test
def "doc renders a single command" [] {
    let result = numd doc 'numd run'

    assert ($result =~ '^### `numd run`')
    assert ($result =~ '```nushell no-run\nnumd run <file>    # `nothing -> string`, `nothing -> nothing`, `nothing -> record`')
    assert ($result =~ '\*\*Parameters:\*\*\n\n- `file: path` — path to a')
    assert ($result =~ '- `--dry-run` — return blocks')
}

@test
def "doc marks optional positionals in the usage line" [] {
    let result = numd doc 'numd capture start'

    # optional positionals render as `(name)`, matching nushell's own --help
    assert ($result =~ 'numd capture start \(file\)    # `nothing -> nothing`')
}

# a command with no declared io types; its sole signature is the untyped default. Module scope so `scope commands` (inside numd doc) can see it
def "untyped demo" [pos: string] { }

@test
def "doc omits the io comment when the only signature is any -> any" [] {
    let result = numd doc 'untyped demo'

    # the untyped default carries no information, so no `# ...` io comment is emitted on the usage line
    assert ($result =~ 'untyped demo <pos>\n```')
    assert (not ($result =~ 'untyped demo <pos>    #'))
}

@test
def "doc renders examples as inert fences" [] {
    let result = numd doc 'numd run'

    assert ($result =~ 'update readme\n\n```nushell no-run\nnumd run README.md\n```')
}

@test
def "doc renders flag defaults" [] {
    let result = numd doc 'numd doc'

    assert ($result =~ '- `--header-level: int` — markdown header level for command headers \(default: `3`\)')
}

@test
def "doc renders every command of a module" [] {
    let result = numd doc numd

    assert ($result =~ '### `numd run`')
    assert ($result =~ '### `numd clear-outputs`')
    assert ($result =~ '### `numd doc`')
}

@test
def "doc respects header level" [] {
    let result = numd doc 'numd run' --header-level 2

    assert ($result =~ '^## `numd run`')
}

# overloads sharing an input type collapse in `scope commands`; all four must still render
def io-overloads []: [string -> nothing, string -> string, nothing -> string, nothing -> nothing] { let x = $in; $x }

@test
def "doc keeps every declared io overload in order" [] {
    let result = numd doc 'io-overloads'

    assert ($result =~ '# `string -> nothing`, `string -> string`, `nothing -> string`, `nothing -> nothing`')
}

@test
def "doc omits the header with --no-header" [] {
    let result = numd doc 'numd run' --no-header

    assert (not ($result =~ '`numd run`'))
    # the reference itself (usage fence) is still emitted
    assert ($result =~ '```nushell no-run\nnumd run <file>')
}

@test
def "doc errors on unknown target" [] {
    let outcome = try { numd doc 'no-such-thing'; 'no-error' } catch { 'error' }

    assert equal $outcome 'error'
}

# =============================================================================
# Tests for the render helpers (exported for unit testing, not part of the public API)
# =============================================================================

@test
def "render-parameter renders a required positional with type and description" [] {
    let param = {parameter_type: 'positional' parameter_name: 'file' is_optional: false syntax_shape: 'path' description: 'a markdown file'}

    assert equal ($param | render-parameter) '- `file: path` — a markdown file'
}

@test
def "render-parameter wraps an optional positional in parentheses" [] {
    let param = {parameter_type: 'positional' parameter_name: 'file' is_optional: true syntax_shape: 'path' description: ''}

    assert equal ($param | render-parameter) '- `(file): path`'
}

@test
def "render-parameter prefixes a rest parameter with dots" [] {
    let param = {parameter_type: 'rest' parameter_name: 'paths' is_optional: true syntax_shape: 'string' description: 'extra paths'}

    assert equal ($param | render-parameter) '- `...paths: string` — extra paths'
}

@test
def "render-parameter omits the type when syntax_shape is null" [] {
    let param = {parameter_type: 'positional' parameter_name: 'thing' is_optional: false syntax_shape: null description: ''}

    assert equal ($param | render-parameter) '- `thing`'
}

@test
def "render-flag renders a switch with no type" [] {
    let flag = {parameter_type: 'switch' parameter_name: 'echo' short_flag: null syntax_shape: null description: 'output to stdout' parameter_default: null}

    assert equal ($flag | render-flag) '- `--echo` — output to stdout'
}

@test
def "render-flag renders a named flag with short alias, type and default" [] {
    let flag = {parameter_type: 'named' parameter_name: 'header-level' short_flag: 'l' syntax_shape: 'int' description: 'header level' parameter_default: 3}

    assert equal ($flag | render-flag) '- `--header-level (-l): int` — header level (default: `3`)'
}

@test
def "render-flag omits type and default when absent" [] {
    let flag = {parameter_type: 'switch' parameter_name: 'dry-run' short_flag: null syntax_shape: null description: '' parameter_default: null}

    assert equal ($flag | render-flag) '- `--dry-run`'
}

@test
def "render-example renders a described example as an inert fence" [] {
    let example = {description: 'list files' example: 'ls' result: null}

    assert equal ($example | render-example) "list files\n\n```nushell no-run\nls\n```"
}

@test
def "render-example bakes the result in as output lines" [] {
    let example = {description: '' example: '1 + 1' result: 2}

    assert equal ($example | render-example) "```nushell no-run\n1 + 1\n# => 2\n```"
}
