use numd
def numdr [file: path] {
    numd run $file --no-backup --intermid-script-path $'($file)_intermid.nu'
}

[
    examples/1_simple_markdown/simple_markdown.md
    examples/2_numd_commands_explanations/numd_commands_explanations.md
    examples/4_book_working_with_lists/working_with_lists.md
    examples/3_book_types_of_data/types_of_data.md
]
| each {numdr $in}
| append (numd run README.md --no-backup)
