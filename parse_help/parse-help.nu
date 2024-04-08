#parse_help
export def main [
    command: string
    --chapters: list
    --record
] {
    let help_lines = help $command
        | ansi strip
        | str replace 'Search terms:' "Search terms:\n"
        | str replace ':  (optional)' ' (optional)'
        | str replace -ram '\s+-\s$' '' # flags or params with no description
        | lines
        | compact --empty
        | if ($in.0 == 'Usage:') {} else {prepend 'Description:'}

    let $regex = [
            Description
            "Search terms"
            Usage
            Subcommands
            Flags
            Parameters
            "Input/output types"
            Examples
        ]
        | str join '|'
        | $"^\(($in)\):"

    let $existing_chapters = $help_lines
        | where $it =~ $regex
        | str trim --right --char ':'
        | wrap chapter

    let $elements = $help_lines
        | split list -r $regex
        | wrap elements

    $existing_chapters
    | merge $elements
    | transpose -idr
    | update 'Flags' {|i| $i | get 'Flags' | where $it !~ '-h, --help'}
    | if ($in.Flags | length) == 0 {reject 'Flags'} else {}
    | if $chapters != [] {
        select -i ...$chapters
    } else {}
    | if $record {
        return $in
    } else {}
    | items {|k v| $v
        | str replace -r '^\s*(\S)' '  $1' # add two spaces before description lines
        | str join (char nl)
        | $"($k)\n($in)"
    }
    | str join "\n\n"
}
