use nu-utils/ [cprint]

# start capturing commands and their results in the current session into a file
export def --env start [
    file: path = 'capture.md'
] {
    cprint $'nudoc commands capture has been started.
        New lines of the recording will be added to the *($file)* file.'

    $env.nudoc.status = 'running'
    $env.nudoc.path = ($file | path expand)

    '```nushell' + (char nl) | save -a $env.nudoc.path

    $env.backup.hooks.display_output = ($env.config.hooks?.display_output? | default {
        if (term size).columns >= 100 { table -e } else { table }
    })
    $env.config.hooks.display_output = {
        let $input = $in;

        $input
        | table -e
        | into string
        | ansi strip
        | default (char nl)
        | '> ' + (history | last | get command) + (char nl) + $in + (char nl)
        | str replace -r "\n\n\n$" "\n\n"
        | if ($in !~ 'nudoc capture') {
            save -ar $env.nudoc.path
        }

        print -n $input # without the `-n` flag new line is added to an output
    }
}

# stop capturing commands and their results
export def --env stop [ ] {
    $env.config.hooks.display_output = $env.backup.hooks.display_output

    let $file = $env.nudoc.path

    '```' + (char nl) | save -a $file

    cprint $'nudoc commands capture to the *($file)* file has been stoped.'

    $env.nudoc.status = 'stopped'
}
