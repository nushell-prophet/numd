# Beautify and adapt the standard `--help` for markdown output
export def main [
    --sections: list
    --record
] {
    let help_lines = split row '======================'
        | first # quick fix for https://github.com/nushell/nushell/issues/13470
        | ansi strip
        | str replace --all 'Search terms:' "Search terms:\n"
        | str replace --all ':  (optional)' ' (optional)'
        | lines
        | str trim
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

    let $existing_sections = $help_lines
        | where $it =~ $regex
        | str trim --right --char ':'
        | wrap chapter

    let $elements = $help_lines
        | split list -r $regex
        | wrap elements

    $existing_sections
    | merge $elements
    | transpose -idr
    | if ($in.Flags | length) == 0 {reject 'Flags'} else {}
    | update 'Flags' {where $it !~ '-h, --help'}
    | if ($in.Description | split list '' | length) > 1 {
        let $input = $in

        $input
        | update Description ($input.Description | take until {|line| $line == ''} | append '')
        | upsert Examples {|i| $i.Examples? | append ($input.Description | skip until {|line| $line == ''} | skip)}
    } else {}
    | if $sections != null {
        select -i ...$sections
    } else {}
    | if $record {
        items {|k v| $v
            | str join (char nl)
            | {section: $k, value: $in}
        }
        | transpose -idr
    } else {
        items {|k v| $v
            | str replace -r '^\s*(\S)' '  $1' # add two spaces before description lines
            | str join (char nl)
            | $"($k):\n($in)"
        }
        | str join "\n"
    }
}
