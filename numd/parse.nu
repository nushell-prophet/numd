export def 'from md' [] {
    let input = $in

    let list = $input | split row "---\n" --number 3

    # it means now frontmatter
    if $list.0 != '' { return {content: $input} }

    let yaml = $list.1 | from yaml

    $yaml | insert content $list.2
}
