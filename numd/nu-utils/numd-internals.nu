use std iter scan

export def backup-file [
    $path: path
]: nothing -> nothing {
    $path
    | if ($in | path exists) and ($in | path type) == 'file' {
        path-modify --parent_dir 'md_backups' --suffix $'-(tstamp)'
        | mv $path $in
    }
}

export def detect-code-chunks [
    md: string
]: nothing -> table {
    let $file_lines = $md | lines
    let $row_type = $file_lines
        | each {
            str trim --right
            | if $in =~ '^```' {} else {''}
        }
        | scan --noinit '' {|prev curr|
            match $curr {
                '' => { if $prev == 'closing-fence' {''} else {$prev} }
                '```' => { if $prev == '' {'```'} else {'closing-fence'} }
                _ => { $curr }
            }
        }
        | scan --noinit '' {|prev curr|
            if $curr == 'closing-fence' {$prev} else {$curr}
        }

    let $block_start_in_orig_md = $row_type
        | enumerate # enumerates start index is 0
        | window --remainder 2
        | scan 1 {|prev curr|
            if $curr.item.0? == $curr.item.1? {
                $prev
            } else {
                # here we output the line number with the opening fence of the current block
                $curr.index.0 + 2
            }
        }

    # We wrap lists into columns here because previously we needed to use the `window` command
    $file_lines | wrap line
    | merge ($row_type | wrap row_type)
    | merge ($block_start_in_orig_md | wrap block_line_in_orig_md)
    | if ($in | last | $in.row_type =~ '^```nu' and $in.line != '```') {
        error make {
            msg: 'a closing code block fence (```) is missing, markdown might be invalid.'
        }
    } else {}
}

export def escape-escapes []: string -> string {
    str replace --all --regex '(\\|\"|\/|\(|\)|\{|\}|\$|\^|\#|\||\~)' '\$1'
}

export def run-intermid-script [
    intermid_script_path: path
    no_fail_on_error: bool
]: nothing -> list {
    ^$nu.current-exe --env-config $nu.env-path --config $nu.config-path $intermid_script_path
    | complete
    | if $in.exit_code == 0 {
        get stdout
        | lines
    } else {
        if $no_fail_on_error {
            []
        } else {
            error make {msg: $in.stderr}
        }
    }
}

export def numd-block [
    index?: int
]: nothing -> string {
    $"###code-block-starting-line-in-original-md-($index)"
}

export def gen-highlight-command [ ]: string -> string {
    escape-escapes
    | $"print \(\"($in)\" | nu-highlight\)(char nl)"
}

export def trim-comments-plus []: string -> string {
    str replace -r '^[>\s]+' '' # trim starting `>`
    | str replace -r '[\s\n]+$' '' # trim new lines and spaces from the end of a line
    | str replace -r '\s*#.*$' '' # remove comments from the last line. Might spoil code blocks with the # symbol, used not for commenting
}

# Use a regular expression to check if the last line of the input ends with a semicolon,
# or contains certain keywords ('let', 'def', 'use') followed by potential characters
# This is to determine if appending ' | print' is possible.
export def ends-with-definition [
    condition: string
]: nothing -> bool {
    $condition =~ '(;|null|(?>[^\r\n]*\b(let|def|use)\b.*[^\r\n;]*))$'
}

export def gen-indented-output [
    --indent: string = '//  '
]: string -> string {
    $"($in) | table | into string | lines | each {$'($indent)\($in\)' | str trim} | str join \(char nl\)"
}

export def gen-print-in []: string -> string {
    $"($in) | print; print ''" # the last `print ''` is for new lines after executed commands
}

export def gen-catch-error-in-current-instance []: string -> string {
    $"try {($in)} catch {|e| $e}"
}

# execute the command outside to obtain a formatted error message if any
export def gen-catch-error-outside []: string -> string {
    escape-escapes
    | ($'($nu.current-exe) -c "($in)"' +
        "| complete | if ($in.exit_code != 0) {get stderr} else {get stdout}")
}

export def gen-fence-output-numd []: string -> string {
    $"print '```(char nl)```output-numd'(char nl)($in)"
}

export def gen-execute-code [
    --fence: string # opening code fence string with options for executing current chunk
    --whole_chunk
]: string -> string {
    let $code = $in
    let $options = $fence | parse-options-from-fence

    let $highlited_command = $code | gen-highlight-command

    let $code_execution = $code
        | if 'no-run' in $options {''} else {
            trim-comments-plus
            | if 'try' in $options {
                if 'new-instance' in $options {
                    gen-catch-error-outside
                } else {
                    gen-catch-error-in-current-instance
                }
            } else {}
            | if 'no-output' in $options {} else {
                if $whole_chunk {
                    gen-fence-output-numd
                } else {}
                | if (ends-with-definition $in) {} else {
                    if 'indent-output' in $options {
                        gen-indented-output
                    } else {}
                    | gen-print-in
                }
            }
            | $in + (char nl)
        }


    $highlited_command + $code_execution
}

export def gen-intermid-script [
    md_classified: table
]: nothing -> string {
    let $pwd = pwd

    $md_classified
    | where row_type =~ '^```nu(shell)?(\s|$)'
    | where row_type !~ '\b(no-run|N)\b'
    | group-by block_line_in_orig_md
    | items {|k v|
        $v.line
        | if ($in | where $it =~ '^>' | is-empty) {  # finding chunks with no `>` symbol, to execute them entirely
            skip | drop # skip code fences
            | str join (char nl)
            | gen-execute-code --whole_chunk --fence $v.row_type.0
        } else {
            each { # here we define what to do with each line of the current chunk one by one
                if $in =~ '^>' { # if it starts with `>` we execute it
                    gen-execute-code --fence $v.row_type.0
                } else if $in =~ '^\s*#' {
                    gen-highlight-command
                }
            }
        }
        | prepend $"print \"($v.row_type.0)\""
        | prepend $"print \"(numd-block $k)\""
        | append $"print \"```\""
    }
    | prepend $"const init_numd_pwd_const = '($pwd)'" # we initialize it here so it will be avaible in intermid-scripts
    | prepend $"cd ($pwd)" # to use `use nudoc` inside nudoc (as if it is executed in $nu.temp_path no )
    | prepend ( '# this script was generated automatically using numd' +
        "\n# https://github.com/nushell-prophet/numd" )
    | flatten
    | str join (char nl)
}

export def parse-block-index [
    $nu_res_stdout_lines: list
]: nothing -> table {
    let $block_start_in_orig_md = $nu_res_stdout_lines
        | each {
            if $in =~ $"^(numd-block)\\d+$" {
                split row '-' | last | into int
            } else {
                -1
            }
        }
        | scan --noinit 0 {|prev curr|
            if $curr == -1 {$prev} else {$curr}
        }
        | wrap block_line_in_orig_md

    $nu_res_stdout_lines
    | wrap 'nu_out'
    | merge $block_start_in_orig_md
    | group-by block_line_in_orig_md --to-table
    | upsert items {
        |i| $i.items.nu_out
        | skip
        | str join (char nl)
    }
    | rename block_line_in_orig_md line
    | into int block_line_in_orig_md
}

export def assemble-markdown [
    $md_classified: table
    $nu_res_with_block_line_in_orig_md: table
]: nothing -> string {
    $md_classified
    | where row_type !~ '^(```nu(shell)?(\s|$))|(```output-numd$)'
    | append (
        $md_classified
        | where row_type =~ '^```nu(shell)?.*\b(no-run|N)\b'
    )
    | append $nu_res_with_block_line_in_orig_md
    | sort-by block_line_in_orig_md
    | get line
    | str join (char nl)
    | $in + (char nl)
}

export def prettify-markdown []: string -> string {
    str replace --all --regex "```output-numd[\n\\s]+```\n" '' # empty output-numd blocks
    | str replace --all --regex "\n{2,}```\n" "\n```\n" # empty lines before closing code fences
    | str replace --all --regex "\n{3,}" "\n\n" # multiple new lines
}

export def calc-changes [
    filename: path
    orig_file: string
    new_file: string
]: nothing -> record {
    let $orig_file = $orig_file | ansi strip
    let $new_file = $new_file | ansi strip

    let $n_code_bloks = detect-code-chunks $new_file
        | where row_type =~ '^```nu'
        | get block_line_in_orig_md
        | uniq
        | length

    $new_file | str stats | transpose metric new
    | merge ($orig_file | str stats | transpose metric old)
    | insert change {|i|
        let $change_abs = $i.new - $i.old

        ($change_abs / $i.old) * 100
        | math round --precision 1
        | if $in < 0 {
            $"(ansi red)($change_abs) \(($in)%\)(ansi reset)"
        } else if ($in > 0) {
            $"(ansi blue)+($change_abs) \(($in)%\)(ansi reset)"
        } else {'0%'}
    }
    | update metric {|i| $'diff-($i.metric)'}
    | select metric change
    | transpose --as-record --ignore-titles --header-row
    | insert filename ($filename | path basename)
    | insert levenstein ($orig_file | str distance $new_file)
    | insert nu_code_blocks $n_code_bloks
    | select filename nu_code_blocks levenstein diff-lines diff-words diff-chars
}

export def diff-changes [
    $file
    $md_res_ansi
]: nothing -> string {
    $md_res_ansi
    | ansi strip
    | ^diff --color=always -c $file -
    | lines
    | skip 5 # skip seemingly uninformative stats
    | if $in == [] {
        'no changes produced to show diff'
    } else {
        str join (char nl)
    }
}

# list code block options to alternate their execution and output. Like: '```nu try'
export def code-block-options [
    --list # show options as a table
]: [nothing -> record, nothing -> table] {
    [
        ["long" "short" "description"];

        ["no-output" "O" "don't try printing result"]
        ["try" "t" "try handling errors"]
        ["new-instance" "n" "execute the chunk in the new nushell instance"]
        ["no-run" "N" "don't execute the code in chunk"]
        ["indent-output" "i" "indent the output visually" ]
    ]
    | if $list {} else {
        select short long
        | transpose --as-record --ignore-titles --header-row
    }

}

export def expand-short-options [
    $option
]: nothing -> string {
    let $dict = code-block-options

    $dict
    | get --ignore-errors --sensitive $option
    | default $option
    | if $in not-in ($dict | values) {
        print $'(ansi red)($in) is unknown option(ansi reset)'
    } else {}
}

export def parse-options-from-fence []: string -> list {
    str replace -r '```nu(shell)?\s*' ''
    | split row ','
    | str trim
    | compact --empty
    | each {|i| expand-short-options $i}
}

export def path-modify [
    --prefix: string
    --suffix: string
    --extension: string
    --parent_dir: string
]: path -> path {
    path parse
    | upsert stem {|i| $'($prefix)($i.stem)($suffix)'}
    | if $extension != null {
        update extension {|i| $i.extension + $extension }
    } else {}
    | if $parent_dir != null {
        upsert parent {|i|
            $i.parent
            | path join $parent_dir
            | $'(mkdir $in)($in)' # The author doesn't like that, but tee in 0.91 somehow consumes and produces list here
        }
    } else {}
    | path join
}

export def tstamp []: nothing -> string {
    date now | format date "%Y%m%d_%H%M%S"
}
