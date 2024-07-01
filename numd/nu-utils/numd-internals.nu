use std iter scan

# Detects code blocks in a markdown string and returns a table with their line numbers and infostrings.
export def detect-code-blocks []: string -> table {
    let $file_lines = lines
    let $row_type = $file_lines
        | each {
            str trim --right
            | if $in =~ '^```' {} else {'text'}
        }
        | scan --noinit 'text' {|prev_fence curr_fence|
            match $curr_fence {
                'text' => { if $prev_fence == 'closing-fence' {'text'} else {$prev_fence} }
                '```' => { if $prev_fence == 'text' {'```'} else {'closing-fence'} }
                _ => { $curr_fence }
            }
        }
        | scan --noinit 'text' {|prev_fence curr_fence|
            if $curr_fence == 'closing-fence' {$prev_fence} else {$curr_fence}
        }

    let $block_start_line = $row_type
        | enumerate # enumerates start index is 0
        | window --remainder 2
        | scan 1 {|prev_line curr_line|
            if $curr_line.item.0? == $curr_line.item.1? {
                $prev_line
            } else {
                # here we output the line number with the opening fence of the current block
                $curr_line.index.0 + 2
            }
        }

    # We wrap lists into columns here because previously we needed to use the `window` command
    $file_lines | wrap line
    | merge ($row_type | wrap row_type)
    | merge ($block_start_line | wrap block_line)
    | if ($in | last | $in.row_type =~ '^```nu' and $in.line != '```') {
        error make {
            msg: 'a closing code block fence (```) is missing, the markdown might be invalid.'
        }
    } else {}
}

# Generates code for execution in the intermediate script within a given code fence.
#
# > 'ls | sort-by modified -r' | gen-execute-code --whole_block --fence '```nu indent-output' | save z_examples/999_numd_internals/gen-execute-code_0.nu -f
export def gen-execute-code [
    --fence: string # opening code fence string with options for executing current block
    --whole_block
]: string -> string {
    let $code_content = $in
    let $fence_options = $fence | parse-options-from-fence

    let $highlighted_command = $code_content | gen-highlight-command

    let $code_execution = $code_content
        | if 'no-run' in $fence_options {''} else {
            trim-comments-plus
            | if 'try' in $fence_options {
                if 'new-instance' in $fence_options {
                    gen-catch-error-outside
                } else {
                    gen-catch-error-in-current-instance
                }
            } else {}
            | if 'no-output' in $fence_options {} else {
                if $whole_block {
                    gen-fence-output-numd
                } else {}
                | if (ends-with-definition $in) {} else {
                    if 'indent-output' in $fence_options {
                        gen-indented-output
                    } else {}
                    | gen-print-in
                }
            }
            | $in + (char nl)
        }

    $highlighted_command + $code_execution
}

# Generates an intermediate script from a table of classified markdown code blocks.
export def gen-intermid-script [
    md_classified: table
]: nothing -> string {
    let $current_dir = pwd

    # $md_classified | save $'(date now | into int).json'

    $md_classified
    | where row_type != '```output-numd'
    | group-by block_line
    | values
    | each {
        if ($in.row_type.0 == 'text' or
            'no-run' in ($in.row_type.0 | parse-options-from-fence)
        ) {
            $in.line
            | gen-print-lines
        } else if $in.row_type.0 =~ '^```nu(shell)?(\s|$)' {
            exec-block-lines $in.line $in.row_type.0
        }
    }
    | prepend $"const init_numd_pwd_const = '($current_dir)'" # we initialize it here so it will be available in intermediate scripts
    | prepend ( '# this script was generated automatically using numd' +
        "\n# https://github.com/nushell-prophet/numd" )
    | flatten
    | str join (char nl)
}

export def exec-block-lines [
    rows: list
    row_type: string
] {
    $rows
    | skip | drop # skip code fences
    | if ($in | where $it =~ '^>' | is-empty) {  # finding blocks with no `>` symbol, to execute them entirely
        str join (char nl)
        | gen-execute-code --whole_block --fence $row_type
    } else {
        each { # here we define what to do with each line of the current block one by one
            if $in =~ '^>' { # if it starts with `>` we execute it
                gen-execute-code --fence $row_type
            } else if $in =~ '^\s*#' {
                gen-highlight-command
            }
        }
    }
    | prepend $"\"($row_type)\" | print"
    | append $"\"```\" | print"
    | append '' # empty line for visual distinction
}

# Parses block indices from Nushell output lines and returns a table with the original markdown line numbers.
export def parse-block-index [
    $nu_res_stdout_lines: list
]: nothing -> table {
    let $block_start_line = $nu_res_stdout_lines
        | each {
            if $in =~ $"^(numd-block)\\d+$" {
                split row '-' | last | into int
            } else {
                -1
            }
        }
        | scan --noinit 0 {|prev_index curr_index|
            if $curr_index == -1 {$prev_index} else {$curr_index}
        }
        | wrap block_line

    $nu_res_stdout_lines
    | wrap 'nu_out'
    | merge $block_start_line
    | group-by block_line --to-table
    | upsert items {
        |i| $i.items.nu_out
        | skip
        | str join (char nl)
    }
    | rename block_line line
    | into int block_line
}

# Assembles the final markdown by merging original classified markdown with parsed results of the generated script.
export def assemble-markdown [
    $md_classified: table
    $nu_res_with_block_line: table
]: nothing -> string {
    $md_classified
    | where row_type !~ '^(```nu(shell)?(\s|$))|(```output-numd$)'
    | append $nu_res_with_block_line
    | sort-by block_line
    | get line
    | str join (char nl)
    | $in + (char nl)
}

# Prettifies markdown by removing unnecessary empty lines and trailing spaces.
export def prettify-markdown []: string -> string {
    str replace --all --regex "```output-numd[\n\\s]+```\n" '' # empty output-numd blocks
    | str replace --all --regex "\n{2,}```\n" "\n```\n" # empty lines before closing code fences
    | str replace --all --regex "\n{3,}" "\n\n" # multiple newlines
    | str replace --all --regex " +(\n|$)" "\n" # remove trailing spaces
    | str replace --all --regex "\n*$" "\n" # ensure a single trailing newline
}

# The replacement is needed to distinguish the blocks with outputs from just blocks with ```.
# `detect-code-blocks` works only with lines without knowing the previous lines.
export def replace-output-numd-fences [
    a = "\n```\n\nOutput:\n\n```\n" # I set variables here to prevent collecting $in var
    b = "\n```\n```output-numd\n"
    --back
] {
    if $back {
        str replace --all $b $a
    } else {
        str replace --all $a $b
    }
}

# Calculates changes between the original and updated markdown files and returns a record with differences.
export def calc-changes-stats [
    filename: path
    orig_file: string
    new_file: string
]: nothing -> record {
    let $original_file_content = $orig_file | ansi strip | $in + "\n" # to fix https://github.com/nushell/nushell/issues/13155
    let $new_file_content = $new_file | ansi strip

    let $nushell_blocks = $new_file_content
        | detect-code-blocks
        | where row_type =~ '^```nu'
        | get block_line
        | uniq
        | length

    $new_file_content | str stats | transpose metric new
    | merge ($original_file_content | str stats | transpose metric old)
    | insert change_percentage {|metric_stats|
        let $change_value = $metric_stats.new - $metric_stats.old

        ($change_value / $metric_stats.old) * 100
        | math round --precision 1
        | if $in < 0 {
            $"(ansi red)($change_value) \(($in)%\)(ansi reset)"
        } else if ($in > 0) {
            $"(ansi blue)+($change_value) \(($in)%\)(ansi reset)"
        } else {'0%'}
    }
    | update metric {$'diff_($in)'}
    | select metric change_percentage
    | transpose --as-record --ignore-titles --header-row
    | insert filename ($filename | path basename)
    | insert levenshtein_dist ($original_file_content | str distance $new_file_content)
    | insert nushell_blocks $nushell_blocks
    | select filename nushell_blocks levenshtein_dist diff_lines diff_words diff_chars
}

# Lists code block options for execution and output customization.
export def code-block-options [
    --list # show options as a table
]: [nothing -> record, nothing -> table] {
    [
        ["long" "short" "description"];

        ["indent-output" "i" "indent the output visually" ]
        ["no-output" "O" "execute the code without outputting the results"]
        ["no-run" "N" "do not execute the code in the block"]
        ["try" "t" "execute the block inside the `try {}` for handling errors"]
        ["new-instance" "n" "execute the block in the new Nushell instance, useful with `try`"]
    ]
    | if $list {} else {
        select short long
        | transpose --as-record --ignore-titles --header-row
    }
}

# Expands short options for code block execution to their long forms.
#
# > expand-short-options 'i'
# indent-output
export def expand-short-options [
    $option
]: nothing -> string {
    let $options_dict = code-block-options

    $options_dict
    | get --ignore-errors --sensitive $option
    | default $option
    | if $in not-in ($options_dict | values) {
        print $'(ansi red)($in) is unknown option(ansi reset)'
    } else {}
}

# Escapes symbols to be printed unchanged inside a `print "something"` statement.
#
# > 'abcd"dfdaf" "' | escape-escapes
# abcd\"dfdaf\" \"
export def escape-escapes []: string -> string {
    str replace --all --regex '(\\|\")' '\$1'
}

# Runs the intermediate script and returns its output lines as a list.
export def run-intermid-script [
    intermid_script_path: path
    no_fail_on_error: bool
    print_block_results: bool # print blocks one by one as they are executed
]: nothing -> string {
    (^$nu.current-exe --env-config $nu.env-path --config $nu.config-path
        --plugin-config $nu.plugin-path $intermid_script_path)
    | if $print_block_results {
        tee {print}
    } else {}
    | complete
    | if $in.exit_code == 0 {
        get stdout
    } else {
        if $no_fail_on_error {
            ''
        } else {
            error make {msg: $in.stderr}
        }
    }
}

# Generates an unique identifier for code blocks in markdown to distinguish their output.
#
# > numd-block 3
# code-block-starting-line-in-original-md-3
export def numd-block [
    index?: int
]: nothing -> string {
    $"#code-block-starting-line-in-original-md-($index)"
}
# TODO we can use NUON in numd-blocks to set display options

# Generates a command to highlight code using Nushell syntax highlighting.
# > 'ls' | gen-highlight-command
# "ls" | nu-highlight | print
export def gen-highlight-command [ ]: string -> string {
    escape-escapes
    | $"\"($in)\" | nu-highlight | print(char nl)(char nl)"
}

# Trims comments and extra whitespaces from code blocks for using code in the generated script.
export def trim-comments-plus []: string -> string {
    str replace -r '^[>\s]+' '' # trim starting `>`
    | str replace -r '[\s\n]+$' '' # trim newlines and spaces from the end of a line
    | str replace -r '\s*#.*$' '' # remove comments from the last line. Might spoil code blocks with the # symbol, used not for commenting
}

# Checks if the last line of the input ends with a semicolon or certain keywords to determine if appending ` | print` is possible.
#
# > ends-with-definition 'let a = ls'
# true
#
# > ends-with-definition 'ls'
# false
export def ends-with-definition [
    condition: string
]: nothing -> bool {
    $condition =~ '(;|null|(?>[^\r\n]*\b(let|def|use)\b.*[^\r\n;]*))$'
}

# Generates indented output for better visual formatting.
#
# > 'ls' | gen-indented-output
# ls | table | into string | lines | each {$'//  ($in)' | str trim --right} | str join (char nl)
export def gen-indented-output [
    --indent: string = '//  '
]: string -> string {
    $"($in) | table | into string | lines | each {$'($indent)\($in\)' | str trim --right} | str join \(char nl\)"
}

# Generates a print statement for capturing command output.
#
# > 'ls' | gen-print-in
# ls | print; print ''
export def gen-print-in []: string -> string {
    if $env.numd?.table-width? == null {} else {
        $"($in) | table --width ($env.numd.table-width)"
    }
    | $"($in) | print; print ''" # the last `print ''` is for newlines after executed commands
}

# Generates a try-catch block to handle errors in the current Nushell instance.
#
# > 'ls' | gen-catch-error-in-current-instance
# try {ls} catch {|error| $error}
export def gen-catch-error-in-current-instance []: string -> string {
    $"try {($in)} catch {|error| $error}"
}

# Executes the command outside to obtain a formatted error message if any.
#
# > 'ls' | gen-catch-error-outside
# /Users/user/.cargo/bin/nu -c "ls"| complete | if ($in.exit_code != 0) {get stderr} else {get stdout}
export def gen-catch-error-outside []: string -> string {
    escape-escapes
    | ($'($nu.current-exe) -c "($in)"' +
        "| complete | if ($in.exit_code != 0) {get stderr} else {get stdout}")
}

# Generates a fenced code block for output with a specific format.
#
# We use a combination of "\n" and (char nl) here for itermid script formatting aesthetics
export def gen-fence-output-numd []: string -> string {
    $"\"```\\n```output-numd\" | print(char nl)(char nl)($in)"
}

export def gen-print-lines []: list -> string {
    str join (char nl)
    | escape-escapes
    | $'"($in)" | print'
}

# Parses options from a code fence and returns them as a list.
#
# > '```nu no-run, t' | parse-options-from-fence
# ╭────────╮
# │ no-run │
# │ try    │
# ╰────────╯
export def parse-options-from-fence []: string -> list {
    str replace -r '```nu(shell)?\s*' ''
    | split row ','
    | str trim
    | compact --empty
    | each {|option| expand-short-options $option}
}

# Modifies a path by adding a prefix, suffix, extension, or parent directory.
#
# > 'numd/capture.nu' | path-modify --extension '.md' --prefix 'pref_' --suffix '_suf' --parent_dir abc
# numd/abc/pref_capture_suf.nu.
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
    file_path: path
]: nothing -> nothing {
    $file_path
    | if ($in | path exists) and ($in | path type) == 'file' {
        path-modify --parent_dir 'md_backups' --suffix $'-(tstamp)'
        | mv $file_path $in
    }
}

# Generates a timestamp string in the format YYYYMMDD_HHMMSS.
#
# > tstamp
# 20240527_111215
export def tstamp []: nothing -> string {
    date now | format date "%Y%m%d_%H%M%S"
}
