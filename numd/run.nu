# numd - R Markdown inspired text-based notebooks for Nushell

use nu-utils [overwrite-or-rename]
use std iter scan

# run nushell code chunks in .md file, output results to terminal, optionally update the .md file back
export def main [
    file: path      # a markdown file to run nushell code in
    output?: path   # a path of a file to save results, if ommited the file from first argument will be updated
    --quiet         # don't output results into terminal
    --overwrite (-o) # owerwrite an existing file without confirmation
] {
    let $file_lines = (open -r $file | lines)

    let $row_types = (
        $file_lines
        | each {|i| match ($i | str trim) {
            '```nu' => 'nu-code',
            '```nushell' => 'nu-code',
            '```numd-output' => 'numd-output'
            '```' => 'chunk-end',
            _ => ''
        }}
        | scan --noinit '' {|prev curr|
            if ($curr == '' and $prev != 'chunk-end') {$prev} else {$curr}
        }
    )

    let $block_index = (
        $row_types
        | window --remainder 2
        | scan 0 {|prev curr|
            if ($curr.0? == $curr.1?) {$prev} else {$prev + 1}
        }
    )

    let $file_lines_classified = (
        $file_lines | wrap line
        | merge ($row_types | wrap row_types)
        | merge ($block_index | wrap block_index)
    )

    let $numd_block_const = '###numd-block-'

    let $to_parse = (
        $file_lines_classified
        | where row_types == 'nu-code'
        | group-by block_index
        | items {|k v|
            let $lines = (
                if ($v | where line =~ '^>' | is-empty) {
                    $v.line | skip | str join (char nl) | '%%' + $in
                } else {
                    $v | where line =~ '^(>|#)' | get line
                }
            )

            $'($numd_block_const)($k)' | append $lines
        }
        | flatten
    )

    let $nu_script_to_execute = (
        $to_parse
        | each {|i|
            if $i =~ '^%%' {
                let $command = ($i | str replace -r '^%%' '')
                $'print `($command | nu-highlight)`;(char nl)print "```(char nl)```numd-output"(char nl)($command)'
            } else if ($i =~ '^>') {
                let $command = ($i | str replace -r '^>' '')
                $"print `>($command | nu-highlight)`;(char nl)print \(" + $command + ')'
            } else {
                $'print `($i)`'
            }
        }
        | str join (char nl)
    )

    let $nu_res_stdout_lines = (nu -c $nu_script_to_execute --env-config $nu.env-path --config $nu.config-path | lines)

    let $groups = (
        $nu_res_stdout_lines
        | each {
            |i| if $i =~ $numd_block_const {
                $i | split row '-' | last | into int
            } else {-1}
        }
        | scan --noinit 0 {|prev curr| if $curr == -1 {$prev} else {$curr}}
        | wrap block_index
    )

    let $nu_res_with_block_index = (
        $nu_res_stdout_lines
        | wrap 'nu_out'
        | merge $groups
        | group-by block_index --to-table
        | upsert items {
            |i| $i.items.nu_out
            | skip
            | str join (char nl)
            | '```nushell' + (char nl) + $in + (char nl) + '```'
        }
        | rename block_index line
        | into int block_index
    )

    let $res = (
        $file_lines_classified
        | where row_types not-in ['nu-code' 'numd-output']
        | append $nu_res_with_block_index
        | sort-by block_index
        | get line
        | str join (char nl)
        | $in + (char nl)
        | str replace -ar "```\n(```\n)+" "```\n" # remove double code-chunks ends
        | str replace -ar "```numd-output(\\s|\n)*```\n" ''
    )

    if not $quiet {print $res}

    $res
    | ansi strip
    | overwrite-or-rename --overwrite=($overwrite) ( $output | default $file )
}
