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
    | execute-blocks --eval $eval --no-fail-on-error=$no_fail_on_error --print-block-results=$print_block_results --save-intermed-script $intermediate_script_path --use-host-config=$use_host_config --file $file

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

# Execute code blocks and return updated blocks table.
# --file is required for `image`-tagged blocks so paths can be computed relative
# to the markdown file's parent directory (keeps generated docs portable).
export def execute-blocks [
    --eval: string # Nushell code to prepend to the script
    --no-fail-on-error # skip errors
    --print-block-results # print blocks as they execute
    --save-intermed-script: path # path for intermediate script
    --use-host-config # load host's env, config, and plugin files
    --file: path # source markdown file path (required for image-tagged blocks)
]: table -> table {
    let original = $in

    load-config $eval

    # Precheck `to png` plugin availability and ensure the media dir exists,
    # but ONLY if the doc actually uses the `image` fence option. Non-image
    # docs must not grow a `media/` folder per spec "Rendering pipeline
    # changes" step 5.
    let image_plugin_path = check-image-plugin $original
    if $image_plugin_path != null and $file != null {
        # Resolve the same directory that decorate-original-code-blocks will use.
        let parent = $file | path dirname | path expand
        let rel_dir = $env.numd?.image-dir? | default 'media'
        let abs_dir = if ($rel_dir | str starts-with '/') { $rel_dir } else { $parent | path join $rel_dir }
        mkdir $abs_dir
    }

    decorate-original-code-blocks $original --file $file
    | generate-intermediate-script
    | save -f $save_intermed_script

    let execution_output = execute-intermediate-script $save_intermed_script $no_fail_on_error $print_block_results $use_host_config --image-plugin-path $image_plugin_path

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
    | strip-numd-image-refs
    | parse-markdown-to-blocks
}

# Remove numd-generated `![](...)` image reference lines from raw markdown.
# Why at the string level: image refs from a previous run live in text blocks
# that follow image-tagged code blocks. On re-run, `execute-blocks` keeps
# text blocks as-is and the new image refs are appended to code-block output,
# which would duplicate them. Stripping at parse time prevents compounding.
# The pattern `\.block-\d+-\d+\.png` is distinctive enough that hand-written
# image links are extremely unlikely to match it.
export def strip-numd-image-refs []: string -> string {
    str replace --all --regex '(?m)^!\[\]\([^)]*\.block-\d+-\d+\.png\)\r?\n?' ''
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

# Apply output formatting based on fence options (image, separate-block, or inline `# =>`).
# When `image` is in $fence_options and --image-abs-path is provided, the group is rasterized
# via the `to png` plugin. `image` wins over `separate-block` per the spec interaction matrix.
def format-command-output [
    fence_options: list<string>
    --image-abs-path: string # absolute path for `to png` output (only used when `image` is active)
]: string -> string {
    if 'no-output' in $fence_options { return $in } else { }
    | if 'image' in $fence_options and $image_abs_path != null {
        # Why: `image` wins over `separate-block` per spec interaction matrix; rasterize
        # and do NOT append a terminal `print` — the side-effect pipeline already captures
        # the output. The markdown `![]()` reference is emitted by `generate-block-markers`
        # after the closing fence, not inline.
        generate-image-output-pipeline $image_abs_path
    } else {
        if 'separate-block' in $fence_options { generate-separate-block-fence } else { }
        | if (can-append-print $in) {
            generate-inline-output-pipeline
            | generate-print-statement
        } else { }
    }
}

# Generate a pipeline that rasterizes a command's output to a PNG file via the `to png` plugin.
# The captured output is fully expanded with `table -e` before rasterization so nested structures
# render exactly as the user would see them in a terminal. `| ignore` drops the path string
# that `to png` returns so nothing contaminates the captured stdout for this group — the
# markdown `![](...)` reference is emitted separately by `generate-block-markers`.
#
# Why `do { $env.config.use_ansi_coloring = true; ... }`: numd launches the child nushell
# without a TTY, so `table -e` emits plain text by default and `to png` produces a monochrome
# image. Enabling ansi coloring inside a `do { ... }` closure scopes the toggle to the image
# pipeline only — verified empirically that the `# =>` inline and `separate-block` paths stay
# ANSI-free, so no defensive `ansi strip` is needed elsewhere. Mutation (`... = true`) rather
# than replacement preserves the rest of `$env.config`. `with-env {FORCE_COLOR: '1'}` does not
# work here because nu reads that env var at process startup, not per-pipeline.
@example "generate image pipeline for a path" {
    'ls' | generate-image-output-pipeline '/tmp/out.png'
} --result "do { $env.config.use_ansi_coloring = true; ls | table -e --width ($env.numd?.table-width? | default 120) | to png '/tmp/out.png' | ignore }"
export def generate-image-output-pipeline [
    abs_path: string # absolute path where the PNG will be written
]: string -> string {
    $"do { $env.config.use_ansi_coloring = true; ($in) | table -e --width \(\$env.numd?.table-width? | default 120\) | to png '($abs_path)' | ignore }"
}

# Generate code for execution in the intermediate script within a given code fence.
export def generate-block-execution [
    fence_options: list<string>
    --image-abs-path: string # absolute path for `to png` output (only used when `image` is active)
]: string -> string {
    let code_content = $in

    let highlighted_command = $code_content | generate-highlight-print

    let code_execution = $code_content
    | trim-trailing-comments
    | if 'try' in $fence_options {
        wrap-in-try-catch --new-instance=('new-instance' in $fence_options)
    } else { }
    | format-command-output $fence_options --image-abs-path $image_abs_path
    | $in + (char nl)
    # Always print a blank line after each command group to preserve visual separation
    | $in + "print ''"

    $highlighted_command + $code_execution
}

# Generate additional service code necessary for execution and capturing results, while preserving the original code.
# When --file is provided, image-tagged blocks have their `to png` absolute paths and
# `![](rel)` markdown references computed relative to the markdown file's parent directory,
# so the generated document stays portable regardless of the caller's cwd.
export def decorate-original-code-blocks [
    md_classified: table<block_index: int, row_type: string, line: list<string>, action: string> # classified markdown table from parse-markdown-to-blocks
    --file: path # source markdown file path (required for image-tagged blocks to compute paths)
]: nothing -> table<block_index: int, row_type: string, line: list<string>, action: string, code: string> {
    # Resolve image directory info once per invocation. $env.numd.image-dir overrides
    # the default 'media'. The absolute dir is resolved against the markdown file's
    # parent so that `numd run docs/guide.md` writes to `docs/media/...`, not to cwd.
    let image_info = if $file != null {
        let parent = $file | path dirname | path expand
        let doc_stem = $file | path parse | get stem
        let rel_dir = $env.numd?.image-dir? | default 'media'
        # Absolute override is respected as-is; relative paths resolve against the
        # markdown file's parent directory (not cwd) so the reference in the rendered
        # markdown stays portable.
        let abs_dir = if ($rel_dir | str starts-with '/') {
            $rel_dir
        } else {
            $parent | path join $rel_dir
        }
        {abs_dir: $abs_dir, rel_dir: $rel_dir, doc_stem: $doc_stem}
    } else {
        null
    }

    $md_classified
    | where action == 'execute'
    | insert code {|i|
        let fence_options = $i.row_type | extract-fence-options
        # Per spec interaction matrix: `no-output` wins over `image`. No PNG is
        # written and no `![](...)` reference is emitted.
        let image_active = ('image' in $fence_options) and ($image_info != null) and ('no-output' not-in $fence_options)

        let image_abs_prefix = if $image_active {
            $image_info.abs_dir | path join $'($image_info.doc_stem).block-($i.block_index)'
        } else {
            null
        }
        let image_rel_prefix = if $image_active {
            $image_info.rel_dir | path join $'($image_info.doc_stem).block-($i.block_index)'
        } else {
            null
        }

        # Compute the list of rel paths for each executable group in this block.
        # group_index is 0-based over ALL groups (including empty / comment-only) per spec.
        let image_refs = if $image_active {
            $i.line
            | skip | drop
            | where $it !~ '^# =>'
            | str join (char nl)
            | split-by-blank-lines
            | enumerate
            | where {|row|
                let trimmed = $row.item | str trim
                (not ($trimmed | is-empty)) and (not ($trimmed | lines | all { $in =~ '^#' }))
            }
            | each {|row| $"($image_rel_prefix)-($row.index).png" }
        } else {
            []
        }

        $i.line
        | process-code-block-content $fence_options --image-abs-prefix $image_abs_prefix
        | generate-block-markers $i.block_index ($i.row_type | str replace 'run-once' 'no-run') --image-refs $image_refs
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
# When the `image` fence option is active and --image-abs-prefix is set, each executable group
# gets its own `to png` target path of the form `<image-abs-prefix>-<group_index>.png`.
# Why: `group_index` is 0-based over ALL groups (not just executable ones) so numbering stays
# stable when a user later inserts a comment-only group in the middle.
export def process-code-block-content [
    fence_options: list<string> # options from the code fence (e.g., 'no-output', 'try')
    --image-abs-prefix: string # absolute path prefix for image output (block-level, e.g. '/abs/media/README.block-3')
]: list<string> -> list<string> {
    skip | drop # skip code fences
    | where $it !~ '^# =>' # strip existing `# =>` output lines (keep plain `#` comments)
    | str join (char nl)
    | split-by-blank-lines
    | enumerate
    | each {|row|
        let group = $row.item
        let group_index = $row.index
        let trimmed = $group | str trim

        if ($trimmed | is-empty) {
            ''
        } else if ($trimmed | lines | all { $in =~ '^#' }) {
            $group | generate-highlight-print
        } else {
            let abs_path = if ('image' in $fence_options) and ($image_abs_prefix != null) {
                $"($image_abs_prefix)-($group_index).png"
            } else {
                null
            }
            $group | generate-block-execution $fence_options --image-abs-path $abs_path
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
    [i image "render block output as a PNG image via the `to png` plugin"]
    ['' run-once "execute code block once, then set to no-run"]
]

# List fence options for execution and output customization.
export def list-fence-options []: nothing -> table {
    $fence_options | select long short description
}

# Expand short options for code block execution to their long forms.
@example "expand short option to long form" {
    convert-short-options 'O'
} --result "no-output"
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
} --result "\"abcd\\\"dfdaf\\\" \\\"\""
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
# --image-plugin-path, when set, is passed as `--plugins <path>` to the child nu so
# the `to png` plugin is loaded even under the default `-n` (no-config) mode. Why
# `--plugins` and not `--plugin-config`: `-n` suppresses the registry file regardless
# of `--plugin-config`, so explicit executable injection is the only way to keep the
# reproducibility guarantees of `-n` while still making `to png` available.
export def execute-intermediate-script [
    intermed_script_path: path # path to the generated intermediate script
    no_fail_on_error: bool # if true, return empty string on error instead of failing
    print_block_results: bool # print blocks one by one as they execute
    use_host_config: bool # if true, load host's env, config, and plugin files
    --image-plugin-path: path # absolute path to the `to png` plugin executable
]: nothing -> string {
    let base_args = if $use_host_config {
        [
            [--env-config $nu.env-path]
            [--config $nu.config-path]
            [--plugin-config $nu.plugin-path]
        ]
        | where {|i| $i.1 | path exists }
        | flatten
    } else {
        [-n]
    }

    # Why `--plugins=<path>` rather than two separate args: `--plugins` is a `path...`
    # multi-positional, so `nu ... --plugins /p /script.nu` treats the script as another
    # plugin path and errors with "valid Nushell plugin filenames must start with
    # `nu_plugin_`". The `=` form binds exactly one value and lets the script path
    # remain a normal positional.
    let args = if $image_plugin_path != null {
        $base_args | append $"--plugins=($image_plugin_path)"
    } else {
        $base_args
    }

    ^$nu.current-exe ...$args $intermed_script_path
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
} --result "\"ls\" | nu-highlight | print

"
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
@example "pipeline ending with command" { get-last-span 'let a = 1..10; $a | length' } --result "length"
@example "pipeline ending with assignment" { get-last-span 'let a = 1..10; let b = $a | length' } --result "let b = $a | length"
@example "statement ending with semicolon" { get-last-span 'let a = 1..10; ($a | length);' } --result "let a = 1..10; ($a | length);"
@example "expression in parentheses" { get-last-span 'let a = 1..10; ($a | length)' } --result "($a | length)"
@example "single assignment" { get-last-span 'let a = 1..10' } --result "let a = 1..10"
@example "string literal" { get-last-span '"abc"' } --result "\"abc\""
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
} --result "ls | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each { $'# => ($in)' | str trim --right } | str join (char nl) | str replace -r '\\s*$' (char nl)"
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
@example "default table width" { 'ls' | generate-table-statement } --result "ls | table --width ($env.numd?.table-width? | default 120)"
export def generate-table-statement []: string -> string {
    pipe-to { table --width ($env.numd?.table-width? | default 120) }
}

# Wrap code in a try-catch block to handle errors gracefully.
@example "wrap command in try-catch" { 'ls' | wrap-in-try-catch } --result "try {ls} catch {|error| $error}"
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
# When --image-refs is non-empty, markdown image reference lines are appended AFTER the
# closing ``` fence so the rendered output is valid markdown — a `![](...)` line inside a
# code fence would be part of the code, not a real image link.
export def generate-block-markers [
    block_number: int # index of the code block in the markdown
    fence: string # the original fence line (e.g., '```nushell')
    --image-refs: list<string> = [] # relative paths for `![](...)` refs appended after the closing fence
]: list<string> -> string {
    let input = $in

    let image_ref_prints = if ($image_refs | is-empty) {
        []
    } else {
        # Blank line between the closing ``` and the first image ref keeps the rendered
        # markdown readable and prevents the ref from being absorbed into the fenced block.
        ["print ''"]
        | append ($image_refs | each {|r| $"print \"![]\(($r)\)\"" })
    }

    code-block-marker $block_number
    | append $fence
    | join-and-print
    | append $input
    | append '"```" | print'
    | append $image_ref_prints
    | append ''
    | str join (char nl)
}

# Parse options from a code fence and return them as a list.
@example "parse fence options with short forms" { '```nu no-run, t' | extract-fence-options } --result [no-run try]
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
} --result "numd/abc/pref_capture_suf.nu.md"
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

# Discover the `to png` plugin executable path via `plugin list`.
# Uses `plugin list` rather than `scope commands` because we need the executable
# PATH to inject into the child `-n` nu process via `--plugins`, not just a
# boolean "is the command registered". Returns null if the plugin isn't found.
export def find-image-plugin-path []: nothing -> any {
    plugin list
    | where {|p| 'to png' in ($p.commands.name | default []) }
    | get filename.0?
}

# Check that `to png` is available when any block in the parsed table uses
# the `image` fence option AND is actually going to produce output (not
# `no-output`). Returns the plugin path on success, null if no image-producing
# blocks are present, and errors fast with an install hint if image blocks
# exist but the plugin isn't registered. Why fail-fast at `numd run` entry:
# the child `-n` process can't introspect plugins cheaply, and running the
# whole intermediate script only to crash on the first `to png` call is a
# slow feedback loop.
export def check-image-plugin [
    blocks_table: table # output of parse-markdown-to-blocks
]: nothing -> any {
    let has_image_blocks = $blocks_table
    | where action == 'execute'
    | any {|b|
        let opts = $b.row_type | extract-fence-options
        ('image' in $opts) and ('no-output' not-in $opts)
    }

    if not $has_image_blocks { return null }

    let plugin_path = find-image-plugin-path
    if $plugin_path == null {
        error make --unspanned {
            msg: $"numd: the `image` fence option requires the `to png` plugin.
Install it (e.g. `cargo install nu_plugin_image`) and register it with:
    plugin add <path-to-nu_plugin_image>
    plugin use image"
        }
    }
    $plugin_path
}

# Generate a timestamp string in the format YYYYMMDD_HHMMSS.
export def generate-timestamp []: nothing -> string {
    date now | format date "%Y%m%d_%H%M%S"
}
