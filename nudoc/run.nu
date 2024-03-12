use std iter scan

# run nushell code chunks in a .md file, output results to terminal, optionally update the .md file back
export def main [
    file: path      # a markdown file to run nushell code in
    output?: path   # a path to a `.md` file to save results, if ommited the file from the first argument will be updated
    --quiet         # don't output results into terminal
    --dont-save     # don't save the `.md` file
    --overwrite (-o) # owerwrite the existing `.md` file without confirmation and backup
    --intermid-script: path # save intermid script into the file, useful for debugging
    --dont-handle-errors # Enclose `>` commands in `try` blocks to avoid errors and output their messages
] {
    let $file_lines = open -r $file | lines
    let $file_lines_classified = classify-lines $file_lines
    let $temp_script = (
        $intermid_script
        | default ($nu.temp-path | path join (date now | format date "%Y%m%d_%H%M%S" | $in + '.nu'))
    )

    assemble-script --dont-handle-errors=$dont_handle_errors $file_lines_classified
    | save -f $temp_script

    let $nu_out = do {nu -l $temp_script} | complete

    if $nu_out.exit_code != 0 {
        echo ($nu_out | select exit_code stderr)
        error make {msg: 'fail'}
    }

    let $nu_res_stdout_lines = $nu_out | get stdout | lines

    let $nu_res_with_block_index = parse-block-index $nu_res_stdout_lines
    let $res = assemble-results $file_lines_classified $nu_res_with_block_index

    if not $dont_save {
        let $path = $output | default $file
        if not $overwrite { backup-file $path }
        $res | ansi strip | save -f $path
    }

    if not $quiet {$res}
}

def backup-file [
    $path: path
]: nothing -> nothing {
    if ($path | path exists) {
        let $backup_path = (
            $path
            | path parse
            | upsert stem {|i| $i.stem + '_back' + (date now | format date "%Y%m%d_%H%M%S")}
            | path join
        )

        mv $path $backup_path
    }
}


def classify-lines [
    $file_lines: list
]: nothing -> table {
    let $row_types = (
        $file_lines
        | each {|i| match ($i | str trim) {
            $type if $type =~ '```(nu\b|nushell\b)' => (
                ['nu-code' ($type | split row ' ' | get 1?)] | str join ' '
            ),
            $type if $type == '```nudoc-output' => 'nudoc-output'
            $type if $type ==  '```' => 'chunk-end',
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

    $file_lines | wrap lines
    | merge ($row_types | wrap row_types)
    | merge ($block_index | wrap block_index)
}

def escape-quotes []: string -> string {
    str replace -ar '([^\\]?)"' '$1\"'
}

def nudoc-block [
    index?: int
]: nothing -> string {
    ['###nudoc-block-' $index] | str join
}

def highlight-command [
    $command: string
    --nudoc-out
]: nothing -> string {
    $command
    | escape-quotes
    | $"print \(\"($in)\" | nu-highlight\)(char nl)"
    | if $nudoc_out {
        $"($in)print '```(char nl)```nudoc-output'(char nl)"
    } else {}
}

def trim-comments-plus []: string -> string {
    str replace -r '^[>\s]+' '' # trim starting `>`
    | str replace -r '[\s\n]+$' '' # trim new lines and spaces from the end of a line
    | str replace -r '\s*#.*$' '' # remove comments from the last line. Might spoil code blocks with the # symbol, used not for commenting
}

def try-append-echo-in []: string -> string {
    if ($in =~ '(;|(?>[^\r\n]*\b(let|def|use)\b.*[^\r\n;]*))$') {} else { # check if we can add print $in to the last line
        $in + ' | echo $in'
    }
}

def try-handle-errors []: string -> string {
    if ($in =~ '\b(def|let)\b') { } else { # weather the command has definitions, so it can be scoped
        if ($in | str replace -a '$in' '') !~ '\$' { # whether the command has no variables in it
            ($"do {nu -c \"($in | escape-quotes)\"} " + # so we can execute it outside to have nice error message
            "| complete | if \($in.exit_code != 0\) {get stderr} else {get stdout}")
        } else {
            $"try {($in)} catch {|e| $e}"
        }
    }
}

def execute-code [
    code: string
    --dont-handle-errors
]: string -> string {
    let $input = $in

    $code
    | trim-comments-plus
    | if $dont_handle_errors {} else {try-handle-errors}
    | try-append-echo-in
    | $input + $in + (char nl)
}

def assemble-script [
    $file_lines_classified: table
    --dont-handle-errors
]: nothing -> string {
    $file_lines_classified
    | where row_types =~ '^nu-code'
    | group-by block_index
    | items {|k v|
        $v.lines
        | if ($in | where $it =~ '^\s*>' | is-empty) {  # finding blocks with no `>` symbol, to execute them entirely
            let $chunk = ( skip | str join (char nl) ) # skip the language identifier ```nushell line

            highlight-command --nudoc-out $chunk
            | execute-code --dont-handle-errors $chunk
        } else {
            each {|line|
                if $line =~ '^\s*>' {
                    highlight-command $line
                    | execute-code --dont-handle-errors=$dont_handle_errors $line
                } else if $line =~ '^\s*#' {
                    highlight-command $line
                }
            }
            | str join (char nl)
        }
        | prepend $'print `(nudoc-block $k)`'
    }
    | prepend ( '# this script was generated automatically using nudoc'
        + 'https://github.com/nushell-prophet/nudoc' + (char nl))
    | flatten
    | str join (char nl)
}

def parse-block-index [
    $nu_res_stdout_lines: list
]: nothing -> table {
    let $block_index = (
        $nu_res_stdout_lines
        | each {
            |i| if $i =~ (nudoc-block) {
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
    | rename block_index lines
    | into int block_index
}

def assemble-results [
    $file_lines_classified: table
    $nu_res_with_block_index: table
]: nothing -> string {
    $file_lines_classified
    | where row_types !~ '^(nu-code|nudoc-output)'
    | append $nu_res_with_block_index
    | sort-by block_index
    | get lines
    | str join (char nl)
    | $in + (char nl)
    | str replace -ar "```\n(```\n)+" "```\n" # multiple code-fences
    | str replace -ar "```nudoc-output(\\s|\n)*```\n" '' # empty nudoc-output blocks
    | str replace -ar "\n\n+```\n" "\n```\n" # empty lines before closing code fences
    | str replace -ar "\n\n+\n" "\n\n" # multiple new lines
}
