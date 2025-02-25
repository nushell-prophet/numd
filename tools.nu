const numdinternals = ([numd commands.nu] | path join)
use $numdinternals [modify-path]

def main [] {}

def 'main testing' [] {
    use numd

    # path join is used for windows compatability
    let $path_simple_table = [z_examples 5_simple_nu_table simple_nu_table.md] | path join

    # clear outputs from simple markdown
    ['z_examples' '1_simple_markdown' 'simple_markdown.md']
    | path join
    | numd clear-outputs $in -o ($in | modify-path --suffix '_with_no_output')

    glob z_examples/*/*.md --exclude [*/*_with_no_output* */*_customized*]
    | par-each --keep-order {|file|

        # Strip markdown
        numd clear-outputs $file --strip-markdown --echo
        | save -f (
            [z_examples 99_strip_markdown ($file | path parse | get stem | $in + '.nu')] | path join
        )

        # Run files with yaml config set
        ( numd run $file --no-backup --intermed-script $'($file)_intermed.nu'
            --config-path numd_config_example1.yaml )
    }
    | append (
        # Run file with customized width of table
        numd run $path_simple_table --no-backup --table-width 20 --result-md-path (
            $path_simple_table | modify-path --suffix '_customized_width20'
        )
    )
    | append (
        # Run file with another config
        numd run $path_simple_table --no-backup --config-path 'numd_config_example2.yaml' --result-md-path (
            $path_simple_table | modify-path --suffix '_customized_example_config'
        )
    )
    | append (
        # Run readme
        numd run README.md --no-backup --config-path numd_config_example1.yaml
    )
}

def 'main release' [] {
    let $description = gh repo view --json description | from json | get description
    let $tag = git tag | lines | sort -n | last | split row '.' | into int | update 2 {$in + 1} | str join '.'

    open nupm.nuon
    | update description ($description | str replace 'numd - ' '')
    | update version $tag
    | to nuon --indent 2
    | save --force --raw nupm.nuon

    open README.md -r
    | lines
    | update 0 ('<h1 align="center">' + $description + '</h1>')
    | str join (char nl)
    | $in + (char nl)
    | save -r README.md -f

    # prettier README.md -w

    # use nupm
    # nupm install --force --path .

    git add nupm.nuon
    git commit -m $'($tag) nupm version'
    git tag $tag
    git push origin $tag
}
