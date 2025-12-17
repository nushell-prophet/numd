# Beautify and adapt the standard `--help` for markdown output
export def main [
    --sections: list<string> # filter to only include these sections (e.g., ['Usage', 'Flags'])
    --record # return result as a record instead of formatted string
]: string -> any {
    let help_lines = split row '======================'
    | first # quick fix for https://github.com/nushell/nushell/issues/13470
    | ansi strip
    | str replace --all 'Search terms:' "Search terms:\n"
    | str replace --all ':  (optional)' ' (optional)'
    | lines
    | str trim
    | if ($in.0 != 'Usage:') { prepend 'Description:' } else { }

    let regex = [
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
    | '^(' + $in + '):'

    let existing_sections = $help_lines
    | where $it =~ $regex
    | str trim --right --char ':'
    | wrap chapter

    let elements = $help_lines
    | split list -r $regex
    | skip
    | wrap elements

    $existing_sections
    | merge $elements
    | transpose --as-record --ignore-titles --header-row
    | if ($in.Flags? == null) { } else { update 'Flags' { where $it !~ '-h, --help' } }
    | if ($in.Flags? | length) == 1 { reject 'Flags' } else { } # todo now flags contain fields with empty row
    | if ($in.Description? | default '' | split list '' | length) > 1 {
        let input = $in

        $input
        | update Description ($input.Description | take until { $in == '' } | append '')
        | upsert Examples {|i| $i.Examples? | append ($input.Description | skip until { $in == '' } | skip) }
    } else { }
    | if $sections == null { } else { select -o ...$sections }
    | if $record {
        items {|k v|
            {$k: ($v | str join (char nl))}
        }
        | into record
    } else {
        items {|k v|
            $v
            | str replace -r '^\s*(\S)' '  $1' # add two spaces before description lines
            | str join (char nl)
            | $"($k):\n($in)"
        }
        | str join (char nl)
        | str replace -ar '\s+$' '' # empty trailing new lines
        | str replace -arm '^' '# => '
    }
}
