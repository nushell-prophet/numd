# Run Nushell code blocks in a markdown file, output results back to the `.md`, and optionally to terminal
export def run [
    file: path # path to a `.md` file containing Nushell code to be executed
    --result-md-path (-o): path # path to a resulting `.md` file; if omitted, updates the original file
    --print-block-results # print blocks one by one as they are executed
    --echo # output resulting markdown to the terminal
    --save-ansi # save ANSI formatted version
    --no-backup # overwrite the existing `.md` file without backup
    --no-save # do not save changes to the `.md` file
    --no-stats # do not output stats of changes
    --intermed-script: path # optional path for keeping intermediate script (useful for debugging purposes). If not set, the temporary intermediate script will be deleted.
    --no-fail-on-error # skip errors (and don't update markdown in case of errors anyway)
    --prepend-code: string # prepend code into the intermediate script, useful for customizing Nushell output settings
    --table-width: int # set the `table --width` option value
    --config-path: path = '' # path to a config file
]: [nothing -> string, nothing -> nothing, nothing -> record] {
    let $original_md = open -r $file
        | if $nu.os-info.family == windows {
            str replace --all --regex (char crlf) "\n"
        } else {}

    let $original_md_table = $original_md
        | toggle-output-fences # should be unnecessary for new files
        | find-code-blocks

    # $original_md_table | save -f ($file + '_original_md_table.json')

    load-config $config_path --prepend_code $prepend_code --table_width $table_width

    let $intermediate_script_path = $intermed_script
        | default ( $file | modify-path --prefix $'numd-temp-(generate-timestamp)' --extension '.nu' )
        # We don't use a temp directory here as the code in `md` files might contain relative paths,
        # which will only work if we execute the intermediate script from the same folder.

    decortate-original-code-blocks $original_md_table
    | generate-intermediate-script
    | save -f $intermediate_script_path

    let $nu_res_with_block_index = execute-intermediate-script $intermediate_script_path $no_fail_on_error $print_block_results
        | if $in == '' {
            return { filename: $file,
                comment: "the script didn't produce any output" }
        } else {}
        | str replace -ar "\n{2,}```\n" "\n```\n"
        | lines
        | extract-block-index $in

    # $nu_res_with_block_index | save -f ($file + '_intermed_exec.json')

    let $updated_md_ansi = merge-markdown $original_md_table $nu_res_with_block_index
        | clean-markdown
        | toggle-output-fences --back

    # if $intermed_script param wasn't set - remove the temporary intermediate script
    if $intermed_script == null { rm $intermediate_script_path }

    let $output_path = $result_md_path | default $file

    if not $no_save {
        if not $no_backup { create-file-backup $output_path }
        $updated_md_ansi | ansi strip | save -f $output_path
    }

    if $save_ansi { $updated_md_ansi | save -f $'($output_path).ans' }

    if not $no_stats {
        compute-change-stats $output_path $original_md $updated_md_ansi
        | if not $echo {
            return $in # default variant: we return here a record
        } else {
            table # we continue here with `string` as it will be appended to the resulting `string` markdown
        }
    } else {}
    | if $echo {prepend $updated_md_ansi} else {} # output the changes stat table below the resulting markdown
    | if $in == null {} else { str join (char nl) }
}

# Remove numd execution outputs from the file
export def clear-outputs [
    file: path # path to a `.md` file containing numd output to be cleared
    --result-md-path (-o): path # path to a resulting `.md` file; if omitted, updates the original file
    --echo # output resulting markdown to the terminal instead of writing to file
    --strip-markdown # keep only Nushell script, strip all markdown tags
]: [nothing -> string, nothing -> nothing] {
    let $original_md_table = open -r $file
        | toggle-output-fences
        | find-code-blocks

    let $result_md_path = $result_md_path | default $file

    $original_md_table
    | where action == 'execute'
    | group-by block_index
    | items {|block_index block_lines|
        $block_lines.line.0
        | if ($in | where $it =~ '^>' | is-empty) {} else {
            where $it =~ '^(>|#|```)'
        }
        | prepend (mark-code-block $block_index)
    }
    | flatten
    | extract-block-index $in
    | if $strip_markdown {
        get line
        | each {
            lines
            | update 0 {$'(char nl)    # ($in)'} # keep infostring
            | drop
            | str replace --all --regex '^>\s*' ''
            | str join (char nl)
            | str replace -r '\s*$' (char nl)
        }
        | str join (char nl)
        | return $in # we return the stripped script here to not spoil original md
    } else {
        merge-markdown $original_md_table $in
        | clean-markdown
    }
    | if $echo {} else { save -f $result_md_path }
}


# start capturing commands and their outputs into a file
export def --env 'capture start' [
    file: path = 'numd_capture.md'
    --separate # don't use `>` notation, create separate blocks for each pipeline
]: nothing -> nothing {
    cprint $'numd commands capture has been started.
        Commands and their outputs of the current nushell instance
        will be appended to the *($file)* file.'

    $env.numd.status = 'running'
    $env.numd.path = ($file | path expand)
    $env.numd.separate-blocks = $separate

    if not $separate { "```nushell\n" | save -a $env.numd.path }

    $env.backup.hooks.display_output = (
        $env.config.hooks?.display_output?
        | default {
            if (term size).columns >= 100 { table -e } else { table }
        }
    )

    $env.config.hooks.display_output = {
        let $input = $in
        let $command = history | last | get command

        $input
        | if (term size).columns >= 100 { table -e } else { table }
        | into string
        | ansi strip
        | default (char nl)
        | if $env.numd.separate-blocks {
            $"```nushell\n($command)\n```\n```output-numd\n($in)\n```\n\n"
            | str replace --regex --all "[\n\r ]+```\n" "\n```\n"
        } else {
            $"> ($command)\n($in)\n\n"
        }
        | str replace --regex "\n{3,}$" "\n\n"
        | if ($in !~ 'numd capture') { # don't save numd capture managing commands
            save --append --raw $env.numd.path
        }

        print -n $input # without the `-n` flag new line is added to an output
    }
}

# stop capturing commands and their outputs
export def --env 'capture stop' [ ]: nothing -> nothing {
    $env.config.hooks.display_output = $env.backup.hooks.display_output

    let $file = $env.numd.path

    if not $env.numd.separate-blocks {
        $"(open $file)```\n"
        | clean-markdown
        | save --force $file
    }

    cprint $'numd commands capture to the *($file)* file has been stopped.'

    $env.numd.status = 'stopped'
}

# Beautify and adapt the standard `--help` for markdown output
export def 'parse-help' [
    --sections: list
    --record
] {
    let help_lines = split row '======================'
        | first # quick fix for https://github.com/nushell/nushell/issues/13470
        | ansi strip
        | str replace --all 'Search terms:' "Search terms:\n"
        | str replace --all ':  (optional)' ' (optional)'
        | lines
        | str trim
        | if ($in.0 == 'Usage:') {} else {prepend 'Description:'}

    let $regex = [
            Description
            "Search terms"
            Usage
            Subcommands
            Flags
            Parameters
            "Input/output types"
            Examples
        ]
        | str join '|'
        | '^(' + $in + '):'

    let $existing_sections = $help_lines
        | where $it =~ $regex
        | str trim --right --char ':'
        | wrap chapter

    let $elements = $help_lines
        | split list -r $regex
        | wrap elements

    $existing_sections
    | merge $elements
    | transpose -idr
    | update 'Flags' {where $it !~ '-h, --help'}
    | if ($in.Flags | length) == 1 {reject 'Flags'} else {} # todo now flags contain fields with empty row
    | if ($in.Description | split list '' | length) > 1 {
        let $input = $in

        $input
        | update Description ($input.Description | take until {|line| $line == ''} | append '')
        | upsert Examples {|i| $i.Examples? | append ($input.Description | skip until {|line| $line == ''} | skip)}
    } else {}
    | if $sections == null {} else { select -i ...$sections }
    | if $record {
        items {|k v|
            {$k: ($v | str join (char nl))}
        }
        | into record
    } else {
        items {|k v| $v
            | str replace -r '^\s*(\S)' '  $1' # add two spaces before description lines
            | str join (char nl)
            | $"($k):\n($in)"
        }
        | str join (char nl)
        | str replace -ar '\s+$' '' # empty trailing new lines
        | str replace -arm '^' '// '
    }
}

####
# I keep commands here with `export` to make them availible for testing script, yet I do not export them in the mod.nu
###

# Detect code blocks in a markdown string and return a table with their line numbers and info strings.
export def find-code-blocks []: string -> table {
    let $file_lines = $in | lines
    let $row_type = $file_lines
        | each {
            str trim --right
            | if $in =~ '^```' {} else {'text'}
        }
        | scan --noinit 'text' {|curr_fence prev_fence|
            match $curr_fence {
                'text' => { if $prev_fence == 'closing-fence' { 'text' } else { $prev_fence } }
                '```' => { if $prev_fence == 'text' { '```' } else { 'closing-fence' } }
                _ => { $curr_fence }
            }
        }
        | scan --noinit 'text' {|curr_fence prev_fence|
            if $curr_fence == 'closing-fence' { $prev_fence } else { $curr_fence }
        }

    let $block_index = $row_type
        | window --remainder 2
        | scan 0 {|curr_line prev_line|
            if $curr_line.0 == $curr_line.1? { $prev_line } else { $prev_line + 1 }
        }

    # Wrap lists into columns because the `window` command was used previously
    $file_lines | wrap line
    | merge ($row_type | wrap row_type)
    | merge ($block_index | wrap block_index)
    | if ($in | last | $in.row_type =~ '^```nu' and $in.line != '```') {
        error make {
            msg: 'A closing code block fence (```) is missing; the markdown might be invalid.'
        }
    } else {}
    | group-by block_index --to-table
    | insert row_type {|i| $i.items.row_type.0}
    | update items {get line}
    | rename block_index line row_type
    | select block_index row_type line
    | into int block_index
    | insert action {|i| match-action $i.row_type}
}

export def match-action [
    $row_type: string
] {
    match $row_type {
        'text' => {'print-as-it-is'}
        '```output-numd' => {'delete'}

        $i if ($i =~ '^```nu(shell)?(\s|$)') => {
            if $i =~ 'no-run' {'print-as-it-is'} else {'execute'}
        }

        _ => {'print-as-it-is'}
    }
}

# Generate code for execution in the intermediate script within a given code fence.
#
# > 'ls | sort-by modified -r' | create-execution-code --whole_block ['indent-output'] | save z_examples/999_numd_internals/create-execution-code_0.nu -f
export def create-execution-code [
    $fence_options
    --whole_block
]: string -> string {
    let $code_content = $in
    # let $fence_options = $env.numd.current_block_options

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
            if $whole_block { create-fence-output } else {}
            | if (check-print-append $in) {
                if 'indent-output' in $fence_options { create-indented-output } else {}
                | generate-print-statement
            } else {}
        }
        | $in + (char nl)

    $highlighted_command + $code_execution
}

# generates additional service code necessary for execution and capturing results, while preserving the original code.
export def decortate-original-code-blocks [
    $md_classified: table
]: nothing -> table {
    $md_classified
    | where action == 'execute'
    | insert code {|i|
        $i.line
        | execute-block-lines ($i.row_type | extract-fence-options)
        | generate-tags $i.block_index $i.row_type
    }
}

# Generate an intermediate script from a table of classified markdown code blocks.
export def generate-intermediate-script [ ]: table -> string {
    get code -i
    | if $env.numd?.prepend-code? != null {
        prepend $"($env.numd?.prepend-code?)\n"
        | if $env.numd.config-path? != null {
            prepend ($"# numd config loaded from `($env.numd.config-path)`\n")
        } else {}
    } else {}
    | prepend $"const init_numd_pwd_const = '(pwd)'\n" # initialize it here so it will be available in intermediate scripts
    | prepend ( '# this script was generated automatically using numd' +
        "\n# https://github.com/nushell-prophet/numd\n" )
    | flatten
    | str join (char nl)
    | str replace -r "\\s*$" "\n"
}

export def execute-block-lines [
    $fence_options
 ]: list -> list {
    skip | drop # skip code fences
    | if ($in | where $it =~ '^>' | is-empty) {  # find blocks with no `>` symbol to execute them entirely
        str join (char nl)
        | create-execution-code $fence_options --whole_block
    } else {
        each { # define what to do with each line of the current block one by one
            if $in starts-with '>' { # if a line starts with `>`, execute it
                create-execution-code $fence_options
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
    let $clean_lines = $nu_res_stdout_lines
        | skip until {|x| $x =~ (mark-code-block)}

    let $block_index = $clean_lines
        | each {
            if $in =~ $"^(mark-code-block)\\d+$" {
                split row '-' | last | into int
            } else {
                -1
            }
        }
        | scan --noinit 0 {|curr_index prev_index|
            if $curr_index == -1 {$prev_index} else {$curr_index}
        }
        | wrap block_index

    $clean_lines
    | wrap 'nu_out'
    | merge $block_index
    | group-by block_index --to-table
    | upsert items {
        |i| $i.items.nu_out
        | skip
        | take until {|x| $x =~ (mark-code-block --end)}
        | str join (char nl)
    }
    | rename block_index line
    | into int block_index
}

# Assemble the final markdown by merging the original classified markdown with parsed results of the generated script.
export def merge-markdown [
    $md_classified: table
    $nu_res_with_block_index: table
]: nothing -> string {
    $md_classified
    | where action == 'print-as-it-is'
    | update line {str join (char nl)}
    | append $nu_res_with_block_index
    | sort-by block_index
    | get line
    | str join (char nl)
}

# Prettify markdown by removing unnecessary empty lines and trailing spaces.
export def clean-markdown []: string -> string {
    str replace --all --regex "\n```output-numd\\s+```\n" "\n" # empty output-numd blocks
    | str replace --all --regex "\n{3,}" "\n\n" # multiple newlines
    | str replace --all --regex " +\n" "\n" # remove trailing spaces
    | str replace --all --regex "\\s*$" "\n" # ensure a single trailing newline
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
    let $original_file_content = $orig_file | ansi strip
    let $new_file_content = $new_file | ansi strip

    let $nushell_blocks = $new_file_content
        | find-code-blocks
        | where action == 'execute'
        | get block_index
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
        # ["picture-output" "p" "capture output as picture and place after block"]
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
    | if $print_block_results { tee {print} } else {}
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
# #code-block-marker-open-3
export def mark-code-block [
    index?: int
    --end
]: nothing -> string {
    $"#code-block-marker-open-($index)"
    | if $end { str replace 'open' 'close' } else {}
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
# > get-last-span 'let a = 1..10; let b = $a | length'
# let b = $a | length
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
        | if ($in | length) == 1 {} else { sort | skip }
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
# /Users/user/.cargo/bin/nu -c "ls" | complete | if ($in.exit_code != 0) {get stderr} else {get stdout}
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

export def generate-tags [
    $block_number
    $fence
]: list -> string {
    let $input = $in

    mark-code-block $block_number
    | append $fence
    | generate-print-lines
    | append $input
    | append '"```" | print'
    | append ''
    | str join (char nl)
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
    | if $extension != null { update extension {$in + $extension} } else {}
    | if $parent_dir != null {
        update parent { path join $parent_dir | $'(mkdir $in)($in)' }
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
            # if table_width or prepend code are set via parameters - they will have precendece
            transpose --ignore-titles --as-record --header-row
        }
    )
}

# Generate a timestamp string in the format YYYYMMDD_HHMMSS.
#
# > generate-timestamp
# 20241128_222140
export def generate-timestamp []: nothing -> string {
    date now | format date "%Y%m%d_%H%M%S"
}

# I hardcode scan from 0.101 version here, as there were a breaking change
# to give chance for execution in previous untested nushell versions

# Returns a list of intermediate steps performed by `reduce`
# (`fold`). It takes two arguments, an initial value to seed the
# initial state and a closure that takes two arguments, the first
# being the list element in the current iteration and the second
# the internal state.
# The internal state is also provided as pipeline input.
#
# # Example
# ```
# use std ["assert equal" "iter scan"]
# let scanned = ([1 2 3] | iter scan 0 {|x, y| $x + $y})
#
# assert equal $scanned [0, 1, 3, 6]
#
# # use the --noinit(-n) flag to remove the initial value from
# # the final result
# let scanned = ([1 2 3] | iter scan 0 {|x, y| $x + $y} -n)
#
# assert equal $scanned [1, 3, 6]
# ```
export def scan [ # -> list<any>
    init: any            # initial value to seed the initial state
    fn: closure          # the closure to perform the scan
    --noinit(-n)         # remove the initial value from the result
] {
    reduce --fold [$init] {|it, acc|
        let acc_last = $acc | last
        $acc ++ [($acc_last | do $fn $it $acc_last)]
    }
    | if $noinit {
        $in | skip
    } else {
        $in
    }
}
