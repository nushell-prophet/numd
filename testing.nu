use numd
def numdr [file: path] {
    numd run $file --no-backup --intermid-script $'($file)_intermid.nu'
}

[
    ('examples' | path join 1_simple_markdown simple_markdown.md)
    ('examples' | path join 2_numd_commands_explanations numd_commands_explanations.md)
    ('examples' | path join 4_book_working_with_lists working_with_lists.md)
    ('examples' | path join 3_book_types_of_data types_of_data.md)
]
| each {numdr $in}
| append (numd run README.md --no-backup)
