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
