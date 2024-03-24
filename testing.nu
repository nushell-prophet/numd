use nudoc
def nudocr [file: path] {
    nudoc run $file --output-md ($file | str replace '.md' '_out.md' ) --no-backup --intermid-script $'($file)_intermid.nu'
}

nudocr examples/working_with_lists.md;
nudocr examples/types_of_data.md
