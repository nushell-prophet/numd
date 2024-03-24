use nudoc
def nudocr [file: path] {
    nudoc run $file --output-md ($file | str replace '.md' '_out.md' ) --no-backup --intermid-script $'($file)_intermid.nu'
}

[
    examples/working_with_lists.md
    examples/types_of_data.md
] | each {nudocr $in}
