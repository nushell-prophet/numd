export def 'filename-set' [
    file = 'numdlive.md'
] {
    $env.numd.live-filename = $file
}

export def 'file-name' [] {
    $env.numd?.live-filename?
    | default 'numdlive.md'
}

export def 'h' [
    $index
    $header
] {
    seq 1 $index
    | each { '#' }
    | append ' '
    | append $header
    | str join
    | str replace -ar "\n*$" "\n\n"
    | save -a (file-name)
}

export def 'h1' [
    $text: string
] {
    h 1 $text
}

export def 'h2' [
    $text: string
] {
    h 2 $text
}

export def 'h3' [
    $text: string
] {
    h 3 $text
}

export def 'h4' [
    $text: string
] {
    h 4 $text
}

export def 'h5' [
    $text: string
] {
    h 5 $text
}

export def 'h6' [
    $text: string
] {
    h 6 $text
}

# > numd list-code-options | values | each {$'--($in)'} | to text

export def 'code' [
    $code_block
    --indent-output
    --inline
    --no-output
    --no-run
    --try
    --new-instance
    --comment: string = '' # add comment to the code
] {
    let $code = $code_block
        | if $inline {
            str replace -r '^(> )?' '> '
        } else {}
        | if $comment != '' {
            $"# ($comment)\n($in)"
        } else {}

    let $code_fence_with_options = [
            (if $indent_output {'indent-output'})
            (if $no_output {'no-output'})
            (if $no_run {'no-run'})
            (if $try {'try'})
            (if $new_instance {'new-instance'})
        ]
        | compact
        | if $in == [] {} else { sort | str join ',' | $' ($in)' }
        | $'```nushell($in)'

    [
        $code_fence_with_options
        $code
        '```'
        ''
    ] | to text
}

# add a paragraph
export def 'p' [
    $text
] {
    $text
    | str replace -r "\\s*$" "\n\n"
}
