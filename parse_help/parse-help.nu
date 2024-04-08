#parse_help
export def main [
    command: string
    --chapters: list
] {
    let help_lines = help $command
        | ansi strip
        | str replace 'Search terms:' "Search terms:\n"
        | str replace ':  (optional)' ' (optional)'
        | str replace -ram '\s+-\s$' ''
        | lines
        | compact --empty
        | if ($in.0 == 'Usage:') {} else {prepend 'Description:'}

    let $regex = $chapters
        | default [
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
        | str trim -rc ':'
        | wrap chapter

    let $elements = $help_lines
        | split list -r $regex
        | wrap elements

    let $record = $existing_chapters
        | merge $elements
        | transpose -idr

    $record
    | update 'Flags' {|i| $i | get 'Flags' | where $it !~ '-h, --help'}
    | if ($in | get 'Flags' | length) == 0 {reject 'Flags'} else {}
    | items {|k v| $v
        | str replace -r '^\s*(\S)' '  $1'
        | str join (char nl)
        | $"($k)\n($in)"
    }
    | str join "\n\n"
}
