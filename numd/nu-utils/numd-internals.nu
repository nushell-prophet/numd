use std iter scan

# Detects code blocks in a markdown string and returns a table with their line numbers and infostrings.
export def find-code-blocks []: string -> table {
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
# > 'ls | sort-by modified -r' | create-execution-code --whole_block --fence '```nu indent-output' | save z_examples/999_numd_internals/create-execution-code_0.nu -f
export def create-execution-code [
    --fence: string # opening code fence string with options for executing current block
    --whole_block
]: string -> string {
    let $code_content = $in
    let $fence_options = $fence | extract-fence-options

    let $highlighted_command = $code_content | create-highlight-command

    let $code_execution = $code_content
        | if 'no-run' in $fence_options {''} else {
            remove-comments-plus
            | if 'try' in $fence_options {
                if 'new-instance' in $fence_options {
                    create-catch-error-outside
                } else {
                    create-catch-error-current-instance
                }
            } else {}
            | if 'no-output' in $fence_options {} else {
                if $whole_block {
                    create-fence-output
                } else {}
                | if (check-print-append $in) {
                    if 'indent-output' in $fence_options {
                        create-indented-output
                    } else {}
                    | generate-print-statement
                } else {}
            }
            | $in + (char nl)
        }

    $highlighted_command + $code_execution
}

# Generates an intermediate script from a table of classified markdown code blocks.
export def generate-intermediate-script [
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
            'no-run' in ($in.row_type.0 | extract-fence-options)
        ) {
            $in.line
            | generate-print-lines
        } else if $in.row_type.0 =~ '^```nu(shell)?(\s|$)' {
            execute-block-lines $in.line $in.row_type.0
        }
    }
    | prepend $"const init_numd_pwd_const = '($current_dir)'" # we initialize it here so it will be available in intermediate scripts
    | prepend ( '# this script was generated automatically using numd' +
        "\n# https://github.com/nushell-prophet/numd" )
    | flatten
    | str join (char nl)
    | str replace -r "\n*$" "\n"
}

export def execute-block-lines [
    rows: list
    row_type: string
] {
    $rows
    | skip | drop # skip code fences
    | if ($in | where $it =~ '^>' | is-empty) {  # finding blocks with no `>` symbol, to execute them entirely
        str join (char nl)
        | create-execution-code --whole_block --fence $row_type
    } else {
        each { # here we define what to do with each line of the current block one by one
            if $in starts-with '>' { # if line starts with `>` we execute it
                create-execution-code --fence $row_type
            } else if $in starts-with '#' { # if line starts with `#` we print it
                create-highlight-command
            }
        }
    }
    | prepend $"\"($row_type)\" | print"
    | append $"\"```\" | print"
    | append '' # empty line for visual distinction
}

# Parses block indices from Nushell output lines and returns a table with the original markdown line numbers.
export def extract-block-index [
    $nu_res_stdout_lines: list
]: nothing -> table {
    let $block_start_line = $nu_res_stdout_lines
        | each {
            if $in =~ $"^(mark-code-block)\\d+$" {
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
export def merge-markdown [
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
export def clean-markdown []: string -> string {
    str replace --all --regex "```output-numd[\n\\s]+```\n" '' # empty output-numd blocks
    | str replace --all --regex "\n{2,}```\n" "\n```\n" # empty lines before closing code fences
    | str replace --all --regex "\n{3,}" "\n\n" # multiple newlines
    | str replace --all --regex " +(\n|$)" "\n" # remove trailing spaces
    | str replace --all --regex "\n*$" "\n" # ensure a single trailing newline
}

# The replacement is needed to distinguish the blocks with outputs from just blocks with ```.
# `find-code-blocks` works only with lines without knowing the previous lines.
export def toggle-output-fences [
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
export def compute-change-stats [
    filename: path
    orig_file: string
    new_file: string
]: nothing -> record {
    let $original_file_content = $orig_file | ansi strip | $in + "\n" # to fix https://github.com/nushell/nushell/issues/13155
    let $new_file_content = $new_file | ansi strip

    let $nushell_blocks = $new_file_content
        | find-code-blocks
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
export def list-code-options [
    --list # show options as a table
]: [nothing -> record, nothing -> table] {
    [
        ["long" "short" "description"];

        ["indent-output" "i" "indent output visually"]
        ["no-output" "O" "execute code without outputting results"]
        ["no-run" "N" "do not execute code in block"]
        ["try" "t" "execute block inside `try {}` for error handling"]
        ["new-instance" "n" "execute block in new Nushell instance (useful with `try` block)"]
        ["picture-output" "p" "capture output as picture and place after block"]
    ]
    | if $list {} else {
        select short long
        | transpose --as-record --ignore-titles --header-row
    }
}

# Expands short options for code block execution to their long forms.
#
# > convert-short-options 'i'
# indent-output
export def convert-short-options [
    $option
]: nothing -> string {
    let $options_dict = list-code-options

    $options_dict
    | get --ignore-errors --sensitive $option
    | default $option
    | if $in not-in ($options_dict | values) {
        print $'(ansi red)($in) is unknown option(ansi reset)'
    } else {}
}

# Escapes symbols to be printed unchanged inside a `print "something"` statement.
#
# > 'abcd"dfdaf" "' | escape-special-characters
# abcd\"dfdaf\" \"
export def escape-special-characters []: string -> string {
    str replace --all --regex '(\\|\")' '\$1'
}

# Runs the intermediate script and returns its output lines as a list.
export def execute-intermediate-script [
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
# > mark-code-block 3
# #code-block-starting-line-in-original-md-3
export def mark-code-block [
    index?: int
]: nothing -> string {
    $"#code-block-starting-line-in-original-md-($index)"
}
# TODO we can use NUON in mark-code-blocks to set display options

# Generates a command to highlight code using Nushell syntax highlighting.
# > 'ls' | create-highlight-command
# "ls" | nu-highlight | print
export def create-highlight-command [ ]: string -> string {
    escape-special-characters
    | $"\"($in)\" | nu-highlight | print(char nl)(char nl)"
}

# Trims comments and extra whitespaces from code blocks for using code in the generated script.
export def remove-comments-plus []: string -> string {
    str replace -r '^[>\s]+' '' # trim starting `>`
    | str replace -r '[\s\n]+$' '' # trim newlines and spaces from the end of a line
    | str replace -r '\s+#.*$' '' # remove comments from the last line. Might spoil code blocks with the # symbol, used not for commenting
}

# Extract the last span from command to decide if `| print` could be appended
export def get-last-span [
    $command: string
] {
    let $command = $command | str trim -c "\n" | str trim
    let $len = ast $command --json
        | get block
        | from json
        | get pipelines
        | last
        | get elements.0.expr.span
        | $in.start - $in.end

    $command
    | str substring $len..
}

# Checks if the last span of the input ends with a semicolon or contains certain keywords to determine if appending ` | print` is possible.
#
# > check-print-append 'let a = ls'
# false
#
# > check-print-append 'ls'
# true
export def check-print-append [
    command: string
]: nothing -> bool {
    let $last_span = get-last-span $command

    if $last_span ends-with ';' {
        false
    } else {
        $last_span !~ '\b(let|mut|def|use)\b'
    }
}

# Generates indented output for better visual formatting.
#
# > 'ls' | create-indented-output
# ls | table | into string | lines | each {$'//  ($in)' | str trim --right} | str join (char nl)
export def create-indented-output [
    --indent: string = '//  '
]: string -> string {
    $"($in) | table | into string | lines | each {$'($indent)\($in\)' | str trim --right} | str join \(char nl\)"
}

# Generates a print statement for capturing command output.
#
# > 'ls' | generate-print-statement
# ls | print; print ''
export def generate-print-statement []: string -> string {
    if $env.numd?.table-width? == null {} else {
        $"($in) | table --width ($env.numd.table-width)"
    }
    | $"($in) | print; print ''" # the last `print ''` is for newlines after executed commands
}

# Generates a try-catch block to handle errors in the current Nushell instance.
#
# > 'ls' | create-catch-error-current-instance
# try {ls} catch {|error| $error}
export def create-catch-error-current-instance []: string -> string {
    $"try {($in)} catch {|error| $error}"
}

# Executes the command outside to obtain a formatted error message if any.
#
# > 'ls' | create-catch-error-outside
# /Users/user/.cargo/bin/nu -c "ls"| complete | if ($in.exit_code != 0) {get stderr} else {get stdout}
export def create-catch-error-outside []: string -> string {
    escape-special-characters
    | ($'($nu.current-exe) -c "($in)"' +
        "| complete | if ($in.exit_code != 0) {get stderr} else {get stdout}")
}

# Generates a fenced code block for output with a specific format.
export def create-fence-output []: string -> string {
    # We use a combination of "\n" and (char nl) here for itermid script formatting aesthetics
    $"\"```\\n```output-numd\" | print(char nl)(char nl)($in)"
}

export def generate-print-lines []: list -> string {
    str join (char nl)
    | escape-special-characters
    | $'"($in)" | print'
}

# Parses options from a code fence and returns them as a list.
#
# > '```nu no-run, t' | extract-fence-options
# ╭───┬────────╮
# │ 0 │ no-run │
# │ 1 │ try    │
# ╰───┴────────╯
export def extract-fence-options []: string -> list {
    str replace -r '```nu(shell)?\s*' ''
    | split row ','
    | str trim
    | compact --empty
    | each {|option| convert-short-options $option}
}

# Modifies a path by adding a prefix, suffix, extension, or parent directory.
#
# > 'numd/capture.nu' | modify-path --extension '.md' --prefix 'pref_' --suffix '_suf' --parent_dir abc
# numd/abc/pref_capture_suf.nu.md
export def modify-path [
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
export def create-file-backup [
    file_path: path
]: nothing -> nothing {
    $file_path
    | if ($in | path exists) and ($in | path type) == 'file' {
        modify-path --parent_dir 'zzz_md_backups' --suffix $'-(generate-timestamp)'
        | mv $file_path $in
    }
}

# Generates a timestamp string in the format YYYYMMDD_HHMMSS.
#
# > generate-timestamp
# 20240701_125253
export def generate-timestamp []: nothing -> string {
    date now | format date "%Y%m%d_%H%M%S"
}
