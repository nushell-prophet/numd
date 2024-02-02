# nubook - jupiter notebooks inspired text-based notebooks for Nushell

# > use nubook.nu
# > nubook start_capture my_first_nubook.txt
# > # run some commands to capture in a nubook
# > ls
# > date now
# > print "this is cool"
# > nubook stop_capture
# > nubook run my_first_nubook.txt

use nu-utils [confirm]

# start capturing commands and their results into a file
export def --env start_capture [
    file: path = 'nubook.nu.txt'
] {
    $env.nubook.path = ($file | path expand)
    $env.backup.hooks.display_output = ($env.config.hooks?.display_output? | default {table})
    $env.config.hooks.display_output = {
        let $input = $in;

        $input
        | table -e
        | into string
        | ansi strip
        | default (char nl)
        | '> ' + (history | last | get command) + (char nl) + $in
        | if ($in !~ 'stop_capture') {
            save -ar $env.nubook.path
        }

        print -n $input # without the `-n` flag new line is added to an output
    }
}

# stop capturing commands and their results
export def --env stop_capture [ ] {
    $env.config.hooks.display_output = $env.backup.hooks.display_output
}

# run nubook
export def run [
    file: path # nubook file to run
    output?: path # path of file to save
    --quiet # don't output results into terminal
    --overwrite (-o) # owerwrite existing file without confirmation
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

    if not $quiet {print $res}

    mut $path = ( $output | default $file )
    mut $keep_asking = true

    while $keep_asking {
        if ($path | path exists) {
            if $overwrite or (confirm $'would you like to overwrite *($path)*') {
                $keep_asking = false
            } else {
                $path = (input 'Enter the new nubook filename: ')
            }
        } else {
            $keep_asking = false
        }
    }

    $res
    | ansi strip
    | save -f $path
}
