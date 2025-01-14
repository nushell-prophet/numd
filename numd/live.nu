export def 'h' [
    $index
    $header
] {
    seq 1 $index
    | each { '#' }
    | append ' '
    | append $header
    | str join
}

export def 'h1' [
    $text: string
] {
    h 1 $text
}
