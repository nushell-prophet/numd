use std iter scan

# run nushell code chunks in a .md file, output results to terminal, optionally update the .md file back
export def main [
    file: path      # a markdown file to run nushell code in
    output?: path   # a path of a file to save results, if ommited the file from first argument will be updated
    --quiet         # don't output results into terminal
    --dont-save     # don't save the file
    --overwrite (-o) # owerwrite the existing file without confirmation
    --intermid_script: path # save intermid script into the file, useful for debugging
] {
    let $file_lines = open -r $file | lines
    let $file_lines_classified = classify-lines $file_lines
    let $temp_script = (
        $intermid_script
        | default ($nu.temp-path | path join (date now | format date "%Y%m%d_%H%M%S" | $in + '.nu'))
    )

    assemble-script $file_lines_classified | save -f $temp_script

    let $nu_out = do {nu -l $temp_script} | complete
    let $nu_res_stdout_lines = $nu_out | get stdout | lines

    let $nu_res_with_block_index = parse-block-index $nu_res_stdout_lines
    let $res = assemble-results $file_lines_classified $nu_res_with_block_index

    if not $dont_save {
        let $path = $output | default $file

        if ($path | path exists) and not $overwrite {
            mv $path (
                $path | path parse
                | upsert stem {|i| $i.stem + '_back' + (date now | format date "%Y%m%d_%H%M%S")}
                | path join
            )
        }

        $res | ansi strip | save -f $path
    }

    if $nu_out.exit_code != 0 {
        echo ($nu_out | select exit_code stderr)
    }

    if not $quiet {$res}
}


def classify-lines [
    $file_lines: list
] {
    let $row_types = (
        $file_lines
        | each {|i| match ($i | str trim) {
            '```nu' => 'nu-code',
            '```nushell' => 'nu-code',
            '```nudoc-output' => 'nudoc-output'
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

    $file_lines | wrap line
    | merge ($row_types | wrap row_types)
    | merge ($block_index | wrap block_index)
}

def escape-quotes [ ] {
    str replace -ar '([^\\]?)"' '$1\"'
}

def highlight-command [
    $command
    --nudoc-out
] {
    $command
    | escape-quotes
    | $"print \(\"($in)\" | nu-highlight\)(char nl)"
    | if $nudoc_out {
        $"($in)print '```(char nl)```nudoc-output'(char nl)"
    } else {}
}

def try-append-print-in []: string -> string {
    str replace -r '[\s\n]+$' '' # trim new lines and spaces from the end of a line
    | str replace -r '\s*#.*$' '' # remove comments from the last line. Might spoil code blocks with the # symbol, used not for commenting
    | if ($in =~ '(;|(?>[^\r\n]*(let|def)[^\r\n;]*))$') {} else { # check if we can add print $in to the last line
        $in + ' | print $in'
    }
}

def assemble-script [
    $file_lines_classified
] {
    $file_lines_classified
    | where row_types == 'nu-code'
    | group-by block_index
    | items {|k v|
        $v.line
        | if ($in | where $it =~ '^\s*>' | is-empty) {  # finding blocks with no `>` symbol, to execute them entirely
            let $chunk = ( skip | str join (char nl) ) # skip the language identifier ```nushell line

            let $command = (
                $chunk
                | str replace -r '[\s\n]+$' '' # trim new lines and spaces from the end of a line
                | str replace -r '\s*#.*$' '' # remove comments from the last line. Might spoil code blocks with the # symbol, used not for commenting
                | if ($in =~ '(;|(?>[^\r\n]*(let|def)[^\r\n;]*))$') {} else { # check if we can add print $in to the last line
                    $in + ' | print $in'
                }
            )

            $"(highlight-command --nudoc-out $chunk)($command)"
        } else {
            each {|line|
                if $line =~ '^\s*>' {
                    let $command = ($line | str replace -r '^\s*>\s*' '' | str replace -r '#.*' '')

                    if ($command =~ '\b(export|def|let)\b') {
                        $"(highlight-command $line)($command)"
                    } else {
                        ((highlight-command $line) +
                        (if $command =~ '\$' { # whether the command has no variables in it, we can execute it outside to have nice error message
                            $"try {($command)} catch {|e| $e} | print $in"
                        } else {
                            $"do {nu -c \"($command | escape-quotes)\"} | complete | if \($in.exit_code != 0\) {get stderr} else {get stdout} | print $in"
                        }))
                    }
                } else if $line =~ '^\s*#' {
                    highlight-command $line
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
    | str replace -ar "```\n(```\n)+" "```\n" # multiple code-fences
    | str replace -ar "```nudoc-output(\\s|\n)*```\n" '' # empty nudoc-output blocks
    | str replace -ar "\n\n+```\n" "\n```\n" # empty lines before closing code fences
    | str replace -ar "\n\n+\n" "\n\n" # multiple new lines
}
