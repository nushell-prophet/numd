use std iter scan

# run nushell code chunks in a markdown file, outputs results back to the `.md` and optionally to terminal
export def run [
    file: path # path to a `.md` file containing nushell code to be executed
    --output-md-path (-o): path # path to a resulting `.md` file; if omitted, updates the original file
    --echo # output resulting markdown to the terminal
    --no-backup # overwrite the existing `.md` file without backup
    --no-save # do not save changes to the `.md` file
    --no-info # do not output stats of changes in `.md` file
    --intermid-script: path # optional a path for an intermediate script (useful for debugging purposes)
    --no-fail-on-error # skip errors (and don't update markdown anyway)
    --prepend-intermid: string # prepend text (code) into the intermid script, useful for customizing nushell output settings
]: [nothing -> nothing, nothing -> string, nothing -> record] {
    let $md_orig = open -r $file
    let $md_orig_table = detect-code-chunks $md_orig

    let $intermid_script_path = $intermid_script
        | default ( $file
            | path-modify --prefix $'numd-temp-(tstamp)' --suffix '.nu' )
        # we don't use temp dir here as code in `md` files might containt relative paths
        # which only work if we'll execute intrmid script from the same folder

    gen-intermid-script $md_orig_table
    | if $prepend_intermid == null {} else {
        $'($prepend_intermid)(char nl)($in)'
    }
    | save -f $intermid_script_path

    let $nu_res_stdout_lines = run-intermid-script $intermid_script_path $no_fail_on_error

    if $intermid_script == null {
        rm $intermid_script_path
    }

    # the part with 2 ifs below needs to rewritten
    if $nu_res_stdout_lines == [] { # if nushell won't output anything
        return {
            filename: $file,
            comment: "Execution of nushell blocks didn't produce any output. The markdown file was not updated"
        }
    }

    let $nu_res_with_block_line_in_orig_md = parse-block-index $nu_res_stdout_lines
    let $md_res_ansi = assemble-markdown $md_orig_table $nu_res_with_block_line_in_orig_md

    if not $no_save {
        let $path = $output_md_path | default $file
        if not ($no_backup or $no_save) { backup-file $path }
        $md_res_ansi | ansi strip | save -f $path
    }

    if $no_info { null } else {
        calc-changes $file $md_orig $md_res_ansi
    }
    | if $echo {
        $"($md_res_ansi)(char nl)($in | table)" # output the changes table below the resulted markdown
    } else {}
}

# remove numd execution outputs from the file
export def clear-outputs [
    file: path # path to a `.md` file containing numd output to be cleared
    --output-md-path (-o): path # path to a resulting `.md` file; if omitted, updates the original file
    --echo # output resulting markdown to the terminal instead of writing to file
    --strip-markdown # keep only nushell script, strip all markdown tags
]: [nothing -> nothing, nothing -> string, nothing -> record] {
    let $md_orig = open -r $file
    let $md_orig_table = detect-code-chunks $md_orig

    let $output_md_path = $output_md_path | default $file

    $md_orig_table
    | where row_type =~ '```nu(shell)?(\s|$)'
    | group-by block_line_in_orig_md
    | items {|k v|
        $v.line
        | if ($in | where $it =~ '^>' | is-empty) {} else {
            where $it =~ '^(>|#|```)'
        }
        | prepend (numd-block $k)
    }
    | flatten
    | parse-block-index $in
    | if $strip_markdown {
        get line
        | each {lines | update 0 {|i| $'(char nl)# ($i)'} | drop | str join (char nl)}
        | str join (char nl)
        | return $in
    } else {
        assemble-markdown $md_orig_table $in
    }
    | if $echo {} else {
        save -f $output_md_path
    }
}

def backup-file [
    $path: path
]: nothing -> nothing {
    if ($path | path exists) and ($path | path type) == 'file' {
        mv $path ($path | path-modify --parent_dir 'md_backups' --suffix $'-(tstamp)')
    }
}


def detect-code-chunks [
    md: string
]: nothing -> table {
    let $file_lines = $md | lines
    let $row_type = $file_lines
        | each {
            str trim
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
}

def escape-quotes []: string -> string {
    str replace --all --regex '([^\\]?)"' '$1\"' # [^\\]? - escape symbols
}

def run-intermid-script [
    intermid_script_path: path
    no_fail_on_error: bool
] {
    do {^$nu.current-exe --env-config $nu.env-path --config $nu.config-path $intermid_script_path}
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

def numd-block [
    index?: int
]: nothing -> string {
    $"###code-block-starting-line-in-original-md-($index)"
}

def gen-highlight-command [ ]: string -> string {
    $"print \(\"($in | escape-quotes)\" | nu-highlight\)(char nl)"
}

def trim-comments-plus []: string -> string {
    str replace -r '^[>\s]+' '' # trim starting `>`
    | str replace -r '[\s\n]+$' '' # trim new lines and spaces from the end of a line
    | str replace -r '\s*#.*$' '' # remove comments from the last line. Might spoil code blocks with the # symbol, used not for commenting
}

# Use a regular expression to check if the last line of the input ends with a semicolon,
# or contains certain keywords ('let', 'def', 'use') followed by potential characters
# This is to determine if appending ' | echo $in' is possible.
def ends-with-definition [
    condition: string
]: nothing -> bool {
    $condition =~ '(;|null|(?>[^\r\n]*\b(let|def|use)\b.*[^\r\n;]*))$'
}

def gen-indented-output []: string -> string {
    $"($in) | table | into string | lines | each {$'//  \($in\)' | str trim} | str join \(char nl\)"
}

def gen-echo-in []: string -> string {
    $'($in) | echo $in'
}

def gen-catch-error-in-current-instance []: string -> string {
    $"try {($in)} catch {|e| $e}"
}

# execute the command outside to obtain a formatted error message if any
def gen-catch-error-outside []: string -> string {
    ($"do {nu -c \"($in | escape-quotes)\"} " +
    "| complete | if \($in.exit_code != 0\) {get stderr} else {get stdout}")
}

def gen-fence-output-numd []: string -> string {
    $"print '```(char nl)```output-numd'(char nl)($in)"
}

def gen-execute-code [
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
                    | gen-echo-in
                }
            }
            | $in + (char nl)
        }


    $highlited_command + $code_execution
}

def gen-intermid-script [
    md_classified: table
]: nothing -> string {
    let $pwd = pwd

    $md_classified
    | where row_type =~ '```nu(shell)?(\s|$)'
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

def parse-block-index [
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

def assemble-markdown [
    $md_classified: table
    $nu_res_with_block_line_in_orig_md: table
]: nothing -> string {
    $md_classified
    | where row_type !~ '(```nu(shell)?(\s|$))|(^```output-numd$)'
    | append $nu_res_with_block_line_in_orig_md
    | sort-by block_line_in_orig_md
    | get line
    | str join (char nl)
    | $in + (char nl)
    | str replace --all --regex "```output-numd[\n\\s]*```\n" '' # empty output-numd blocks
    | str replace --all --regex "\n\n+```\n" "\n```\n" # empty lines before closing code fences
    | str replace --all --regex "\n{3,}" "\n\n" # multiple new lines
}

export def code-block-options [
    --list # show options as a table
] {
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

def expand-short-options [
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

def calc-changes [
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
            $"(ansi red)($change_abs)\(($in)%\)(ansi reset)"
        } else if ($in > 0) {
            $"(ansi blue)+($in)\(($change_abs)%\)(ansi reset)"
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

def parse-options-from-fence []: string -> list {
    str replace -r '```nu(shell)?\s*' ''
    | split row ','
    | str trim
    | where $it != ''
    | compact
    | each {|i| expand-short-options $i}
}

def path-modify [
    --prefix: string
    --suffix: string
    --parent_dir: string
]: path -> path {
    path parse
    | upsert stem {|i| $'($prefix)($i.stem)($suffix)'}
    | if $parent_dir != null {
        upsert parent {|i|
            $i.parent
            | path join $parent_dir
            | $'(mkdir $in)($in)' # The author doesn't like that, but tee in 0.91 somehow consumes and produces list here
        }
    } else {}
    | path join
}

def tstamp []: nothing -> string {
    date now | format date "%Y%m%d_%H%M%S"
}
