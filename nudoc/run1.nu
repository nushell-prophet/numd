use std iter scan

# run nushell code chunks in a markdown file, outputs results back to the `.md` and optionally to terminal
export def run [
    file: path # path to a `.md` file containing nushell code to be executed
    --output-md-path (-o): path # path to a resulting `.md` file; if omitted, updates the original file
    --echo # output resulting markdown to the terminal
    --no-backup # overwrite the existing `.md` file without backup
    --no-save # do not save changes to the `.md` file
    --no-info # do not output stats of changes in `.md` file
    --intermid-script-path: path # optional a path for an intermediate script (useful for debugging purposes)
    --no-fail-on-error # skip errors (and don't update markdown anyway)
] {
    let $md_orig = open -r $file
    let $md_orig_table = detect-code-chunks $md_orig

    let $intermid_script_path = $intermid_script_path
        | default ( $nu.temp-path | path join $'nudoc-(tstamp).nu' )

    gen-intermid-script $md_orig_table $intermid_script_path

    let $nu_res_stdout_lines = run-intermid-script $intermid_script_path $no_fail_on_error

    # the part with 2 ifs below needs to rewritten
    if $nu_res_stdout_lines == [] { # if nushell won't output anything
        return {
            filename: $file,
            comment: "Execution of nushell blocks didn't produce any output. The markdown file was not updated"
        }
    }

    let $nu_res_with_block_index = parse-block-index $nu_res_stdout_lines
    let $md_res_ansi = assemble-markdown $md_orig_table $nu_res_with_block_index

    if not $no_save {
        let $path = $output_md_path | default $file
        if not ($no_backup or $no_save) { backup-file $path }
        $md_res_ansi | ansi strip | save -f $path
    }

    if $no_info { null } else {
        calc-changes $file $md_orig ($md_res_ansi | ansi strip)
    }
    | if $echo {
        $"($md_res_ansi)(char nl)($in | table)" # output changes table below the resulted markdown
    } else {}
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
    let $row_types = $file_lines
        | each {
            str trim
            | if $in =~ '^```' {} else {''}
        }
        | scan --noinit '' {|prev curr|
            if $curr == '' and $prev != '```' {$prev} else {$curr}
        }

    let $block_index = $row_types
        | window --remainder 2
        | scan 0 {|prev curr|
            if ($curr.0? == $curr.1?) {$prev} else {$prev + 1}
        }

    # We wrap lists into columns here because previously we needed to use the `window` command
    $file_lines | wrap lines
    | merge ($row_types | wrap row_types)
    | merge ($block_index | wrap block_index)
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

def nudoc-block [
    index?: int
]: nothing -> string {
    $"###nudoc-block-($index)"
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
def gen-append-echo-in []: string -> string {
    # check if we can add echo $in to the last line
    if ($in =~ '(;|null|(?>[^\r\n]*\b(let|def|use)\b.*[^\r\n;]*))$') {} else {
        $in + ' | echo $in'
    }
}

def gen-catch-error-in-current-instance []: string -> string {
    $"try {($in)} catch {|e| $e}"
}

# execute the command outside to obtain a formatted error message if any
def gen-catch-error-outside []: string -> string {
    ($"do {nu -c \"($in | escape-quotes)\"} " +
    "| complete | if \($in.exit_code != 0\) {get stderr} else {get stdout}")
}

def gen-fence-nudoc-output []: string -> string {
    $"print '```(char nl)```nudoc-output'(char nl)($in)"
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
                    gen-fence-nudoc-output
                } else {}
                | gen-append-echo-in
            }
            | $in + (char nl)
        }


    $highlited_command + $code_execution
}

def gen-intermid-script [
    md_classified: table
    save_path: path
]: nothing -> nothing {
    $md_classified
    | where row_types =~ '```nu(shell)?(\s|$)'
    | group-by block_index
    | items {|k v|
        $v.lines
        | if ($in | where $it =~ '^>' | is-empty) {  # finding chunks with no `>` symbol, to execute them entirely
            skip # skip the opening code fence ```nushell
            | str join (char nl)
            | gen-execute-code --whole_chunk --fence $v.row_types.0
        } else {
            each { # here we define what to do with each line of the current chunk one by one
                if $in =~ '^>' { # if it starts with `>` we execute it
                    gen-execute-code --fence $v.row_types.0
                } else if $in =~ '^\s*#' {
                    gen-highlight-command
                }
            }
        }
        | prepend $"print \"($v.row_types.0)\""
        | prepend $"print \"(nudoc-block $k)\""
    }
    | prepend ( '# this script was generated automatically using nudoc' +
        "\n# https://github.com/nushell-prophet/nudoc" )
    | flatten
    | str join (char nl)
    | save -f $save_path
}

def parse-block-index [
    $nu_res_stdout_lines: list
]: nothing -> table {


    let $block_index = $nu_res_stdout_lines
        | each {
            if $in =~ $"^(nudoc-block)\\d+$" {
                split row '-' | last | into int
            } else {
                -1
            }
        }
        | scan --noinit 0 {|prev curr|
            if $curr == -1 {$prev} else {$curr}
        }
        | wrap block_index

    $nu_res_stdout_lines
    | wrap 'nu_out'
    | merge $block_index
    | group-by block_index --to-table
    | upsert items {
        |i| $i.items.nu_out
        | skip
        | str join (char nl)
        | $in + (char nl) + '```'
    }
    | rename block_index lines
    | into int block_index
}

def assemble-markdown [
    $md_classified: table
    $nu_res_with_block_index: table
]: nothing -> string {
    $md_classified
    | where row_types !~ '(```nu(shell)?(\s|$))|(^```nudoc-output$)'
    | append $nu_res_with_block_index
    | sort-by block_index
    | get lines
    | str join (char nl)
    | $in + (char nl)
    | str replace --all --regex "```\n(```\n)+" "```\n" # multiple code-fences
    | str replace --all --regex "```nudoc-output(\\s|\n)*```\n" '' # empty nudoc-output blocks
    | str replace --all --regex "\n\n+```\n" "\n```\n" # empty lines before closing code fences
    | str replace --all --regex "\n\n+\n" "\n\n" # multiple new lines
}

export def code-block-options [
    --list # show options as a table
] {
    [
        ["long" "short" "description"];

        ["no-output" "O" "don't try printing result"]
        ["try" "t" "try handling errors"]
        ["new-instance" "n" "execute outside"]
        ["no-run" "N" "dont execute the code"]
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
    $new_file | str stats | transpose metric new
    | merge ($orig_file | str stats | transpose metric old)
    | insert change {|i|
        (($i.new - $i.old) / $i.old) * 100
        | math round --precision 1
        | if $in < 0 {
            $"(ansi red)($in)%(ansi reset)"
        } else if ($in > 0) {
            $"(ansi blue)+($in)%(ansi reset)"
        } else {'0%'}
        | $"($in) from ($i.old)"
    }
    | select metric change
    | transpose --as-record --ignore-titles --header-row
    | insert filename ($filename | path basename)
    | insert levenstein ($orig_file | str distance $new_file)
    | select filename lines words chars levenstein
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
