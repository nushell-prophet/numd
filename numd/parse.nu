# Parse frontmatter from markdown, output record
@category markdown
export def 'parse-frontmatter' [
    file?: path # path to a markdow file. Might be ommited if markdown content is piped in
]: [string -> record nothing -> record] {
    # Why: since 0.112 a bare `open` on a `.md` path runs `from md` and yields a table,
    # which `split row` below can't take. `--raw` keeps it a string.
    let input = if $file == null { } else { open --raw $file }
        | if $in != null { } else {
            error make {
                msg: 'no path or content of file were provided'
                # Why: `$file` is always null on this branch, so its span is the call site
                # itself — the error underlines the caller's own line, not this one
                label: {text: 'no file argument here' span: (metadata $file).span}
                help: 'pass a path as the first argument, or pipe the markdown content in'
            }
        }

    let list = $input | split row "---\n" --number 3

    # no frontmatter: doesn't start with --- or missing closing ---
    if $list.0 != '' or ($list | length) < 3 { return {content: $input} }

    let yaml = $list.1 | from yaml

    $yaml | insert content $list.2
}

alias core_to_md = to md

# produce markdown from record. All fields except of `content` go to frontmatter.
# And content becomes the body
@category markdown
export def 'to md-with-frontmatter' []: record -> string {
    let input = $in

    $input | columns | if $in == ['content'] { return $input.content }

    let frontmatter = $input | reject --optional content | to yaml

    ''
    | append $frontmatter
    | append ($input.content? | default '')
    | str join "---\n"
}
