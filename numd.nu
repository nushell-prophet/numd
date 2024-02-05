# numd - R Markdown inspired text-based notebooks for Nushell

use nu-utils [overwrite-or-rename]
use std iter scan

# run nushell code chunks in .md file, output results to terminal, optionally update the .md file back
export def run [
    file: path # numd file to run
    output?: path # path of file to save
    --quiet # don't output results into terminal
    --overwrite (-o) # owerwrite existing file without confirmation
] {
    let $md_row_type = (
        open $file
        | lines
        | wrap line
        | insert row_type {|i| match ($i.line | str trim) {
            '```nu' => 'nu-code',
            '```nushell' => 'nu-code',
            '```' => 'chunk-end',
            _ => ''
        }}
    )

    let $row_types = (
        $md_row_type.row_type
        | scan --noinit '' {|prev curr| if $curr == '' {if $prev == 'chunk-end' {''} else $prev} else {$curr}}
    )

    let $block_index = (
        $row_types
        | window --remainder 2
        | scan 0 {|prev curr| if ($curr.0? == $curr.1?) {$prev} else {$prev + 1}}
    )

    let $rows = (
        $md_row_type
        | merge ($row_types | wrap row_types)
        | merge ($block_index | wrap block_index)
    )

    let $numd_block_const = '###numd-block-'

    let $to_parse = (
        $rows
        | where row_types == 'nu-code'
        | where line =~ '^(>|#)'
        | group-by block_index
        | items {|k v| $'($numd_block_const)($k)' | append $v.line}
        | flatten
    )

    let $nu_command = (
        $to_parse
        | each {|i|
            if ($i =~ '^>') {
                let $command = ($i | str replace -r '^>' '')
                $"print `>($command | nu-highlight)`; (char nl)print \(" + $command + ')'
            } else {
                $'print `($i)`'
            }
        }
        | str join (char nl)
    )

    let $nuout = (nu -c $nu_command --env-config $nu.env-path --config $nu.config-path | lines)

    let $groups = (
        $nuout
        | each {
            |i| if $i =~ $numd_block_const {
                $i | split row '-' | last | into int
            } else {-1}
        }
        | scan --noinit 0 {|prev curr| if $curr == -1 {$prev} else {$curr}}
        | wrap block_index
    )

    let $nu_out_with_block_index = (
        $nuout
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
        $rows
        | where row_types not-in ['nu-code' 'chunk-end']
        | append $nu_out_with_block_index
        | sort-by block_index
        | get line
        | str join (char nl)
        | $in + (char nl)
    )

    if not $quiet {print $res}

    $res
    | ansi strip
    | overwrite-or-rename --overwrite=($overwrite) ( $output | default $file )
}

# start capturing commands and their results into a file
export def --env start_capture [
    file: path = 'numd.nu.txt'
] {
    $env.numd.path = ($file | path expand)
    $env.backup.hooks.display_output = ($env.config.hooks?.display_output? | default {table})
    $env.config.hooks.display_output = {
        let $input = $in;

        $input
        | table -e
        | into string
        | ansi strip
        | default (char nl)
        | '> ' + (history | last | get command) + (char nl) + $in + (char nl)
        | str replace -r "\n\n\n$" "\n\n"
        | if ($in !~ 'stop_capture') {
            save -ar $env.numd.path
        }

        print -n $input # without the `-n` flag new line is added to an output
    }
}

# stop capturing commands and their results
export def --env stop_capture [ ] {
    $env.config.hooks.display_output = $env.backup.hooks.display_output
}
