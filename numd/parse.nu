export def 'from md' [
    file?: path # path to a markdow file. Might be ommited if markdown content is piped in
]: [string -> record nothing -> record] {
    let input = if $file == null { } else { open $file }
    | if $in != null { } else {
        error make {msg: 'no path or content of file were provided'}
    }

    let list = $input | split row "---\n" --number 3

    # it means there is no frontmatter
    if $list.0 != '' { return {content: $input} }

    let yaml = $list.1 | from yaml

    $yaml | insert content $list.2
}

alias core_to_md = to md

export def 'to md' []: record -> string {
    let input = $in

    $input | columns | if $in == ['content'] { return $input.content }

    let frontmatter = $input | reject --optional content | to yaml

    ''
    | append $frontmatter
    | append ($input.content? | default '')
    | str join "---\n"
}
