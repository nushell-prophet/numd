const numdinternals = ([numd commands.nu] | path join)
use $numdinternals [ build-modified-path compute-change-stats ]

export def main [] { }

# Run all tests (unit + integration)
export def 'main test' [
    --json # output results as JSON for external consumption
    --update # accept changes: stage modified integration test files
    --fail # exit with non-zero code if any tests fail (for CI)
] {
    if not $json { print $"(ansi attr_dimmed)Unit tests(ansi reset)" }
    let unit = main test-unit --json=$json
    if not $json { print $"(ansi attr_dimmed)Integration tests(ansi reset)" }
    let integration = main test-integration --json=$json --update=$update

    # Parse JSON if needed
    let unit_data = if $json { $unit | from json } else { $unit }
    let integration_data = if $json { $integration | from json } else { $integration }
    let results = $unit_data | append $integration_data

    # Print summary
    let passed = $results | where status == 'passed' | length
    let failed = $results | where status == 'failed' | length
    let changed = $results | where status == 'changed' | length
    let total = $results | length

    if not $json {
        print ""
        print $"(ansi green_bold)($passed) passed(ansi reset), (ansi red_bold)($failed) failed(ansi reset), (ansi yellow_bold)($changed) changed(ansi reset) \(($total) total\)"
        if $changed > 0 and not $update {
            print $"(ansi attr_dimmed)Run with --update to accept changes(ansi reset)"
        }
    }

    if $fail and $failed > 0 {
        if $json { print ($results | to json --raw) }
        exit 1
    }

    if $json { $results | to json --raw }
}

# Run unit tests using nutest
export def 'main test-unit' [
    --json # output results as JSON for external consumption
] {
    use ../nutest/nutest

    # Get detailed table from nutest
    let results = nutest run-tests --path tests/ --returns table --display nothing

    # Convert to flat table format
    let flat = $results
    | each {|row|
        let status = if $row.result == 'PASS' { 'passed' } else { 'failed' }
        {type: 'unit' name: $row.test status: $status file: null}
    }

    if not $json {
        $flat | each {|r| print-test-result $r }
    }

    if $json { $flat | to json --raw } else { $flat }
}

# Run integration tests (execute example markdown files)
export def 'main test-integration' [
    --json # output results as JSON for external consumption
    --update # accept changes: stage modified files in git
] {
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
                numd run $file --save-intermed-script $'($file)_intermed.nu' --eval (open -r numd_config_example1.nu) --ignore-git-check
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
                numd run $path_simple_table --echo --no-stats --eval (open -r numd_config_example2.nu)
                | ansi strip
                | save -f $target
            }
        )
        # Run readme
        | append (
            run-integration-test 'README.md' {
                numd run README.md --eval (open -r numd_config_example1.nu) --ignore-git-check
            }
        )
    )

    if not $json {
        $results | each {|r| print-test-result $r }
    }

    if $update {
        let changed = $results | where status == 'changed'
        if ($changed | is-not-empty) {
            $changed | each {|r|
                ^git add $r.file
                print $"(ansi green)Staged:(ansi reset) ($r.file)"
            }
        }
    }

    if $json { $results | to json --raw } else { $results }
}

# Print a single test result with status indicator
def print-test-result [result: record] {
    let icon = match $result.status {
        'passed' => $"(ansi green)✓(ansi reset)"
        'failed' => $"(ansi red)✗(ansi reset)"
        'changed' => $"(ansi yellow)~(ansi reset)"
        _ => "?"
    }
    let suffix = if $result.file != null { $" (ansi attr_dimmed)\(($result.file)\)(ansi reset)" } else { "" }
    print $"  ($icon) ($result.name)($suffix)"
}

# Run an integration test and return unified result format
def run-integration-test [name: string, command_src: closure] {
    try {
        do $command_src

        # Check git diff to determine status
        let diff_result = do { ^git diff --quiet $name } | complete
        let status = if $diff_result.exit_code == 0 { 'passed' } else { 'changed' }

        {type: 'integration' name: ($name | path basename) status: $status file: $name}
    } catch {|err|
        {type: 'integration' name: ($name | path basename) status: 'failed' file: $name}
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
    --major (-M)  # Bump major version (X.0.0)
    --minor (-m)  # Bump minor version (x.Y.0)
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
