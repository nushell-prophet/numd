const numdinternals = ([numd commands.nu] | path join)
use $numdinternals [ build-modified-path ]

export def main [] { }

# Run all tests (unit tests + integration tests)
export def 'main testing' [
    --json # output results as JSON for external consumption
] {
    let unit = main testing-unit --quiet=$json
    let integration = main testing-integration

    {unit: $unit integration: $integration}
    | if $json { to json --raw } else { }
}

# Run unit tests using nutest
export def 'main testing-unit' [
    --json # output results as JSON for external consumption
    --quiet # suppress terminal output (for use when called from main testing)
] {
    use ../nutest/nutest

    let display = if ($json or $quiet) { 'nothing' } else { 'terminal' }
    nutest run-tests --path tests/ --returns summary --display $display
    | if $json { to json --raw } else { }
}

# Run integration tests (execute example markdown files)
export def 'main testing-integration' [
    --json # output results as JSON for external consumption
] {
    use numd

    # will be executed if dotnu-embeds-are-available
    update-dotnu-embeds

    # path join is used for windows compatability
    let path_simple_table = [z_examples 5_simple_nu_table simple_nu_table.md] | path join

    # clear outputs from simple markdown
    ['z_examples' '1_simple_markdown' 'simple_markdown.md']
    | path join
    | numd clear-outputs $in -o ($in | build-modified-path --suffix '_with_no_output')

    # I use a long chain of `append` here to obtain a table with statistics on updates upon exit.

    # Strip markdown and run main set of .md files in one loop
    glob z_examples/*/*.md --exclude [
        */*_with_no_output*
        */*_customized*
        */8_parse_frontmatter
    ]
    | par-each --keep-order {|file|
        # Strip markdown
        let strip_markdown_path = $file
        | path parse
        | get stem
        | $in + '.nu'
        | [z_examples 99_strip_markdown $in]
        | path join

        numd clear-outputs $file --strip-markdown --echo
        | save -f $strip_markdown_path

        # Run files with yaml config set
        (
            numd run $file --no-backup --save-intermed-script $'($file)_intermed.nu'
            --config-path numd_config_example1.yaml
        )
    }
    # Run file with customized width of table
    | append (
        numd run $path_simple_table --no-backup --table-width 20 --result-md-path (
            $path_simple_table | build-modified-path --suffix '_customized_width20'
        )
    )
    # Run file with another config
    | append (
        numd run $path_simple_table --no-backup --config-path 'numd_config_example2.yaml' --result-md-path (
            $path_simple_table | build-modified-path --suffix '_customized_example_config'
        )
    )
    # Run readme
    | append (
        numd run README.md --no-backup --config-path numd_config_example1.yaml
    )
    | if $json { to json --raw } else { }
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
    let description = gh repo view --json description | from json | get description
    let parts = git tag | lines | sort -n | last | split row '.' | into int
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

    # open README.md -r
    # | lines
    # | update 0 ('<h1 align="center">' + $description + '</h1>')
    # | str join (char nl)
    # | $in + (char nl)
    # | save -r README.md -f

    # prettier README.md -w

    # use nupm
    # nupm install --force --path .

    git checkout main

    git add nupm.nuon
    git commit -m $'($tag) nupm version'
    git tag $tag
    git push origin $tag
}
