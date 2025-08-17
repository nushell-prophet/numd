use std/iter scan

open nushell_readme.md
| lines
| each { str substring ..20 }
| wrap content
| enumerate
| flatten
| insert code {|i|
    $i.content
    | parse -r '^\s*(?<code>```\w*)'
    | get 0?
}
| insert h {|i|
    $i.content
    | parse -r '^(?<h>#+)\s?(.*)$'
    | get 0?
}
| flatten
| scan {in_code: false} {|line state|
    let new_state = if ($line.code? != null) {
        {in_code: (not $state.in_code)}
    } else {
        $state
    }
    $line | insert in_code $new_state.in_code
}
| update in_code {|i| if $i.code? == '```' { true } else $i.in_code? }
