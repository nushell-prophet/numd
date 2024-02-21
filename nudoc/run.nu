use nu-utils [overwrite-or-rename]
use std iter scan

# run nushell code chunks in .md file, output results to terminal, optionally update the .md file back
export def main [
    file: path      # a markdown file to run nushell code in
    output?: path   # a path of a file to save results, if ommited the file from first argument will be updated
    --quiet         # don't output results into terminal
    --overwrite (-o) # owerwrite an existing file without confirmation
    --intermid_script: path # save intermid script into the file, useful for debugging
] {
    let $file_lines = open -r $file | lines
    let $file_lines_classified = classify-lines $file_lines
    let $temp_script = (
        $intermid_script
        | default ($nu.temp-path | path join (date now | format date "%Y%m%d_%H%M%S" | $in + '.nu'))
    )

    assemble-script $file_lines_classified | save -f $temp_script

    let $nu_res_stdout_lines = nu -l $temp_script | lines

    let $nu_res_with_block_index = parse-block-index $nu_res_stdout_lines
    let $res = assemble-results $file_lines_classified $nu_res_with_block_index

    if not $quiet {print $res}

    $res
    | ansi strip
    | overwrite-or-rename --overwrite=($overwrite) ($output | default $file)
}


def classify-lines [
    $file_lines: list
] {
    let $row_types = ($file_lines
    | each {|i| match ($i | str trim) {
        '```nu' => 'nu-code',
        '```nushell' => 'nu-code',
        '```nudoc-output' => 'nudoc-output'
        '```' => 'chunk-end',
        _ => ''
    }}
    | scan --noinit '' {|prev curr|
        if ($curr == '' and $prev != 'chunk-end') {$prev} else {$curr}
    })

    let $block_index = (
        $row_types
        | window --remainder 2
        | scan 0 {|prev curr|
            if ($curr.0? == $curr.1?) {$prev} else {$prev + 1}
        }
    )

    $file_lines | wrap line
    | merge ($row_types | wrap row_types)
    | merge ($block_index | wrap block_index)
}

def assemble-script [
    $file_lines_classified
] {
    $file_lines_classified
    | where row_types == 'nu-code'
    | group-by block_index
    | items {|k v|
        $v.line
        | if ($in | where $it =~ '^\s*>' | is-empty) {  # finding blocks with no `>` symbol, to execute entirely
            skip                                        # skipping code language identifier ```nushell
            | str join (char nl)
            | $"print \('($in)' | nu-highlight\);(char nl)print '```(char nl)```nudoc-output'(char nl)($in)"
        } else {
            where $it =~ '^\s*(>|#)'
            | each {|i|
                if ($i =~ '^\s*>') {
                    let $command = ($i | str replace -r '^\s*>' '' | str replace -r '#.*' '')

                    if ($command =~ '\b(export|def|let)\b') {
                        $"print \('($i)' | nu-highlight\);(char nl)($command)"
                    } else {
                        $"print \('($i)' | nu-highlight\);(char nl)($command) | print $in"
                    }
                } else {
                    $"print '($i)'"
                }
            }
            | str join (char nl)
        }
        | prepend $'print `###nudoc-block-($k)`'
    }
    | flatten
    | str join (char nl)
}

def parse-block-index [
    $nu_res_stdout_lines
] {
    let $block_index = (
        $nu_res_stdout_lines
        | each {
            |i| if $i =~ '#nudoc-block-' {
                $i | split row '-' | last | into int
            } else {-1}
        }
        | scan --noinit 0 {|prev curr| if $curr == -1 {$prev} else {$curr}}
        | wrap block_index
    )

    $nu_res_stdout_lines
    | wrap 'nu_out'
    | merge $block_index
    | group-by block_index --to-table
    | upsert items {
        |i| $i.items.nu_out
        | skip
        | str join (char nl)
        | '```nushell' + (char nl) + $in + (char nl) + '```'
    }
    | rename block_index line
    | into int block_index
}

def assemble-results [
    $file_lines_classified
    $nu_res_with_block_index
] {
    $file_lines_classified
    | where row_types not-in ['nu-code' 'nudoc-output']
    | append $nu_res_with_block_index
    | sort-by block_index
    | get line
    | str join (char nl)
    | $in + (char nl)
    | str replace -ar "```\n(```\n)+" "```\n" # remove double code-chunks ends
    | str replace -ar "```nudoc-output(\\s|\n)*```\n" ''
}
