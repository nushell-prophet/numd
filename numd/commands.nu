use std/iter scan

# Run Nushell code blocks in a markdown file, output results back to the `.md`, and optionally to terminal
@example "update readme" {
    numd run README.md
}
export def run [
    file: path # path to a `.md` file containing Nushell code to be executed
    --echo # output resulting markdown to stdout instead of saving to file
    --eval: string # Nushell code to prepend to the script (use `open -r config.nu` for file-based config)
    --ignore-git-check # skip the check for uncommitted changes before overwriting
    --no-fail-on-error # skip errors (markdown is never saved on error)
    --no-stats # do not output stats of changes (is activated via --echo by default)
    --print-block-results # print blocks one by one as they are executed, useful for long running scripts
    --save-intermed-script: path # optional path for keeping intermediate script (useful for debugging purposes). If not set, the temporary intermediate script will be deleted.
    --use-host-config # load host's env, config, and plugin files (default: run with nu -n for reproducibility)
]: [nothing -> string nothing -> nothing nothing -> record] {
    let original_md = open -r $file

    let intermediate_script_path = $save_intermed_script
    | default ($file | build-modified-path --suffix $'-numd-temp-(generate-timestamp)' --extension '.nu')

    let result = parse-file $file
    | execute-blocks --eval $eval --no-fail-on-error=$no_fail_on_error --print-block-results=$print_block_results --save-intermed-script $intermediate_script_path --use-host-config=$use_host_config

    # if $save_intermed_script param wasn't set - remove the temporary intermediate script
    if $save_intermed_script == null { rm $intermediate_script_path }

    # Check for empty output (no code blocks executed)
    if ($result | where action == 'execute' | is-empty) {
        return {
            filename: $file
            comment: "the script didn't produce any output"
        }
    }

    let updated_md = $result | to-markdown

    if $echo {
        $updated_md
    } else {
        if not $ignore_git_check { check-git-clean $file }
        $updated_md | ansi strip | save -f $file

        if not $no_stats {
            compute-change-stats $file $original_md $updated_md
        }
    }
}

# Remove numd execution outputs from the file
# Note: No git check here - clearing outputs is a reversible operation (just re-run numd)
# and users typically clear outputs intentionally before committing clean source
export def clear-outputs [
    file: path # path to a `.md` file containing numd output to be cleared
    --echo # output resulting markdown to stdout instead of writing to file
    --strip-markdown # keep only Nushell script, strip all markdown tags
]: [nothing -> string nothing -> nothing] {
    parse-file $file
    | strip-outputs
    | if $strip_markdown {
        to-numd-script
    } else {
        to-markdown
    }
    | if $echo { } else {
        $in | save -f $file
    }
}

# Extract pure Nushell script from blocks table (strip markdown fences)
export def to-numd-script []: table -> string {
    where action == 'execute'
    | each {
        $in.line
        | update 0 { $'(char nl)    # ($in)' } # keep infostring as comment
        | drop # remove closing fence
        | str join (char nl)
        | str replace -r '\s*$' (char nl)
    }
    | str join (char nl)
}

# Execute code blocks and return updated blocks table
export def execute-blocks [
    --eval: string # Nushell code to prepend to the script
    --no-fail-on-error # skip errors
    --print-block-results # print blocks as they execute
    --save-intermed-script: path # path for intermediate script
    --use-host-config # load host's env, config, and plugin files
]: table -> table {
    let original = $in

    load-config $eval

    decorate-original-code-blocks $original
    | generate-intermediate-script
    | save -f $save_intermed_script

    let execution_output = execute-intermediate-script $save_intermed_script $no_fail_on_error $print_block_results $use_host_config

    if $execution_output == '' {
        return $original
    }

    let results = $execution_output
    | str replace -ar "\n{2,}```\n" "\n```\n"
    | lines
    | extract-block-index

    # Update original table with execution results
    let result_indices = $results | get block_index

    $original
    | each {|block|
        if $block.block_index in $result_indices {
            let result = $results | where block_index == $block.block_index | first
            $block | update line { $result.line | lines }
        } else {
            $block
        }
    }
}

# Parse a markdown file into a blocks table
export def parse-file [
    file: path # path to a markdown file
]: nothing -> table<block_index: int, row_type: string, line: list<string>, action: string> {
    open -r $file
    | if $nu.os-info.family == windows {
        str replace --all (char crlf) "\n"
    } else { }
    | convert-output-fences
    | parse-markdown-to-blocks
}

# Strip numd output lines (# =>) from code blocks
export def strip-outputs []: table -> table {
    update line {|block|
        if $block.action == 'execute' {
            $block.line | where $it !~ '^# => ?'
        } else {
            $block.line
        }
    }
}

# Render blocks table back to markdown string
export def to-markdown []: table -> string {
    where action != 'delete'
    | each { $in.line | str join (char nl) }
    | str join (char nl)
    | clean-markdown
    | convert-output-fences --restore
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
        prepend $"($env.numd.prepend-code)\n"
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

# Split code block content by blank lines into command groups and generate execution code for each.
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
            $"($change_value) \(($in)%\)"
        } else if ($in > 0) {
            $"+($change_value) \(($in)%\)"
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

# Fence options data: short form, long form, description
const fence_options = [
    [short long description];

    [O no-output "execute code without outputting results"]
    [N no-run "do not execute code in block"]
    [t try "execute block inside `try {}` for error handling"]
    [n new-instance "execute block in new Nushell instance (useful with `try` block)"]
    [s separate-block "output results in a separate code block instead of inline `# =>`"]
]

# List fence options for execution and output customization.
export def list-fence-options []: nothing -> table {
    $fence_options | select long short description
}

# Expand short options for code block execution to their long forms.
@example "expand short option to long form" {
    convert-short-options 'O'
} --result 'no-output'
export def convert-short-options [
    option: string
]: nothing -> string {
    let options_dict = $fence_options | select short long | transpose -r -d
    let result = $options_dict | get -o $option | default $option

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

# Append a pipeline to a command string by extracting the closure body.
export def pipe-to [closure: closure]: string -> string {
    let $input = $in

    view source $closure
    | str substring 1..(-2)
    | str replace -r '^\s+' ''
    | str replace -r '\s+$' ''
    | $input + " | " + $in
}

# Run the intermediate script and return its output as a string.
export def execute-intermediate-script [
    intermed_script_path: path # path to the generated intermediate script
    no_fail_on_error: bool # if true, return empty string on error instead of failing
    print_block_results: bool # print blocks one by one as they execute
    use_host_config: bool # if true, load host's env, config, and plugin files
]: nothing -> string {
    let args = if $use_host_config {
        []
        | if ($nu.env-path | path exists) { append [--env-config $nu.env-path] } else { }
        | if ($nu.config-path | path exists) { append [--config $nu.config-path] } else { }
        | if ($nu.plugin-path | path exists) { append [--plugin-config $nu.plugin-path] } else { }
    } else {
        [-n]
    }

    (^$nu.current-exe ...$args $intermed_script_path)
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
    | pipe-to { nu-highlight | print }
    | $in + "\n\n"
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
    let trimmed = $command | str trim
    let spans = ast $trimmed --json
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

    $trimmed
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

# Generate a pipeline that captures command output with `# =>` prefix for inline display.
@example "generate inline output capture pipeline" {
    'ls' | generate-inline-output-pipeline
} --result "ls | table --width 120 | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\\s*$' (char nl)"
export def generate-inline-output-pipeline []: string -> string {
    generate-table-statement
    | pipe-to {
        default '' | into string | lines | each { $'# => ($in)' | str trim --right } | str join (char nl) | str replace -r '\s*$' (char nl)
    }
}

# Generate a print statement for capturing command output.
@example "wrap command with print" { 'ls' | generate-print-statement } --result "ls | print; print ''"
export def generate-print-statement []: string -> string {
    pipe-to { print; print '' } # The last `print ''` is for newlines after executed commands
}

# Generate a table statement with width evaluated at runtime from $env.numd.table-width.
@example "default table width" { 'ls' | generate-table-statement } --result 'ls | table --width ($env.numd?.table-width? | default 120)'
export def generate-table-statement []: string -> string {
    pipe-to { table --width ($env.numd?.table-width? | default 120) }
}

# Wrap code in a try-catch block to handle errors gracefully.
@example "wrap command in try-catch" { 'ls' | wrap-in-try-catch } --result 'try {ls} catch {|error| $error}'
export def wrap-in-try-catch [
    --new-instance # execute in a separate Nushell instance to get formatted error messages
]: string -> string {
    if $new_instance {
        quote-for-print
        | $'($nu.current-exe) -c ($in)'
        | pipe-to { complete | if ($in.exit_code != 0) { get stderr } else { get stdout } }
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
    | pipe-to { print }
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
        update parent { path join $parent_dir | tee { mkdir $in } }
    } else { }
    | path join
}

# Check if file is safely tracked in git before overwriting.
# Errors if file has uncommitted changes. Use --ignore-git-check to skip.
export def check-git-clean [
    file_path: path # path to the file to check
]: nothing -> nothing {
    let file = $file_path | path expand

    # Check if we're in a git repo
    let in_git_repo = (do { git rev-parse --git-dir } | complete).exit_code == 0
    if not $in_git_repo { return }

    # Check if file is tracked by git (untracked files are ok to overwrite)
    let is_tracked = (do { git ls-files --error-unmatch $file } | complete).exit_code == 0
    if not $is_tracked { return }

    # Check if file has uncommitted changes
    let has_changes = (git diff --name-only $file | str trim) != ''
    let is_staged = (git diff --staged --name-only $file | str trim) != ''
    if $has_changes or $is_staged {
        error make --unspanned {
            msg: $"($file_path) has uncommitted changes. Commit or stash changes first, or use --ignore-git-check to override."
        }
    }
}

# Load numd configuration from eval code into the environment.
# The eval code is Nushell code that gets prepended to the intermediate script.
export def --env load-config [
    eval_code?: string # Nushell code to prepend to the script
]: nothing -> nothing {
    let code = $eval_code | default '' | str trim

    if $code == '' { return }

    # Preserve existing $env.numd fields, only update prepend-code
    let base = $env.numd? | default {}
    $env.numd = $base | merge {prepend-code: $code}
}

# Generate a timestamp string in the format YYYYMMDD_HHMMSS.
export def generate-timestamp []: nothing -> string {
    date now | format date "%Y%m%d_%H%M%S"
}
