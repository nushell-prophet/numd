use std iter scan

# run nushell code chunks in a markdown file, outputs results back to the `.md` and optionally to terminal
export def main [
    file: path # path to a `.md` file containing nushell code to be executed
    --output-md: path # path to a resulting `.md` file; if omitted, updates the original file
    --echo # output resulting markdown to the terminal
    --no-backup (-o) # overwrite the existing `.md` file without backup
    --no-save # do not save changes to the `.md` file
    --no-info # do not output stats of changes in `.md` file
    --intermid-script: path # optional a path for an intermediate script (useful for debugging purposes)
    --stop-on-error # don't update markdown if error occures, otherwise all incompleted blocks will have blank output
] {
    let $md_orig = open -r $file
    let $md_orig_table = detect-code-chunks $md_orig

    let $intermid_script = $intermid_script
        | default ( $nu.temp-path | path join $'nudoc-(tstamp).nu' )

    assemble-script $md_orig_table $intermid_script

    let $nu_res_stdout_lines = run-intermid-script $intermid_script $stop_on_error
    let $nu_res_with_block_index = parse-block-index $nu_res_stdout_lines
    let $md_res = assemble-markdown $md_orig_table $nu_res_with_block_index

    if not $no_save {
        let $path = $output_md | default $file
        if not $no_backup { backup-file $path }
        $md_res | ansi strip | save -f $path
    }

    if $no_info {''} else {
        calc-changes $file $md_orig $md_res
    }
    | if $echo {
        $"($md_res)(char nl)($in | table)"
    } else {}
}

def backup-file [
    $path: path
]: nothing -> nothing {
    if ($path | path exists) {
        mv $path ($path | path-modify --suffix $'-backup-(tstamp)')
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
    intermid_script: path
    stop_on_error: bool
] {
    do {nu -l $intermid_script}
    | complete
    | if $in.exit_code == 0 {
        get stdout
    } else {
        if $stop_on_error {
            error make {msg: $in.stdout}
        } else {
            $'($in.stdout)(char nl)($in.stderr?)'
        }
    }
    | lines
}

def nudoc-block [
    index?: int
]: nothing -> string {
    $"###nudoc-block-($index)"
}

def gen-highlight-command [
    $command: string
]: nothing -> string {
    $"print \(\"($command | escape-quotes)\" | nu-highlight\)(char nl)"
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

def gen-catch-error-in-current-instance [] {
    $"try {($in)} catch {|e| $e}"
}

def gen-catch-error-outside [] {
    # execute the command outside to obtain a clear error message if any
    ($"do {nu -c \"($in | escape-quotes)\"} " +
    "| complete | if \($in.exit_code != 0\) {get stderr} else {get stdout}")
}

def gen-execute-code [
    --fence: string # opening code fence string with options for executing current chunk
    --whole_chunk
]: string -> string {
    let $code = $in
    let $options = $fence | parse-options-from-fence

    let $highlited_command = $code | gen-highlight-command

    let $code_execution = $code
        | trim-comments-plus
        | if 'try' in $options {
            if 'new-instance' in $options {
                gen-catch-error-outside
            } else {
                gen-catch-error-in-current-instance
            }
        } else {}
        | if 'no-output' in $options {} else {
            gen-append-echo-in
            | if $whole_chunk {
                $"print '```(char nl)```nudoc-output'(char nl)($in)"
            } else {}
        }
        | $in + (char nl)

    $highlited_command + $code_execution
}

def assemble-script [
    file_lines_classified: table
    save_path: path
]: nothing -> nothing {
    $file_lines_classified
    | where row_types =~ '```nu(shell)?(\s|$)'
    | group-by block_index
    | items {|k v|
        $v.lines
        | if ($in | where $it =~ '^\s*>' | is-empty) {  # finding blocks with no `>` symbol, to execute them entirely
            let $chunk = ( skip | str join (char nl) ) # skip the language identifier ```nushell line

            gen-execute-code --whole_chunk $chunk $v.row_types.0
        } else {
            each {|line|
                if $line =~ '^\s*>' {
                    gen-execute-code $line $v.row_types.0
                } else if $line =~ '^\s*#' {
                    gen-highlight-command $line
                }
            }
        }
        | prepend $"print \"($v.row_types.0)\""
        | prepend $"print \"(nudoc-block $k)\""
    }
    | prepend ( '# this script was generated automatically using nudoc
        # https://github.com/nushell-prophet/nudoc' )
    | flatten
    | str join (char nl)
    | save -f $save_path
}

def parse-block-index [
    $nu_res_stdout_lines: list
]: nothing -> table {
    if $nu_res_stdout_lines == [] {
        return []
    }

    let $block_index = $nu_res_stdout_lines
        | each {
            if $in =~ (nudoc-block) {
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
    $file_lines_classified: table
    $nu_res_with_block_index: table
]: nothing -> string {
    $file_lines_classified
    | where row_types !~ '(```nu(shell|doc-output)?(\s|$))'
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

def expand-short-options [
    $option
] {
    # types of handlders
    let $dict = {
        O: 'no-output' # don't try printing result
        t: 'try' # try handling errors
        n: 'new-instance' # execute outside
        # - todo output results as an image using nu_plugin_image - image(i)
        # - todo execute outside with all previous code included
    }

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
] {
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
]: path -> path {
    path parse
    | upsert stem {|i| $'($prefix)($i.stem)($suffix)'}
    | path join
}

def tstamp []: nothing -> string {
    date now | format date "%Y%m%d_%H%M%S"
}
