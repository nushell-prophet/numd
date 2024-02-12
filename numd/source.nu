# create a file that will print and execute all the commands by blocks.
# Blocks are made by empty lines between commands.
export def main [
    file: path
] {
    let $out_file = ($file + '.numdtmp')

    open $file
    | str trim --char (char nl)
    | split row -r "\n+\n"
    | each {print-block}
    | prepend 'mut $prev_ts = (date now)'
    | save -f $out_file

    print $'the file ($out_file) is produced. Source it')

    commandline $'source ($out_file)'
}

def print-block [] {
    let $i = $in
    (
        $"print `> ($i | nu-highlight | str replace '`' '“')`\n" +
        $i + "\nprint $'(ansi grey)((date now) - $prev_ts)(ansi reset)'; $prev_ts = (date now);\n\n"
    )
}
