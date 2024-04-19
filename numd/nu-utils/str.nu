
alias std_append = append
alias std_prepend = prepend

export def repeat [
    $n
] {
    let $text = $in
    seq 1 $n | each {$text} | str join
}

export def append [
    ...text: string
    --space (-s)
    --2space (-2)
    --new-line (-n)
    --tab (-t)
    --concatenator (-c): string = '' # input and rest concatenator
    --rest_el: string = ' ' # rest elements concatenator
] {
    let $input = $in
    let $concatenator = $"(
        if $new_line {(char nl)} )(
        if $tab {(char tab)} )(
        if $2space {'  '} )(
        if $space {' '} )(
        $concatenator
    )"

    $"($input)($concatenator)( $text | str join $rest_el )"
}

export def prepend [
    ...text: string
    --space (-s)
    --2space (-2)
    --new-line (-n)
    --tab (-t)
    --concatenator (-c): string = '' # input and rest concatenator
    --rest_el: string = ' ' # rest elements concatenator
] {
    let $input = $in
    let $concatenator = $"(
        if $new_line {(char nl)} )(
        if $tab {(char tab)} )(
        if $2space {'  '} )(
        if $space {' '} )(
        $concatenator
    )"

    $"( $text | str join $rest_el )($concatenator)($input)"
}

export def indent [] {}

export def dedent [] {}
