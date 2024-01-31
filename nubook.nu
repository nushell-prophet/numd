# start capturing commands and their results into a file
export def --env start_capture [
    file: path = 'nubook.nu.txt'
] {
    $env.nubook.path = $file;
    $env.backup.hooks.display_output = $env.config.hooks?.display_output? | default {table}
    $env.config.hooks.display_output = {
        let $input = $in;

        $input
        | table -e
        | into string
        | ansi strip
        | '> ' + (history | last | get command) + (char nl) + $in
        | if ($in !~ 'stop_capture') {
            save -ar $env.nubook.path;
        }

        print -n $input # without -n the new line is added to output
    }
}

# stop capturing commands and their results
export def --env stop_capture [ ] {
    $env.config.hooks.display_output = $env.backup.hooks.display_output
}

# run nubook
export def run [
    file: path
    --save_to: path = '' # path of file to save
    --quiet # don't output results into terminal
] {
    let $res = (
        open $file
        | lines
        | where ($it | str starts-with '> ')
        | str replace -r '^> ' ''
        | each {|i| $"print `> ($i | nu-highlight)`; (char nl)print \(" + $i + ')'}
        | str join (char nl)
        | nu -c $in --env-config $nu.env-path --config $nu.config-path
    )

    if $save_to != '' {$res | ansi strip | save -f $save_to}

    if not $quiet {print $res}
}
