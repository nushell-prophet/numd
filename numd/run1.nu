use nu-utils numd-internals *
export use nu-utils numd-internals code-block-options

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
    --intermid-script: path # optional path for an intermediate script (useful for debugging purposes)
    --no-fail-on-error # skip errors (and don't update markdown in case of errors anyway)
    --prepend-intermid: string # prepend text (code) into the intermediate script, useful for customizing Nushell output settings
    --diff # use diff for printing changes
    --width: int # set the `table --width` option value
]: [nothing -> string, nothing -> nothing, nothing -> record] {
    let $original_md = open -r $file

    let $original_md_table = $original_md
        | replace-output-numd-fences
        | detect-code-blocks

    if $width != null {
        $env.numd.table-width = $width
    }

    let $intermediate_script_path = $intermid_script
        | default ( $file | path-modify --prefix $'numd-temp-(tstamp)' --extension '.nu' )
        # We don't use a temp directory here as the code in `md` files might contain relative paths,
        # which will only work if we execute the intermediate script from the same folder.

    gen-intermid-script $original_md_table
    | if $prepend_intermid == null {} else {
        $'($prepend_intermid)(char nl)($in)'
    }
    | save -f $intermediate_script_path

    let $updated_md_ansi = run-intermid-script $intermediate_script_path $no_fail_on_error --print-block-results=$print_block_results
        | if $in == '' {
            return {
                filename: $file,
                comment: "Execution of Nushell blocks didn't produce any output. The markdown file was not updated"
            }
        } else {}
        | $in + (char nl)
        | prettify-markdown
        | replace-output-numd-fences --back

    # if $intermid_script param wasn't set - remove the temporary intermediate script
    if $intermid_script == null {
        rm $intermediate_script_path
    }

    let $output_path = $result_md_path | default $file
    if not $no_save {
        if not $no_backup { backup-file $output_path }
        $updated_md_ansi | ansi strip | save -f $output_path
    }
    if $save_ansi {
        $updated_md_ansi | save -f $'($output_path).ans'
    }

    if not $no_stats {
        calc-changes-stats $file $original_md $updated_md_ansi
        | if not ($echo or $diff) {
            return $in # default variant: we return here a record
        } else {
            table # we continue here with `string` as it will be appended to the resulting `string` markdown
        }
    } else {}
    | if $echo {prepend $updated_md_ansi} else {} # output the changes stat table below the resulting markdown
    | if $diff {
        append (diff-changes $file $updated_md_ansi) # we use the file path of the original file here
    } else {}
    | if $in == null {} else {
        str join (char nl)
    }
}

# Remove numd execution outputs from the file
export def clear-outputs [
    file: path # path to a `.md` file containing numd output to be cleared
    --result-md-path (-o): path # path to a resulting `.md` file; if omitted, updates the original file
    --echo # output resulting markdown to the terminal instead of writing to file
    --strip-markdown # keep only Nushell script, strip all markdown tags
]: [nothing -> string, nothing -> nothing] {
    let $original_md_table = open -r $file
        | replace-output-numd-fences
        | detect-code-blocks

    let $result_md_path = $result_md_path | default $file

    $original_md_table
    | where row_type =~ '^```nu(shell)?(\s|$)'
    | group-by block_line
    | items {|block_index block_lines|
        $block_lines.line
        | if ($in | where $it =~ '^>' | is-empty) {} else {
            where $it =~ '^(>|#|```)'
        }
        | prepend (numd-block $block_index)
    }
    | flatten
    | parse-block-index $in
    | if $strip_markdown {
        get line
        | each {lines | update 0 {$'(char nl)# ($in)'} | drop | str join (char nl)}
        | str join (char nl)
        | return $in
    } else {
        assemble-markdown $original_md_table $in
    }
    | if $echo {} else {
        save -f $result_md_path
    }
}
