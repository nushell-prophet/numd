# numd - R Markdown inspired text-based notebooks for Nushell

# > use numd.nu
# > numd start_capture my_first_numd.txt
# > # run some commands to capture in a numd
# > ls
# > date now
# > print "this is cool"
# > numd stop_capture
# > numd run my_first_numd.txt

use nu-utils [confirm]

# start capturing commands and their results into a file
export def --env start_capture [
    file: path = 'numd.nu.txt'
] {
    $env.numd.path = ($file | path expand)
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
        | if ($in !~ 'stop_capture') {
            save -ar $env.numd.path
        }

        print -n $input # without the `-n` flag new line is added to an output
    }
}

# stop capturing commands and their results
export def --env stop_capture [ ] {
    $env.config.hooks.display_output = $env.backup.hooks.display_output
}

# run numd
export def run [
    file: path # numd file to run
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
                $path = (input 'Enter the new numd filename: ')
            }
        } else {
            $keep_asking = false
        }
    }

    $res
    | ansi strip
    | save -f $path
}
