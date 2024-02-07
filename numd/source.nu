# create a file that will print and execute all the commands by blocks.
# Blocks are made by empty lines between commands.
export def main [
    file: path
] {
    let $out_file = ($file + 'source.numd')

    open $file
    | str trim --char (char nl)
    | split row -r "\n+\n"
    | each {|i| $"print `> ($i | str replace '`' '“' | nu-highlight)`\n($i)\n" }
    | save -f $out_file

    print $'the file ($out_file) is produced. Source it')

    commandline $'source ($out_file)'
}
