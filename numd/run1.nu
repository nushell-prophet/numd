use nu-utils numd-internals *
export use nu-utils numd-internals code-block-options

# run nushell code chunks in a markdown file, output results back to the `.md` and optionally to terminal
export def run [
    file: path # path to a `.md` file containing nushell code to be executed
    --output-md-path (-o): path # path to a resulting `.md` file; if omitted, updates the original file
    --echo # output resulting markdown to the terminal
    --no-backup # overwrite the existing `.md` file without backup
    --no-save # do not save changes to the `.md` file
    --no-info # do not output stats of changes in `.md` file
    --intermid-script: path # optional a path for an intermediate script (useful for debugging purposes)
    --no-fail-on-error # skip errors (and don't update markdown in case of errors anyway)
    --prepend-intermid: string # prepend text (code) into the intermid script, useful for customizing nushell output settings
    --diff # use diff for printing changes
]: [nothing -> nothing, nothing -> string, nothing -> record] {
    let $md_orig = open -r $file
    let $md_orig_table = detect-code-chunks $md_orig

    let $intermid_script_path = $intermid_script
        | default ( $file | path-modify --prefix $'numd-temp-(tstamp)' --suffix '.nu' )
        # we don't use temp dir here as code in `md` files might containt relative paths
        # which only work if we'll execute intrmid script from the same folder

    gen-intermid-script $md_orig_table
    | if $prepend_intermid == null {} else {
        $'($prepend_intermid)(char nl)($in)'
    }
    | save -f $intermid_script_path

    let $nu_res_stdout_lines = run-intermid-script $intermid_script_path $no_fail_on_error

    # if $intermid_script param wasn't set - remove the temporary intermid script
    if $intermid_script == null {
        rm $intermid_script_path
    }

    if $nu_res_stdout_lines == [] { # if nushell won't output anything
        return {
            filename: $file,
            comment: "Execution of nushell blocks didn't produce any output. The markdown file was not updated"
        }
    }

    let $nu_res_with_block_line_in_orig_md = parse-block-index $nu_res_stdout_lines
    let $md_res_ansi = assemble-markdown $md_orig_table $nu_res_with_block_line_in_orig_md
        | prettify-markdown

    if not $no_save {
        let $path = $output_md_path | default $file
        if not ($no_backup or $no_save) { backup-file $path }
        $md_res_ansi | ansi strip | save -f $path
    }

    if not $no_info {
        calc-changes $file $md_orig $md_res_ansi
        | if not ($echo or $diff) {
            return $in # default variant: we return here a record
        } else {
            table # we continue here with string
        }
    } else {}
    | if $echo {prepend $md_res_ansi} else {} # output the changes stat table below the resulted markdown
    | if $diff {
        append (diff-changes $file $md_res_ansi) # we use the file path of the original file here
    } else {}
    | if $in == null {} else {
        str join (char nl)
    }
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
    | where row_type =~ '^```nu(shell)?(\s|$)'
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
