def main [] {}

def 'main testing' [] {
    use ./numd

    ['examples' '1_simple_markdown' 'simple_markdown.md']
    | path join
    | numd clear-outputs $in -o ($in | str replace 'markdown.md' 'markdown_with_no_output.md')

    glob examples/*/*.md --exclude [*/*_with_no_output*]
    | par-each {|file|
        numd run $file --no-backup --intermid-script $'($file)_intermid.nu'
    }
    | append (numd run README.md --no-backup)
}

def 'main release' [] {
    let $git_info = gh repo view --json description,name | from json
    let $git_tag = git tag | lines | sort -n | last | split row '.' | into int | update 2 {$in + 1} | str join '.'

    open nupm.nuon
    | update description ($git_info.description | str replace 'numd - ' '')
    | update version $git_tag
    | to nuon --indent 2
    | save --force --raw nupm.nuon

    open README.md -r
    | lines
    | update 0 ('<h1 align="center">' + $git_info.description + '</h1>')
    | str join (char nl)
    | $in + (char nl)
    | save -r README.md -f

    # prettier README.md -w

    # use nupm
    # nupm install --force --path .

    git add nupm.nuon
    git commit -m $'($git_tag) nupm version'
    git tag $git_tag
    git push origin $git_tag
}
