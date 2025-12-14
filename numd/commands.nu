use std/iter scan

# Run Nushell code blocks in a markdown file, output results back to the `.md`, and optionally to terminal
@example "update readme" {
    numd run README.md
}
export def run [
    file: path # path to a `.md` file containing Nushell code to be executed
    --result-md-path (-o): path # path to a resulting `.md` file; if omitted, updates the original file
    --print-block-results # print blocks one by one as they are executed
    --echo # output resulting markdown to the terminal
    --save-ansi # save ANSI formatted version
    --no-backup # overwrite the existing `.md` file without backup
    --no-save # do not save changes to the `.md` file
    --no-stats # do not output stats of changes
    --save-intermed-script: path # optional path for keeping intermediate script (useful for debugging purposes). If not set, the temporary intermediate script will be deleted.
    --no-fail-on-error # skip errors (and don't update markdown in case of errors anyway)
    --prepend-code: string # prepend code into the intermediate script, useful for customizing Nushell output settings
    --table-width: int # set the `table --width` option value
    --config-path: path = '' # path to a config file
]: [nothing -> string nothing -> nothing nothing -> record] {
    let original_md = open -r $file
    | if $nu.os-info.family == windows {
        str replace --all (char crlf) "\n"
    } else { }

    let original_md_table = $original_md
    | convert-output-fences # should be unnecessary for new files
    | parse-markdown-to-blocks

    load-config $config_path --prepend_code $prepend_code --table_width $table_width

    let intermediate_script_path = $save_intermed_script
    | default ($file | build-modified-path --prefix $'numd-temp-(generate-timestamp)' --extension '.nu')
    # We don't use a temp directory here as the code in `md` files might contain relative paths,
    # which will only work if we execute the intermediate script from the same folder.

    decorate-original-code-blocks $original_md_table
    | generate-intermediate-script
    | save -f $intermediate_script_path

    let nu_res_with_block_index = execute-intermediate-script $intermediate_script_path $no_fail_on_error $print_block_results
    | if $in == '' {
        return {
            filename: $file
            comment: "the script didn't produce any output"
        }
    } else { }
    | str replace -ar "\n{2,}```\n" "\n```\n"
    | lines
    | extract-block-index

    let updated_md_ansi = merge-markdown $original_md_table $nu_res_with_block_index
    | clean-markdown
    | convert-output-fences --restore

    # if $save_intermed_script param wasn't set - remove the temporary intermediate script
    if $save_intermed_script == null { rm $intermediate_script_path }

    let output_path = $result_md_path | default $file

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
    } else { }
    | if $echo { prepend $updated_md_ansi } else { } # output the changes stat table below the resulting markdown
    | if $in == null { } else { str join (char nl) }
}

# Remove numd execution outputs from the file
export def clear-outputs [
    file: path # path to a `.md` file containing numd output to be cleared
    --result-md-path (-o): path # path to a resulting `.md` file; if omitted, updates the original file
    --echo # output resulting markdown to the terminal instead of writing to file
    --strip-markdown # keep only Nushell script, strip all markdown tags
]: [nothing -> string nothing -> nothing] {
    let original_md_table = open -r $file
    | convert-output-fences
    | parse-markdown-to-blocks

    let result_md_path = $result_md_path | default $file

    $original_md_table
    | where action == 'execute'
    | group-by block_index
    | items {|block_index block_lines|
        $block_lines.line.0
        | where $it !~ '^# => ?' # strip `# =>` output lines, preserve plain `#` comments
        | prepend (code-block-marker $block_index)
    }
    | flatten
    | extract-block-index
    | if $strip_markdown {
        get line
        | each {
            lines
            | update 0 { $'(char nl)    # ($in)' } # keep infostring
            | drop
            | str join (char nl)
            | str replace -r '\s*$' (char nl)
        }
        | str join (char nl)
        | return $in # we return the stripped script here to not spoil original md
    } else {
        merge-markdown $original_md_table $in
        | clean-markdown
    }
    | if $echo { } else { save -f $result_md_path }
}

# start capturing commands and their outputs into a file
export def --env 'capture start' [
    file: path = 'numd_capture.md'
    --separate-blocks # create separate code blocks for each pipeline instead of inline `# =>` output
]: nothing -> nothing {
    cprint $'numd commands capture has been started.
        Commands and their outputs of the current nushell instance
        will be appended to the *($file)* file.

        Beware that your `display_output` hook has been changed.
        It will be reverted when you use `numd capture stop`'

    $env.numd.status = 'running'
    $env.numd.path = ($file | path expand)
    $env.numd.separate-blocks = $separate_blocks

    if not $separate_blocks { "```nushell\n" | save -a $env.numd.path }

    $env.backup.hooks.display_output = (
        $env.config.hooks?.display_output?
        | default {
            if (term size).columns >= 100 { table -e } else { table }
        }
    )

    $env.config.hooks.display_output = {
        let input = $in
        let command = history | last | get command

        $input
        | default ''
        | if (term size).columns >= 100 { table -e } else { table }
        | into string
        | ansi strip
        | default (char nl)
        | if $env.numd.separate-blocks {
            $"```nushell\n($command)\n```\n```output-numd\n($in)\n```\n\n"
            | str replace --regex --all "[\n\r ]+```\n" "\n```\n"
        } else {
            # inline output format: command followed by `# =>` prefixed output
            let output_lines = $in | lines | each { $'# => ($in)' } | str join (char nl)
            $"($command)\n($output_lines)\n\n"
        }
        | str replace --regex "\n{3,}$" "\n\n"
        | if ($in !~ 'numd capture') {
            # don't save numd capture managing commands
            save --append --raw $env.numd.path
        }

        print -n $input # without the `-n` flag new line is added to an output
    }
}

# stop capturing commands and their outputs
export def --env 'capture stop' []: nothing -> nothing {
    $env.config.hooks.display_output = $env.backup.hooks.display_output

    let file = $env.numd.path

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
    --sections: list<string> # filter to only include these sections (e.g., ['Usage', 'Flags'])
    --record # return result as a record instead of formatted string
]: string -> any {
    let help_lines = split row '======================'
    | first # quick fix for https://github.com/nushell/nushell/issues/13470
    | ansi strip
    | str replace --all 'Search terms:' "Search terms:\n"
    | str replace --all ':  (optional)' ' (optional)'
    | lines
    | str trim
    | if ($in.0 != 'Usage:') { prepend 'Description:' } else { }

    let regex = [
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

    let existing_sections = $help_lines
    | where $it =~ $regex
    | str trim --right --char ':'
    | wrap chapter

    let elements = $help_lines
    | split list -r $regex
    | skip
    | wrap elements

    $existing_sections
    | merge $elements
    | transpose --as-record --ignore-titles --header-row
    | if ($in.Flags? == null) { } else { update 'Flags' { where $it !~ '-h, --help' } }
    | if ($in.Flags? | length) == 1 { reject 'Flags' } else { } # todo now flags contain fields with empty row
    | if ($in.Description? | default '' | split list '' | length) > 1 {
        let input = $in

        $input
        | update Description ($input.Description | take until { $in == '' } | append '')
        | upsert Examples {|i| $i.Examples? | append ($input.Description | skip until { $in == '' } | skip) }
    } else { }
    | if $sections == null { } else { select -o ...$sections }
    | if $record {
        items {|k v|
            {$k: ($v | str join (char nl))}
        }
        | into record
    } else {
        items {|k v|
            $v
            | str replace -r '^\s*(\S)' '  $1' # add two spaces before description lines
            | str join (char nl)
            | $"($k):\n($in)"
        }
        | str join (char nl)
        | str replace -ar '\s+$' '' # empty trailing new lines
        | str replace -arm '^' '# => '
    }
}

####
# I keep commands here with `export` to make them available for testing script, yet I do not export them in the mod.nu
###

# Detect code blocks in a markdown string and return a table with their line numbers and info strings.
export def parse-markdown-to-blocks []: string -> table<block_index: int, row_type: string, line: list<string>, action: string> {
    let file_lines = $in | lines
    let row_type = $file_lines
    | each {
        str trim --right
        | if $in =~ '^```' { } else { 'text' }
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

    let block_index = $row_type
    | window --remainder 2
    | scan 0 {|window index|
        if $window.0 == $window.1? { $index } else { $index + 1 }
    }

    # Wrap lists into columns because the `window` command was used previously
    $file_lines | wrap line
    | merge ($row_type | wrap row_type)
    | merge ($block_index | wrap block_index)
    | if ($in | last | $in.row_type =~ '^```nu' and $in.line != '```') {
        error make {
            msg: 'A closing code block fence (```) is missing; the markdown might be invalid.'
        }
    } else { }
    | group-by block_index --to-table
    | insert row_type { $in.items.row_type.0 }
    | update items { get line }
    | rename block_index line row_type
    | select block_index row_type line
    | into int block_index
    | insert action { classify-block-action $in.row_type }
}

export def classify-block-action [
    $row_type: string
]: nothing -> string {
    match $row_type {
        'text' => { 'print-as-it-is' }
        '```output-numd' => { 'delete' }

        $i if ($i =~ '^```nu(shell)?(\s|$)') => {
            if $i =~ 'no-run' { 'print-as-it-is' } else { 'execute' }
        }

        _ => { 'print-as-it-is' }
    }
}

# Apply output formatting based on fence options (separate-block vs inline `# =>`).
def format-command-output [fence_options: list<string>]: string -> string {
    if 'no-output' in $fence_options { return $in } else { }
    | if 'separate-block' in $fence_options { generate-separate-block-fence } else { }
    | if (can-append-print $in) {
        generate-inline-output-pipeline
        | generate-print-statement
    } else { }
}

# Generate code for execution in the intermediate script within a given code fence.
#
# > 'ls | sort-by modified -r' | generate-block-execution ['no-output'] | save z_examples/999_numd_internals/generate-block-execution_0.nu -f
export def generate-block-execution [
    fence_options: list<string>
]: string -> string {
    let code_content = $in

    let highlighted_command = $code_content | generate-highlight-print

    let code_execution = $code_content
    | trim-trailing-comments
    | if 'try' in $fence_options {
        wrap-in-try-catch --new-instance=('new-instance' in $fence_options)
    } else { }
    | format-command-output $fence_options
    | $in + (char nl)
    # Always print a blank line after each command group to preserve visual separation
    | $in + "print ''"

    $highlighted_command + $code_execution
}

# Generate additional service code necessary for execution and capturing results, while preserving the original code.
export def decorate-original-code-blocks [
    md_classified: table<block_index: int, row_type: string, line: list<string>, action: string> # classified markdown table from parse-markdown-to-blocks
]: nothing -> table<block_index: int, row_type: string, line: list<string>, action: string, code: string> {
    $md_classified
    | where action == 'execute'
    | insert code {|i|
        $i.line
        | process-code-block-content ($i.row_type | extract-fence-options)
        | generate-block-markers $i.block_index $i.row_type
    }
}

# Generate an intermediate script from a table of classified markdown code blocks.
#
# Takes decorated code blocks and produces a complete Nushell script ready for execution.
export def generate-intermediate-script []: table<block_index: int, row_type: string, line: list<string>, action: string, code: string> -> string {
    get code -o
    | if $env.numd?.prepend-code? != null {
        prepend $"($env.numd?.prepend-code?)\n"
        | if $env.numd.config-path? != null {
            prepend ($"# numd config loaded from `($env.numd.config-path)`\n")
        } else { }
    } else { }
    | prepend $"const init_numd_pwd_const = '(pwd)'\n" # initialize it here so it will be available in intermediate scripts
    | prepend (
        '# this script was generated automatically using numd' +
        "\n# https://github.com/nushell-prophet/numd\n"
    )
    | flatten
    | str join (char nl)
    | str replace -r "\\s*$" "\n"
}

# Split code block content by blank lines into command groups, execute each, insert `# =>` output.
export def process-code-block-content [
    fence_options: list<string> # options from the code fence (e.g., 'no-output', 'try')
]: list<string> -> list<string> {
    skip | drop # skip code fences
    | where $it !~ '^# =>' # strip existing `# =>` output lines (keep plain `#` comments)
    | str join (char nl)
    | split-by-blank-lines
    | each {|group|
        let trimmed = $group | str trim
        if ($trimmed | is-empty) {
            ''
        } else if ($trimmed | lines | all { $in =~ '^#' }) {
            $group | generate-highlight-print
        } else {
            $group | generate-block-execution $fence_options
        }
    }
}

# Split string by blank lines (double newlines) into command groups.
# Preserves multiline commands that don't have blank lines between them.
export def split-by-blank-lines []: string -> list<string> {
    split row "\n\n"
    | each { str trim -c "\n" }
}

# Parse block indices from Nushell output lines and return a table with the original markdown line numbers.
export def extract-block-index []: list<string> -> table<block_index: int, line: string> {
    let clean_lines = skip until { $in =~ (code-block-marker) }

    let block_index = $clean_lines
    | each {
        if $in =~ $"^(code-block-marker)\\d+$" {
            split row '-' | last | into int
        } else {
            -1
        }
    }
    | scan --noinit 0 {|curr_index prev_index|
        if $curr_index == -1 { $prev_index } else { $curr_index }
    }
    | wrap block_index

    $clean_lines
    | wrap 'nu_out'
    | merge $block_index
    | group-by block_index --to-table
    | upsert items {|i|
        $i.items.nu_out
        | skip
        | take until { $in =~ (code-block-marker --end) }
        | str join (char nl)
    }
    | rename block_index line
    | into int block_index
}

# Assemble the final markdown by merging the original classified markdown with parsed results of the generated script.
export def merge-markdown [
    md_classified: table<block_index: int, row_type: string, line: list<string>, action: string>
    nu_res_with_block_index: table<block_index: int, line: string>
]: nothing -> string {
    $md_classified
    | where action == 'print-as-it-is'
    | update line { str join (char nl) }
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
# `parse-markdown-to-blocks` works only with lines without knowing the previous lines.
@example "convert output fence to compact format" {
    "```nu\n123\n```\n\nOutput:\n\n```\n123" | convert-output-fences
} --result "```nu\n123\n```\n```output-numd\n123"
export def convert-output-fences [
    expanded_format = "\n```\n\nOutput:\n\n```\n" # default params to prevent collecting $in
    compact_format = "\n```\n```output-numd\n"
    --restore # convert back from compact to expanded format
]: string -> string {
    if $restore {
        str replace --all $compact_format $expanded_format
    } else {
        str replace --all $expanded_format $compact_format
    }
}

# Calculate changes between the original and updated markdown files and return a record with the differences.
export def compute-change-stats [
    filename: path
    orig_file: string
    new_file: string
]: nothing -> record {
    let original_file_content = $orig_file | ansi strip
    let new_file_content = $new_file | ansi strip

    let nushell_blocks = $new_file_content
    | parse-markdown-to-blocks
    | where action == 'execute'
    | get block_index
    | uniq
    | length

    $new_file_content | str stats | transpose metric new
    | merge ($original_file_content | str stats | transpose metric old)
    | insert change_percentage {|metric_stats|
        let change_value = $metric_stats.new - $metric_stats.old

        ($change_value / $metric_stats.old) * 100
        | math round --precision 1
        | if $in < 0 {
            $"(ansi red)($change_value) \(($in)%\)(ansi reset)"
        } else if ($in > 0) {
            $"(ansi blue)+($change_value) \(($in)%\)(ansi reset)"
        } else { '0%' }
    }
    | update metric { $'diff_($in)' }
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
]: [nothing -> record nothing -> table] {
    [
        ["long" "short" "description"];

        ["no-output" "O" "execute code without outputting results"]
        ["no-run" "N" "do not execute code in block"]
        ["try" "t" "execute block inside `try {}` for error handling"]
        ["new-instance" "n" "execute block in new Nushell instance (useful with `try` block)"]
        ["separate-block" "s" "output results in a separate code block instead of inline `# =>`"]
        # ["picture-output" "p" "capture output as picture and place after block"]
    ]
    | if $list { } else {
        select short long
        | transpose --as-record --ignore-titles --header-row
    }
}

# Expand short options for code block execution to their long forms.
@example "expand short option to long form" {
    convert-short-options 'O'
} --result 'no-output'
export def convert-short-options [
    option: string
]: nothing -> string {
    let options_dict = list-code-options
    let result = $options_dict | get --optional $option | default $option

    if $result not-in ($options_dict | values) {
        print $'(ansi red)($result) is unknown option(ansi reset)'
    }

    $result
}

# Escape symbols to be printed unchanged inside a `print "something"` statement.
@example "escape quotes for print statement" {
    'abcd"dfdaf" "' | quote-for-print
} --result '"abcd\"dfdaf\" \""'
export def quote-for-print []: string -> string {
    # `to json` might give similar results, yet it replaces new lines
    # which spoils readability of intermediate scripts
    str replace --all --regex '(\\|\")' '\$1'
    | $'"($in)"'
}

# Run the intermediate script and return its output as a string.
export def execute-intermediate-script [
    intermed_script_path: path # path to the generated intermediate script
    no_fail_on_error: bool # if true, return empty string on error instead of failing
    print_block_results: bool # print blocks one by one as they execute
]: nothing -> string {
    (
        ^$nu.current-exe --env-config $nu.env-path --config $nu.config-path
        --plugin-config $nu.plugin-path $intermed_script_path
    )
    | if $print_block_results { tee { print } } else { }
    | complete
    | if $in.exit_code == 0 {
        get stdout
    } else {
        if $no_fail_on_error {
            ''
        } else {
            error make --unspanned {msg: ($in.stderr? | default '' | into string)} # default '' - to refactor later
        }
    }
}

# Generate a unique identifier for code blocks in markdown to distinguish their output.
@example "generate marker for block 3" {
    code-block-marker 3
} --result "#code-block-marker-open-3"
export def code-block-marker [
    index?: int
    --end
]: nothing -> string {
    $"#code-block-marker-open-($index)"
    | if $end { str replace 'open' 'close' } else { }
}
# TODO NUON can be used in code-block-markers to set display options

# Generate a command to highlight code using Nushell syntax highlighting.
@example "generate syntax highlighting command" {
    'ls' | generate-highlight-print
} --result "\"ls\" | nu-highlight | print\n\n"
export def generate-highlight-print []: string -> string {
    quote-for-print
    | $"($in) | nu-highlight | print(char nl)(char nl)"
}

# Trim comments and extra whitespace from code blocks for use in the generated script.
export def trim-trailing-comments []: string -> string {
    str replace -r '[\s\n]+$' '' # trim newlines and spaces from the end of a line
    | str replace -r '\s+#.*$' '' # remove comments from the last line. Might spoil code blocks with the # symbol, used not for commenting
}

# Extract the last span from a command to determine if `| print` can be appended.
@example "pipeline ending with command" { get-last-span 'let a = 1..10; $a | length' } --result 'length'
@example "pipeline ending with assignment" { get-last-span 'let a = 1..10; let b = $a | length' } --result 'let b = $a | length'
@example "statement ending with semicolon" { get-last-span 'let a = 1..10; ($a | length);' } --result 'let a = 1..10; ($a | length);'
@example "expression in parentheses" { get-last-span 'let a = 1..10; ($a | length)' } --result '($a | length)'
@example "single assignment" { get-last-span 'let a = 1..10' } --result 'let a = 1..10'
@example "string literal" { get-last-span '"abc"' } --result '"abc"'
export def get-last-span [
    command: string
]: nothing -> string {
    let command = $command | str trim
    let spans = ast $command --json
    | get block
    | from json
    | to yaml
    | parse -r 'span:\n\s+start:(.*)\n\s+end:(.*)'
    | rename start end
    | into int start end

    #  I just brute-forced AST filter parameters in nu 0.97, as `ast` awaits a better replacement or improvement.
    let last_span_end = $spans.end | math max
    let longest_last_span_start = $spans
    | where end == $last_span_end
    | get start
    | if ($in | length) == 1 { } else { sort | skip }
    | first

    let offset = $longest_last_span_start - $last_span_end

    $command
    | str substring $offset..
}

# Check if the command can have `| print` appended by analyzing its last span for semicolons or declaration keywords.
@example "assignment cannot have print appended" { can-append-print 'let a = ls' } --result false
@example "command can have print appended" { can-append-print 'ls' } --result true
@example "mutation cannot have print appended" { can-append-print 'mut a = 1; $a = 2' } --result false
export def can-append-print [
    command: string
]: nothing -> bool {
    let last_span = get-last-span $command

    (
        $last_span !~ '(;|print|null)$'
        and $last_span !~ '\b(let|mut|def|use|source|overlay|alias)\b'
        and $last_span !~ '(^|;|\n) ?(?<!(let|mut) )\$\S+ = '
    )
}

# Generate indented output for better visual formatting.
@example "generate inline output capture pipeline" {
    'ls' | generate-inline-output-pipeline
} --result "ls | table --width 120 | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\\s*$' \"\\n\""
export def generate-inline-output-pipeline [
    --indent: string = '# => ' # prefix string for each output line
]: string -> string {
    generate-table-statement
    | $"($in) | default '' | into string | lines | each {$'($indent)\($in\)' | str trim --right} | str join \(char nl\) | str replace -r '\\s*$' \"\\n\""
}

# Generate a print statement for capturing command output.
@example "wrap command with print" { 'ls' | generate-print-statement } --result "ls | print; print ''"
export def generate-print-statement []: string -> string {
    $"($in) | print; print ''" # The last `print ''` is for newlines after executed commands
}

# Generate a table statement with optional width specification.
@example "default table width" { 'ls' | generate-table-statement } --result 'ls | table --width 120'
@example "custom table width" { $env.numd.table-width = 10; 'ls' | generate-table-statement } --result 'ls | table --width 10'
export def generate-table-statement []: string -> string {
    $"($in) | table --width ($env.numd?.table-width? | default 120)"
}

# Wrap code in a try-catch block to handle errors gracefully.
@example "wrap command in try-catch" { 'ls' | wrap-in-try-catch } --result 'try {ls} catch {|error| $error}'
export def wrap-in-try-catch [
    --new-instance # execute in a separate Nushell instance to get formatted error messages
]: string -> string {
    if $new_instance {
        quote-for-print
        | (
            $'($nu.current-exe) -c ($in)' +
            " | complete | if ($in.exit_code != 0) {get stderr} else {get stdout}"
        )
    } else {
        $"try {($in)} catch {|error| $error}"
    }
}

# Generate a fenced code block for output with a specific format.
export def generate-separate-block-fence []: string -> string {
    # We use a combination of "\n" and (char nl) here for intermediate script formatting aesthetics
    $"\"```\\n```output-numd\" | print(char nl)(char nl)($in)"
}

# Join a list of strings and generate a print statement for the combined output.
export def join-and-print []: list<string> -> string {
    str join (char nl)
    | quote-for-print
    | $'($in) | print'
}

# Generate marker tags and code block delimiters for tracking output in the intermediate script.
export def generate-block-markers [
    block_number: int # index of the code block in the markdown
    fence: string # the original fence line (e.g., '```nushell')
]: list<string> -> string {
    let input = $in

    code-block-marker $block_number
    | append $fence
    | join-and-print
    | append $input
    | append '"```" | print'
    | append ''
    | str join (char nl)
}

# Parse options from a code fence and return them as a list.
@example "parse fence options with short forms" { '```nu no-run, t' | extract-fence-options } --result ['no-run' 'try']
export def extract-fence-options []: string -> list<string> {
    str replace -r '```nu(shell)?\s*' ''
    | split row ','
    | str trim
    | compact --empty
    | each { convert-short-options $in }
}

# Modify a path by adding a prefix, suffix, extension, or parent directory.
@example "build path with all modifiers" {
    'numd/capture.nu' | build-modified-path --extension '.md' --prefix 'pref_' --suffix '_suf' --parent_dir abc
} --result 'numd/abc/pref_capture_suf.nu.md'
export def build-modified-path [
    --prefix: string
    --suffix: string
    --extension: string
    --parent_dir: string
]: path -> path {
    path parse
    | update stem { $'($prefix)($in)($suffix)' }
    | if $extension != null { update extension { $in + $extension } } else { }
    | if $parent_dir != null {
        update parent { path join $parent_dir | $'(mkdir $in)($in)' }
    } else { }
    | path join
}

# Create a backup of a file by moving it to a subdirectory with a timestamp suffix.
export def create-file-backup [
    file_path: path # path to the file to back up
]: nothing -> nothing {
    $file_path
    | if ($in | path exists) and ($in | path type) == 'file' {
        build-modified-path --parent_dir 'zzz_md_backups' --suffix $'-(generate-timestamp)'
        | mv $file_path $in
    }
}

# TODO: make config an env record

# Load numd configuration from a YAML file or command-line options into the environment.
export def --env load-config [
    path: path # path to a .yaml numd config file
    --prepend_code: string # code to prepend to the intermediate script
    --table_width: int # width for table output formatting
]: nothing -> nothing {
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
        } else { }
        | where value != null
        | if ($in | is-empty) { {} } else {
            # if table_width or prepend code are set via parameters - they will have precedence
            transpose --ignore-titles --as-record --header-row
        }
    )
}

# Generate a timestamp string in the format YYYYMMDD_HHMMSS.
export def generate-timestamp []: nothing -> string {
    date now | format date "%Y%m%d_%H%M%S"
}
