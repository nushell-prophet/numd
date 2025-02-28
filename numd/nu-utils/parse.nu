alias core_parse = parse

export def main [
    file: path
] {
    open $file
    | lines
    | enumerate
    | each {|i| $i.item | parse -r '^(?:(?<h>#+) (?<content>.*))?(?<c>```)?' | get 0 | merge $i }
}
