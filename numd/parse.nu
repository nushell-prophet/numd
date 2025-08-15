export def 'from md' [] {
    let input = $in

    let list = $input | split row "---\n" --number 3

    # it means now frontmatter
    if $list.0 != '' { return {content: $input} }

    let yaml = $list.1 | from yaml

    $yaml | insert content $list.2
}

alias core_to_md = to md

export def 'to md' [] {
    let input = $in

    let frontmatter = $input | reject content | to yaml

    ''
    | append $frontmatter
    | append $input.content
    | str join "---\n"
}
