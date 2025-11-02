export def 'from md' [
    file?
]: [string -> record nothing -> record] {
    let input = if $file == null { } else { $file }
    | if ($in | path exists) { open } else { }
    | if $in != null { } else {
        error make {msg: 'no path or content of file were provided'}
    }

    let list = $input | split row "---\n" --number 3

    # it means no frontmatter
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
