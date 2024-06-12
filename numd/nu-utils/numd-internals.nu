use std iter scan

# Detects code blocks in a markdown string and returns a table with their line numbers and infostrings.
export def detect-code-blocks [
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

# Generates code for execution in the intermediate script within a given code fence
export def gen-execute-code [
    --fence: string # opening code fence string with options for executing current block
    --whole_block
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
                if $whole_block {
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

# Generates an intermediate script from a table of classified markdown code blocks.
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
        | if ($in | where $it =~ '^>' | is-empty) {  # finding blocks with no `>` symbol, to execute them entirely
            skip | drop # skip code fences
            | str join (char nl)
            | gen-execute-code --whole_block --fence $v.row_type.0
        } else {
            each { # here we define what to do with each line of the current block one by one
                if $in =~ '^>' { # if it starts with `>` we execute it
                    gen-execute-code --fence $v.row_type.0
                } else if $in =~ '^\s*#' {
                    gen-highlight-command
                }
            }
        }
        | prepend $"    print \"($v.row_type.0)\""
        | prepend $"    print \"(numd-block $k)\""
        | append $"    print \"```\""
        | append '' # empty line for visual distinction
    }
    | prepend $"const init_numd_pwd_const = '($pwd)'" # we initialize it here so it will be available in intermediate scripts
    | prepend $"cd ($pwd)" # to use `use nudoc` inside nudoc (as if it is executed in $nu.temp_path no )
    | prepend ( '# this script was generated automatically using numd' +
        "\n# https://github.com/nushell-prophet/numd" )
    | flatten
    | str join (char nl)
}

# Parses block indices from Nushell output lines and returns a table with the original markdown line numbers.
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

# Assembles the final markdown by merging original classified markdown with parsed results of the generated script.
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

# Prettifies markdown by removing unnecessary empty lines and trailing spaces.
export def prettify-markdown []: string -> string {
    str replace --all --regex "```output-numd[\n\\s]+```\n" '' # empty output-numd blocks
    | str replace --all --regex "\n{2,}```\n" "\n```\n" # empty lines before closing code fences
    | str replace --all --regex "\n{3,}" "\n\n" # multiple new lines
    | str replace --all --regex " +(\n|$)" "\n" # remove trailing spaces
}

# Calculates changes between the original and updated markdown files and returns a record with differences.
export def calc-changes [
    filename: path
    orig_file: string
    new_file: string
]: nothing -> record {
    let $orig_file = $orig_file | ansi strip
    let $new_file = $new_file | ansi strip

    let $n_code_bloks = detect-code-blocks $new_file
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
    | update metric {$'diff_($in)'}
    | select metric change
    | transpose --as-record --ignore-titles --header-row
    | insert filename ($filename | path basename)
    | insert levenstein ($orig_file | str distance $new_file)
    | insert nu_code_blocks $n_code_bloks
    | select filename nu_code_blocks levenstein diff_lines diff_words diff_chars
}

# Displays the differences between the original and new markdown files in a colored diff format.
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

# Lists code block options for execution and output customization.
export def code-block-options [
    --list # show options as a table
]: [nothing -> record, nothing -> table] {
    [
        ["long" "short" "description"];

        ["no-output" "O" "don't try printing result"]
        ["try" "t" "try handling errors"]
        ["new-instance" "n" "execute the block in the new Nushell instance"]
        ["no-run" "N" "don't execute the code in block"]
        ["indent-output" "i" "indent the output visually" ]
    ]
    | if $list {} else {
        select short long
        | transpose --as-record --ignore-titles --header-row
    }

}

# Expands short options for code block execution to their long forms.
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

# Escapes symbols to be printed unchanged inside a `print "something"` statement.
#
# > 'abcd"dfdaf" "' | escape-escapes
# abcd\"dfdaf\" \"
export def escape-escapes []: string -> string {
    # str replace --all --regex '(\\|\"|\/|\(|\)|\{|\}|\$|\^|\#|\||\~)' '\$1'
    str replace --all --regex '(\\|\")' '\$1'
}

# Runs the intermediate script and returns its output lines as a list.
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

# Generates a unique identifier for code blocks in markdown to distinguish their output.
export def numd-block [
    index?: int
]: nothing -> string {
    $"#code-block-starting-line-in-original-md-($index)"
}
# TODO we can use NUON in numd-blocks to set display options

# Generates a command to highlight code using Nushell syntax highlighting.
export def gen-highlight-command [ ]: string -> string {
    escape-escapes
    | $"    print \(\"($in)\" | nu-highlight\)(char nl)(char nl)"
}

# Trims comments and extra whitespace from code blocks for using code in the generated script
export def trim-comments-plus []: string -> string {
    str replace -r '^[>\s]+' '' # trim starting `>`
    | str replace -r '[\s\n]+$' '' # trim new lines and spaces from the end of a line
    | str replace -r '\s*#.*$' '' # remove comments from the last line. Might spoil code blocks with the # symbol, used not for commenting
}

# Checks if the last line of the input ends with a semicolon or certain keywords to determine if appending ` | print` is possible.
export def ends-with-definition [
    condition: string
]: nothing -> bool {
    $condition =~ '(;|null|(?>[^\r\n]*\b(let|def|use)\b.*[^\r\n;]*))$'
}

# Generates indented output for better visual formatting.
export def gen-indented-output [
    --indent: string = '//  '
]: string -> string {
    $"($in) | table | into string | lines | each {$'($indent)\($in\)' | str trim} | str join \(char nl\)"
}

# Generates a print statement for capturing command output.
export def gen-print-in []: string -> string {
    if $env.numd?.table-width? == null {} else {
        $"($in) | table --width ($env.numd.table-width)"
    }
    | $"($in) | print; print ''" # the last `print ''` is for new lines after executed commands
}

# Generates a try-catch block to handle errors in the current Nushell instance.
export def gen-catch-error-in-current-instance []: string -> string {
    $"try {($in)} catch {|e| $e}"
}

# Executes the command outside to obtain a formatted error message if any.
export def gen-catch-error-outside []: string -> string {
    escape-escapes
    | ($'($nu.current-exe) -c "($in)"' +
        "| complete | if ($in.exit_code != 0) {get stderr} else {get stdout}")
}

# Generates a fenced code block for output with a specific format.
export def gen-fence-output-numd []: string -> string {
    $"    print \"```\\n```output-numd\"(char nl)(char nl)($in)"
}

# Parses options from a code fence and returns them as a list.
export def parse-options-from-fence []: string -> list {
    str replace -r '```nu(shell)?\s*' ''
    | split row ','
    | str trim
    | compact --empty
    | each {|i| expand-short-options $i}
}

# Modifies a path by adding a prefix, suffix, extension, or parent directory.
export def path-modify [
    --prefix: string
    --suffix: string
    --extension: string
    --parent_dir: string
]: path -> path {
    path parse
    | update stem {$'($prefix)($in)($suffix)'}
    | if $extension != null {
        update extension {$in + $extension}
    } else {}
    | if $parent_dir != null {
        update parent {
            path join $parent_dir
            | $'(mkdir $in)($in)' # The author doesn't like that, but tee in 0.91 somehow consumes and produces list here
        }
    } else {}
    | path join
}

# Creates a backup of a file by moving it to a specified directory with a timestamp.
export def backup-file [
    $path: path
]: nothing -> nothing {
    $path
    | if ($in | path exists) and ($in | path type) == 'file' {
        path-modify --parent_dir 'md_backups' --suffix $'-(tstamp)'
        | mv $path $in
    }
}

# Generates a timestamp string in the format YYYYMMDD_HHMMSS.
#
# > tstamp
# 20240527_111215
export def tstamp []: nothing -> string {
    date now | format date "%Y%m%d_%H%M%S"
}
