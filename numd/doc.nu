# Render a positional or rest parameter as a markdown bullet
export def render-parameter []: record -> string {
    let param = $in
    let name = if $param.parameter_type == 'rest' {
        $'...($param.parameter_name)'
    } else {
        $param.parameter_name | if $param.is_optional { $"\(($in)\)" } else { }
    }

    $name
    | if $param.syntax_shape == null { } else { $'($in): ($param.syntax_shape)' }
    | $'- `($in)`'
    | if ($param.description | default '' | is-empty) { } else { $'($in) — ($param.description)' }
}

# Render a flag as a markdown bullet
export def render-flag []: record -> string {
    let flag = $in

    $'--($flag.parameter_name)'
    | if $flag.short_flag == null { } else { $in + ' (-' + $flag.short_flag + ')' }
    | if $flag.parameter_type == 'named' { $'($in): ($flag.syntax_shape)' } else { }
    | $'- `($in)`'
    | if ($flag.description | default '' | is-empty) { } else { $'($in) — ($flag.description)' }
    | if $flag.parameter_default == null { } else { $in + ' (default: `' + ($flag.parameter_default | to nuon) + '`)' }
}

# Render one example: its description as text, the code in an inert fence
export def render-example []: record -> string {
    let example = $in

    $example.example
    | if $example.result == null { } else {
        # Why: `no-run` keeps the block inert, so the result is baked in as `# =>` lines
        $in + (char nl) + ($example.result | table | into string | lines | each { $'# => ($in)' } | str join (char nl))
    }
    | $"```nushell no-run(char nl)($in)(char nl)```"
    | if ($example.description | default '' | is-empty) { } else { $'($example.description)(char nl)(char nl)($in)' }
}

# Render markdown documentation for a single command from its `scope commands` row
export def render-command [
    name: string
    header_level: int
    no_header: bool
]: nothing -> string {
    let found = scope commands | where name == $name
    if ($found | is-empty) {
        error make {msg: $"`($name)` is neither a module nor a command in the current scope"}
    }
    let cmd = $found | first

    # signatures is a record keyed by input type; parameters and flags repeat in every entry — take the first
    let signature = $cmd.signatures | values | first
    let positionals = $signature | where parameter_type in ['positional' 'rest']
    let flags = $signature | where parameter_type in ['switch' 'named']

    # Why: `scope commands` keys `signatures` by input type, so overloads sharing an input
    # (e.g. `string -> nothing` and `string -> string`) collapse to one entry and get lost.
    # Recover the full, ordered list by parsing the declared `[in -> out, ...]` annotation out
    # of `view source`; fall back to the collapsed `signatures` when there's no bracketed annotation.
    # Arrows are masked first so their `>` can't be mistaken for a generic close when splitting
    # pairs on top-level commas — keeps complex types like `table<a: int, b: str>` whole.
    let declared_io = try { view source $name } catch { '' }
        | parse --regex '(?s)\]:\s*\[(?<io>[^\]]*)\]'
        | get io.0?
        | default ''
        | str replace --all --regex '\s*->\s*' "\u{1}"
        | str replace --all --regex ',(?![^<]*>)' "\u{2}"
        | split row "\u{2}"
        | each { split row "\u{1}" | each { str trim } }
        | where { ($in | length) == 2 and ($in | all { is-not-empty }) }
        | each { $'`($in.0) -> ($in.1)`' }

    let inputs_outputs = if ($declared_io | is-not-empty) { $declared_io } else {
        $cmd.signatures
        | values
        | each {|sig|
            let input = $sig | where parameter_type == 'input' | first | get syntax_shape
            let output = $sig | where parameter_type == 'output' | first | get syntax_shape
            $'`($input) -> ($output)`'
        }
    }

    let usage = $positionals
        | each {|p|
            # Why: match nushell's own --help notation — `<req>`, `(opt)`, `...(rest)`
            if $p.parameter_type == 'rest' {
                $"...\(($p.parameter_name)\)"
            } else {
                $p.parameter_name | if $p.is_optional { $"\(($in)\)" } else { $'<($in)>' }
            }
        }
        | prepend $name
        | str join ' '

    let parameters_section = if ($positionals | is-not-empty) {
        "**Parameters:**\n\n" + ($positionals | each { render-parameter } | str join (char nl))
    }

    let flags_section = if ($flags | is-not-empty) {
        "**Flags:**\n\n" + ($flags | each { render-flag } | str join (char nl))
    }

    let examples_section = if ($cmd.examples | is-not-empty) {
        "**Examples:**\n\n" + ($cmd.examples | each { render-example } | str join "\n\n")
    }

    [
        (if not $no_header { ('' | fill --character '#' --width $header_level) + ' `' + $name + '`' })
        ([$cmd.description $cmd.extra_description] | compact --empty | str join "\n\n")
        (
            $usage
            # Why: the sole `any -> any` is the untyped default — it carries no information, so drop the comment
            | if $inputs_outputs == ['`any -> any`'] { } else { $in + '    # ' + ($inputs_outputs | str join ', ') }
            | $"```nushell no-run(char nl)($in)(char nl)```"
        )
        $parameters_section
        $flags_section
        $examples_section
    ]
    | compact --empty
    | str join "\n\n"
}

# Render markdown documentation for a module or a single command from `scope` data
@example "document one command" {
    numd doc 'numd run'
}
@example "document every command of a module, headers one level deeper" {
    numd doc numd --header-level 4
}
@example "document one command with no generated header, to sit under a hand-written header" {
    numd doc 'numd run' --no-header
}
export def main [
    target: string # a module name (documents all its commands) or a full command name (e.g. 'numd run')
    --header-level: int = 3 # markdown header level for command headers
    --no-header # omit the generated header line, so the block can sit under a hand-written header (applies to every command when target is a module)
]: nothing -> string {
    scope modules
    | where name == $target
    | if ($in | is-empty) {
        [$target]
    } else {
        first | get commands.name | each { $'($target) ($in)' }
    }
    | each { render-command $in $header_level $no_header }
    | str join "\n\n"
}
