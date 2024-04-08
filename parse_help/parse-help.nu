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
        | str replace -ram '(\s*)(-|:)\s*($|\()' '$1$2' # flags or params with no description
        | lines
        | str trim
        | if not ($in | where $it == '======================' | is-empty) {
            error make {msg: $"there are more than 1 command with the name ($command)"}
        } else {}
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
    | if ($in.Description | split list '' | length) > 1 {
        let $input = $in

        $input
        | update Description ($input.Description | take until {|line| $line == ''} | append '')
        | upsert Examples {|i| $i.Examples? | append ($input.Description | skip until {|line| $line == ''} | skip)}
    } else {}
    | if ($in.Flags | length) == 0 {reject 'Flags'} else {}
    | if $chapters != null {
        select -i ...$chapters
    } else {}
    | if $record {
        return $in
    } else {}
    | items {|k v| $v
        | str replace -r '^\s*(\S)' '  $1' # add two spaces before description lines
        | str join (char nl)
        | $"($k):\n($in)"
    }
    | str join "\n"
}
