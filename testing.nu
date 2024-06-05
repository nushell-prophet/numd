use ./numd

numd clear-outputs ('examples' | path join 1_simple_markdown simple_markdown.md) -o (
    'examples' | path join 1_simple_markdown simple_markdown_with_no_output.md
)

[
    [1_simple_markdown simple_markdown.md]
    ['2_numd_commands_explanations' numd_commands_explanations.md]
    [4_book_working_with_lists working_with_lists.md]
    [3_book_types_of_data types_of_data.md]
]
| each {
    prepend 'examples'
    | path join
    | numd run $in --no-backup --intermid-script $'($in)_intermid.nu'
}
| append (numd run README.md --no-backup)
