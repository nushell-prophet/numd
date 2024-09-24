use std iter scan

# Detect code blocks in a markdown string and return a table with their line numbers and info strings.
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
        | enumerate # enumerate starting index is 0
        | window --remainder 2
        | scan 1 {|prev_line curr_line|
            if $curr_line.item.0? == $curr_line.item.1? {
                $prev_line
            } else {
                # output the line number with the opening fence of the current block
                $curr_line.index.0 + 2
            }
        }

    # Wrap lists into columns because the `window` command was used previously
    $file_lines | wrap line
    | merge ($row_type | wrap row_type)
    | merge ($block_start_line | wrap block_line)
    | if ($in | last | $in.row_type =~ '^```nu' and $in.line != '```') {
        error make {
            msg: 'A closing code block fence (```) is missing; the markdown might be invalid.'
        }
    } else {}
}

# Generate code for execution in the intermediate script within a given code fence.
#
# > 'ls | sort-by modified -r' | create-execution-code --whole_block --fence '```nu indent-output' | save z_examples/999_numd_internals/create-execution-code_0.nu -f
export def create-execution-code [
    --whole_block
]: string -> string {
    let $code_content = $in
    let $fence_options = $env.numd.current_block_options

    let $highlighted_command = $code_content | create-highlight-command

    let $code_execution = $code_content
        | remove-comments-plus
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
                | if 'picture-output' in $fence_options {
                    generate-picture
                } else {
                    generate-print-statement
                }
            } else {}
        }
        | $in + (char nl)

    $highlighted_command + $code_execution
}

# Generate an intermediate script from a table of classified markdown code blocks.
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
        let $input = $in
        let $row_type = $input.row_type.0
        if $row_type != 'text' {
            $env.numd.current_block_options = ($row_type | extract-fence-options)
        }

        $input.line
        | if ($row_type == 'text' or
            'no-run' in $env.numd.current_block_options
        ) {
            generate-print-lines
        } else if $row_type =~ '^```nu(shell)?(\s|$)' {
            execute-block-lines
            | prepend $"\"($row_type)\" | print"
            | append $"\"```\" | print"
            | append '' # add an empty line for visual distinction
        }
    }
    | if $env.numd?.prepend-code? != null {
        prepend $"($env.numd?.prepend-code?)\n"
        | if $env.numd.config-path? != null {
            prepend ($"# numd config loaded from `($env.numd.config-path)`\n")
        } else {}
    } else {}
    | prepend $"const init_numd_pwd_const = '($current_dir)'\n" # initialize it here so it will be available in intermediate scripts
    | prepend "stor create --table-name 'captures' --columns {capture: str}"
    | prepend ( '# this script was generated automatically using numd' +
        "\n# https://github.com/nushell-prophet/numd\n" )
    | append "print (stor open | query db 'select * from captures')"
    | flatten
    | str join (char nl)
    | str replace -r "\n*$" "\n"
}

export def execute-block-lines [ ]: list -> list {
    skip | drop # skip code fences
    | if ($in | where $it =~ '^>' | is-empty) {  # find blocks with no `>` symbol to execute them entirely
        str join (char nl)
        | create-execution-code --whole_block
    } else {
        each { # define what to do with each line of the current block one by one
            if $in starts-with '>' { # if a line starts with `>`, execute it
                create-execution-code
            } else if $in starts-with '#' { # if a line starts with `#`, print it
                create-highlight-command
            }
        }
    }
}

# Parse block indices from Nushell output lines and return a table with the original markdown line numbers.
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

# Assemble the final markdown by merging the original classified markdown with parsed results of the generated script.
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

# Prettify markdown by removing unnecessary empty lines and trailing spaces.
export def clean-markdown []: string -> string {
    str replace --all --regex "```output-numd[\n\\s]+```\n" '' # empty output-numd blocks
    | str replace --all --regex "\n{2,}```\n" "\n```\n" # empty lines before closing code fences
    | str replace --all --regex "\n{3,}" "\n\n" # multiple newlines
    | str replace --all --regex " +(\n|$)" "\n" # remove trailing spaces
    | str replace --all --regex "\n*$" "\n" # ensure a single trailing newline
}

# Replacement is needed to distinguish the blocks with outputs from blocks with just ```.
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

# Calculate changes between the original and updated markdown files and return a record with the differences.
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

# List code block options for execution and output customization.
export def list-code-options [
    --list # display options as a table
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

# Expand short options for code block execution to their long forms.
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

# Escape symbols to be printed unchanged inside a `print "something"` statement.
#
# > 'abcd"dfdaf" "' | escape-special-characters-and-quote
# "abcd\"dfdaf\" \""
export def escape-special-characters-and-quote []: string -> string {
    # `to json` might give similar results, yet it replaces new lines
    # which spoils readability of intermediate scripts
    str replace --all --regex '(\\|\")' '\$1'
    | $'"($in)"'
}

# Run the intermediate script and return its output lines as a list.
export def execute-intermediate-script [
    intermed_script_path: path
    no_fail_on_error: bool
    print_block_results: bool # print blocks one by one as they execute
]: nothing -> string {
    (^$nu.current-exe --env-config $nu.env-path --config $nu.config-path
        --plugin-config $nu.plugin-path $intermed_script_path)
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
            error make {msg: ($in.stderr? | into string)} --unspanned
        }
    }
}

# Generate a unique identifier for code blocks in markdown to distinguish their output.
#
# > mark-code-block 3
# #code-block-starting-line-in-original-md-3
export def mark-code-block [
    index?: int
]: nothing -> string {
    $"#code-block-starting-line-in-original-md-($index)"
}
# TODO NUON can be used in mark-code-blocks to set display options

# Generate a command to highlight code using Nushell syntax highlighting.
# > 'ls' | create-highlight-command
# "ls" | nu-highlight | print
export def create-highlight-command [ ]: string -> string {
    escape-special-characters-and-quote
    | $"($in) | nu-highlight | print(char nl)(char nl)"
}

# Trim comments and extra whitespaces from code blocks for use in the generated script.
export def remove-comments-plus []: string -> string {
    str replace -r '^[>\s]+' '' # trim starting `>`
    | str replace -r '[\s\n]+$' '' # trim newlines and spaces from the end of a line
    | str replace -r '\s+#.*$' '' # remove comments from the last line. Might spoil code blocks with the # symbol, used not for commenting
}

# Extract the last span from a command to determine if `| print` can be appended
#
# > get-last-span 'let a = 1..10; $a | length'
# length
#
# > get-last-span 'let a = 1..10; ($a | length);'
# let a = 1..10; ($a | length);
#
# > get-last-span 'let a = 1..10; ($a | length)'
# ($a | length)
#
# > get-last-span 'let a = 1..10'
# let a = 1..10
#
# > get-last-span '"abc"'
# "abc"
export def get-last-span [
    $command: string
] {
    let $command = $command | str trim -c "\n" | str trim
    let $spans = ast $command --json
        | get block
        | from json
        | to yaml
        | parse -r 'span:\n\s+start:(.*)\n\s+end:(.*)'
        | rename s f
        | into int s f

    # I just brutforced ast filter params in nu 0.97, as `ast` waits for better replacement or improvement
    let last_span_end = $spans.f | math max
    let longest_last_span_start = $spans
        | where f == $last_span_end
        | get s
        | if ($in | length) == 1 {} else {
            sort
            | skip
        }
        | first

    let $len = $longest_last_span_start - $last_span_end

    $command
    | str substring $len..
}

# Check if the last span of the input ends with a semicolon or contains certain keywords to determine if appending ` | print` is possible.
#
# > check-print-append 'let a = ls'
# false
#
# > check-print-append 'ls'
# true
#
# > check-print-append 'mut a = 1; $a = 2'
# false
export def check-print-append [
    command: string
]: nothing -> bool {
    let $last_span = get-last-span $command

    if $last_span =~ '(;|print|null)$' {
        false
    } else {
        $last_span !~ '\b(let|mut|def|use)\b' and $last_span !~ '(^|;|\n) ?(?<!(let|mut) )\$\S+ = '
    }
}

# Generate indented output for better visual formatting.
#
# > 'ls' | create-indented-output
# ls | table | lines | each {$'//  ($in)' | str trim --right} | str join (char nl)
export def create-indented-output [
    --indent: string = '//  '
]: string -> string {
    generate-table-statement
    | $"($in) | lines | each {$'($indent)\($in\)' | str trim --right} | str join \(char nl\)"
}

# Generate a print statement for capturing command output.
#
# > 'ls' | generate-print-statement
# ls | table | print; print ''
export def generate-print-statement []: string -> string {
    generate-table-statement
    | $"($in) | print; print ''" # The last `print ''` is for newlines after executed commands
}

# Generate a table statement with optional width specification.
#
# > 'ls' | generate-table-statement
# ls | table
#
# > $env.numd.table-width = 10; 'ls' | generate-table-statement
# ls | table --width 10
export def generate-table-statement []: string -> string {
    if $env.numd?.table-width? == null {
        $"($in) | table"
    } else {
        $"($in) | table --width ($env.numd.table-width)"
    }
}

export def generate-picture [] {
    $"($in) | table | do {|i| stor open | query db \"insert into 'captures' \(capture) values \(?)\" -p [$i]} $in"
}


# Generate a try-catch block to handle errors in the current Nushell instance.
#
# > 'ls' | create-catch-error-current-instance
# try {ls} catch {|error| $error}
export def create-catch-error-current-instance []: string -> string {
    $"try {($in)} catch {|error| $error}"
}

# Execute the command outside to obtain a formatted error message if any.
#
# > 'ls' | create-catch-error-outside
# /Users/user/.cargo/bin/nu -c "ls"| complete | if ($in.exit_code != 0) {get stderr} else {get stdout}
export def create-catch-error-outside []: string -> string {
    escape-special-characters-and-quote
    | ($'($nu.current-exe) -c ($in)' +
        " | complete | if ($in.exit_code != 0) {get stderr} else {get stdout}")
}

# Generate a fenced code block for output with a specific format.
export def create-fence-output []: string -> string {
    # We use a combination of "\n" and (char nl) here for itermid script formatting aesthetics
    $"\"```\\n```output-numd\" | print(char nl)(char nl)($in)"
}

export def generate-print-lines []: list -> string {
    str join (char nl)
    | escape-special-characters-and-quote
    | $'($in) | print'
}

# Parse options from a code fence and return them as a list.
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

# Modify a path by adding a prefix, suffix, extension, or parent directory.
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
            | $'(mkdir $in)($in)' # The author doesn't like it, but tee in 0.91 somehow consumes and produces a list here
        }
    } else {}
    | path join
}

# Create a backup of a file by moving it to a specified directory with a timestamp.
export def create-file-backup [
    file_path: path
]: nothing -> nothing {
    $file_path
    | if ($in | path exists) and ($in | path type) == 'file' {
        modify-path --parent_dir 'zzz_md_backups' --suffix $'-(generate-timestamp)'
        | mv $file_path $in
    }
}

#todo make config - an env record

export def --env load-config [
    path: path # path to .yaml numd config file
    --prepend_code: any
    --table_width: any
] {
    $env.numd = (
        [
            [key value];

            [prepend-code $prepend_code]
            [table-width $table_width]
        ]
        | if $path != '' {
            append (
                open $path
                | upsert config-path $path
                | transpose key value
            )
        } else {}
        | where value != null
        | if ($in | is-empty) {{}} else {
            transpose --ignore-titles --as-record --header-row
        }
    )
}

# Generate a timestamp string in the format YYYYMMDD_HHMMSS.
#
# > generate-timestamp
# 20240825_091300
export def generate-timestamp []: nothing -> string {
    date now | format date "%Y%m%d_%H%M%S"
}
