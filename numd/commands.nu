use nu-utils numd-internals *
export use nu-utils numd-internals list-code-options

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

    generate-intermediate-script $original_md_table
    | save -f $intermediate_script_path

    let $nu_res_with_block_index = execute-intermediate-script $intermediate_script_path $no_fail_on_error $print_block_results
        | if $in == '' {
            return { filename: $file,
                comment: "the script didn't produce any output" }
        } else {}
        | lines
        | extract-block-index $in

    # $nu_res_with_block_index | save -f ($file + '_intermed_exec.json')

    let $updated_md_ansi = merge-markdown $original_md_table $nu_res_with_block_index
        | clean-markdown
        | toggle-output-fences --back

    # if $intermed_script param wasn't set - remove the temporary intermediate script
    if $intermed_script == null {
        rm $intermediate_script_path
    }

    let $output_path = $result_md_path | default $file
    if not $no_save {
        if not $no_backup { create-file-backup $output_path }
        $updated_md_ansi | ansi strip | save -f $output_path
    }
    if $save_ansi {
        $updated_md_ansi | save -f $'($output_path).ans'
    }

    if not $no_stats {
        compute-change-stats $output_path $original_md $updated_md_ansi
        | if not $echo {
            return $in # default variant: we return here a record
        } else {
            table # we continue here with `string` as it will be appended to the resulting `string` markdown
        }
    } else {}
    | if $echo {prepend $updated_md_ansi} else {} # output the changes stat table below the resulting markdown
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
            | to text
        }
        | str join (char nl)
        | return $in # we return the stripped script here to not spoil original md
    } else {
        merge-markdown $original_md_table $in
        | clean-markdown
    }
    | if $echo {} else {
        save -f $result_md_path
    }
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

    if not $separate {
        "```nushell\n" | save -a $env.numd.path
    }

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
    | if $sections != null {
        select -i ...$sections
    } else {}
    | if $record {
        items {|k v|
            {$k: ($v | to text)}
        }
        | into record
    } else {
        items {|k v| $v
            | str replace -r '^\s*(\S)' '  $1' # add two spaces before description lines
            | to text
            | $"($k):\n($in)"
        }
        | to text
        | str replace -ar '[\n\s]+$' '' # empty trailing new lines
        | str replace -arm '^' '// '
    }
}
