use nu-utils/cprint.nu
use commands.nu clean-markdown

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
