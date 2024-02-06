use nu-utils/ [cprint]

# start capturing commands and their results in the current session into a file
export def --env start [
    file: path = 'capture.md'
] {
    cprint $'numd commands capture has been started.
        New lines of the recording will be added to the *($file)* file.'

    $env.numd.status = 'running'
    $env.numd.path = ($file | path expand)

    '```nushell' + (char nl) | save -a $env.numd.path

    $env.backup.hooks.display_output = ($env.config.hooks?.display_output? | default {table})
    $env.config.hooks.display_output = {
        let $input = $in;

        $input
        | table -e
        | into string
        | ansi strip
        | default (char nl)
        | '> ' + (history | last | get command) + (char nl) + $in + (char nl)
        | str replace -r "\n\n\n$" "\n\n"
        | if ($in !~ 'numd capture') {
            save -ar $env.numd.path
        }

        print -n $input # without the `-n` flag new line is added to an output
    }
}

# stop capturing commands and their results
export def --env stop [ ] {
    $env.config.hooks.display_output = $env.backup.hooks.display_output

    let $file = $env.numd.path

    '```' + (char nl) | save -a $file

    cprint $'numd commands capture to the *($file)* file has been stoped.'

    $env.numd.status = 'stopped'
}
