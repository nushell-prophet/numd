const numdinternals = ([numd commands.nu] | path join)
use $numdinternals [ build-modified-path compute-change-stats ]

export def main [] { }

# Run all tests (unit + integration)
#
# Output mode is auto-detected: when stdout is a terminal you get the human view
# (failures + a summary line); when it is piped or redirected you get machine-readable
# JSON. Force either with --json / --pretty.
export def 'main test' [
    --json # force machine-readable JSON output even on a terminal
    --pretty # force the human view even when output is piped
    --all # human view: also list passing tests (default shows only non-passing)
    --update # accept changes: stage modified integration test files
    --fail # exit with non-zero code if any tests fail (for CI)
] {
    let results = (collect-unit-results) | append (collect-integration-results --update=$update)

    if (machine-mode --json=$json --pretty=$pretty) {
        print ($results | to json --raw)
    } else {
        print-human $results --all=$all --update=$update
    }

    if $fail and ($results | where status == 'failed' | is-not-empty) {
        exit 1
    }
}

# Run unit tests using nutest
#
# Machine (JSON / piped) rows use the flat schema:
#   {type: 'unit', name, status: 'passed'|'failed', file: null, message}
# Note: status is 'passed'|'failed', NOT nutest's 'PASS'|'FAIL' 'result' column.
# message holds the assertion text on failure, null otherwise.
export def 'main test-unit' [
    --json # force machine-readable JSON output even on a terminal
    --pretty # force the human view even when output is piped
    --all # human view: also list passing tests (default shows only failures)
] {
    let flat = collect-unit-results
    if (machine-mode --json=$json --pretty=$pretty) {
        $flat | to json --raw
    } else {
        print-human $flat --all=$all
    }
}

# Run integration tests (execute example markdown files)
#
# Machine rows use the flat schema:
#   {type: 'integration', name, status: 'passed'|'changed'|'failed', file, message}
export def 'main test-integration' [
    --json # force machine-readable JSON output even on a terminal
    --pretty # force the human view even when output is piped
    --all # human view: also list passing tests (default shows only non-passing)
    --update # accept changes: stage modified files in git
] {
    let flat = collect-integration-results --update=$update
    if (machine-mode --json=$json --pretty=$pretty) {
        $flat | to json --raw
    } else {
        print-human $flat --all=$all --update=$update
    }
}

# Decide whether to emit machine-readable data instead of the human view.
# Why: agents capture stdout through a pipe, humans read it in a terminal.
# Not $nu.is-interactive because: it reports REPL-ness, not human-ness — it is false for
# any `nu toolkit.nu ...` script run (human or agent) and true for an agent driving the
# nushell MCP, so it detects the opposite of what we need. is-terminal --stdout is the tty test.
def machine-mode [--json --pretty]: nothing -> bool {
    if $pretty { return false } # Not-piped override wins over everything
    if $json { return true }
    not (is-terminal --stdout)
}

# Collect unit test results as flat rows (no output side effects)
def collect-unit-results []: nothing -> table {
    use ../nutest/nutest

    nutest run-tests --path tests/ --returns table --display nothing
    | each {|row|
        let status = if $row.result == 'PASS' { 'passed' } else { 'failed' }
        let message = if $status == 'failed' {
            let msgs = $row.output | each {|o| $o.msg? } | compact
            if ($msgs | is-empty) { null } else { $msgs | str join '; ' }
        } else { null }
        {type: 'unit' name: $row.test status: $status file: null message: $message}
    }
}

# Collect integration test results as flat rows (executes example markdown files)
def collect-integration-results [--update]: nothing -> table {
    use numd

    # will be executed if dotnu-embeds-are-available
    update-dotnu-embeds

    # path join is used for windows compatability
    let path_simple_table = [z_examples 5_simple_nu_table simple_nu_table.md] | path join

    # clear outputs from simple markdown
    let simple_md = ['z_examples' '1_simple_markdown' 'simple_markdown.md'] | path join
    numd clear-outputs $simple_md --echo
    | save -f ($simple_md | build-modified-path --suffix '_with_no_output')

    # Run all integration tests and collect results
    let results = (
        # Strip markdown and run main set of .md files in one loop
        glob z_examples/*/*.md --exclude [
            */*_with_no_output*
            */*_customized*
            */8_parse_frontmatter
            */run_once*
        ]
        | par-each --keep-order {|file|
            run-integration-test $file {
                # Strip markdown
                let strip_markdown_path = $file
                    | path parse
                    | get stem
                    | $in + '.nu'
                    | [z_examples 99_strip_markdown $in]
                    | path join

                numd clear-outputs $file --strip-markdown --echo
                | save -f $strip_markdown_path

                # Run files with config set
                numd run $file --save-intermed-script $'($file)_intermed.nu' --eval (open -r ([z_examples numd_config_example1.nu] | path join)) --ignore-git-check
            }
        }
        # Run file with customized width of table
        | append (
            run-integration-test ($path_simple_table | build-modified-path --suffix '_customized_width20') {
                let target = $path_simple_table | build-modified-path --suffix '_customized_width20'
                numd run $path_simple_table --echo --no-stats --eval '$env.numd.table-width = 20'
                | ansi strip
                | save -f $target
            }
        )
        # Run file with another config
        | append (
            run-integration-test ($path_simple_table | build-modified-path --suffix '_customized_example_config') {
                let target = $path_simple_table | build-modified-path --suffix '_customized_example_config'
                numd run $path_simple_table --echo --no-stats --eval (open -r ([z_examples numd_config_example2.nu] | path join))
                | ansi strip
                | save -f $target
            }
        )
        # Run run-once test via --echo (file mutates by design, so we assert on output instead)
        | append (
            run-integration-test 'z_examples/6_edge_cases/run_once.md' {
                let output = numd run z_examples/6_edge_cases/run_once.md --echo --no-stats
                if ($output !~ '```nu no-run') or ($output =~ '```nu run-once') {
                    error make {msg: 'run-once was not rewritten to no-run'}
                }
            }
        )
        # Run readme
        | append (
            run-integration-test 'README.md' {
                numd run README.md --eval (open -r ([z_examples numd_config_example1.nu] | path join)) --ignore-git-check
            }
        )
    )

    if $update {
        let changed = $results | where status == 'changed'
        if ($changed | is-not-empty) {
            $changed | each {|r|
                ^git add $r.file
                # Why: -e (stderr) so staging notes never corrupt the JSON on stdout in machine mode
                print -e $"(ansi green)Staged:(ansi reset) ($r.file)"
            }
        }
    }

    $results
}

# Print the human view: non-passing tests (or all with --all), then a summary line.
# Returns nothing so no wide table auto-renders and truncates the verdict column.
def print-human [flat: table --all --update] {
    let to_show = if $all { $flat } else { $flat | where status != 'passed' }
    $to_show | each {|r| print-test-result $r }
    print-summary $flat --update=$update
}

# Print the N passed, M failed [, K changed] headline
def print-summary [flat: table --update] {
    let passed = $flat | where status == 'passed' | length
    let failed = $flat | where status == 'failed' | length
    let changed = $flat | where status == 'changed' | length
    let total = $flat | length

    let parts = [
        $"(ansi green_bold)($passed) passed(ansi reset)"
        $"(ansi red_bold)($failed) failed(ansi reset)"
    ] | append (if $changed > 0 { [$"(ansi yellow_bold)($changed) changed(ansi reset)"] } else { [] })

    print $"($parts | str join ', ') \(($total) total\)"
    if $changed > 0 and not $update {
        print $"(ansi attr_dimmed)Run with --update to accept changes(ansi reset)"
    }
}

# Print a single test result with status indicator (and the assertion on failure)
def print-test-result [result: record] {
    let icon = match $result.status {
        'passed' => $"(ansi green)✓(ansi reset)"
        'failed' => $"(ansi red)✗(ansi reset)"
        'changed' => $"(ansi yellow)~(ansi reset)"
        _ => "?"
    }
    let suffix = if $result.file != null { $" (ansi attr_dimmed)\(($result.file)\)(ansi reset)" } else { "" }
    print $"  ($icon) ($result.name)($suffix)"
    if $result.status == 'failed' and ($result.message? | is-not-empty) {
        print $"      (ansi red)($result.message)(ansi reset)"
    }
}

# Run an integration test and return unified result format
def run-integration-test [name: string command_src: closure] {
    try {
        do $command_src

        # Check git diff to determine status
        let diff_result = do { ^git diff --quiet $name } | complete
        let status = if $diff_result.exit_code == 0 { 'passed' } else { 'changed' }

        {type: 'integration' name: ($name | path basename) status: $status file: $name message: null}
    } catch {|err|
        {type: 'integration' name: ($name | path basename) status: 'failed' file: $name message: $err.msg}
    }
}

def update-dotnu-embeds [] {
    scope modules
    | where name == 'dotnu'
    | is-empty
    | if $in { return }

    dotnu embeds-update z_examples/8_parse_frontmatter/dotnu-test.nu
}

export def 'main release' [
    --major (-M) # Bump major version (X.0.0)
    --minor (-m) # Bump minor version (x.Y.0)
] {
    git checkout main

    let description = gh repo view --json description | from json | get description
    let parts = git tag | lines | sort --natural | last | split row '.' | into int
    let tag = if $major {
        [($parts.0 + 1) 0 0]
    } else if $minor {
        [$parts.0 ($parts.1 + 1) 0]
    } else {
        [$parts.0 $parts.1 ($parts.2 + 1)]
    } | str join '.'

    open nupm.nuon
    | update description ($description | str replace 'numd - ' '')
    | update version $tag
    | to nuon --indent 2
    | save --force --raw nupm.nuon

    git add nupm.nuon
    git commit -m $'($tag) nupm version'
    git tag $tag
    git push origin main --tags
}
