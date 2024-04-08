#parse_help
export def main [
    command: string
] {

    let help_lines = help $command
        | ansi strip
        | str replace 'Search terms:' "Search terms:\n"
        | str replace ':  (optional)' ' (optional)'
        | lines
        | compact --empty
        | if ($in.0 == 'Usage:') {} else {prepend 'Description:'}


        let $regex = '^(Description|Search terms|Usage|Subcommands|Flags|Parameters|Input/output types|Examples):'

    let $existing_chapters = $help_lines
        | where $it =~ $regex
        | str trim -rc ':'
        | wrap chapter

    let $elements = $help_lines
        | split list -r $regex
        | wrap elements

    let $record = ($existing_chapters
        | merge $elements
        | transpose -idr);

    let $out_record = ($record
        | update 'Flags' {|i| $i
        | get 'Flags'
        | where $it !~ '-h, --help'}
        | if ($in
        | get 'Flags'
        | length) == 0 {reject 'Flags'} else {})

    $out_record
        | items {|k v| $"($k)\n($v
        | str replace -r '^\s*(\S)' '  $1'
        | str join (char nl))"}
        | str join "\n\n"
}
