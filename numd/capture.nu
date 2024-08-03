use nu-utils [cprint]
use nu-utils numd-internals [clean-markdown]

# start capturing commands and their outputs into a file
export def --env start [
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
export def --env stop [ ]: nothing -> nothing {
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
