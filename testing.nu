use ./numd

numd clear-outputs ('examples' | path join 1_simple_markdown simple_markdown.md) -o (
    'examples' | path join 1_simple_markdown simple_markdown_with_no_output.md
)

glob examples/*/*.md --exclude [*/*_with_no_output*]
| each {|file|
    numd run $file --no-backup --intermid-script $'($file)_intermid.nu'
}
| append (numd run README.md --no-backup)
