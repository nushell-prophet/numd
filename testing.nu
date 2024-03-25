use nudoc
def nudocr [file: path] {
    nudoc run $file --output-md-path ($file | str replace '.md' '_out.md' ) --no-backup --intermid-script-path $'($file)_intermid.nu'
}

[
    examples/working_with_lists.md
    examples/types_of_data.md
] | each {nudocr $in}
