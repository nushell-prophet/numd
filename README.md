# numd - reproducible Nushell Markdown Notebooks

Execute chunks of nushell code within markdown documents, output results to the terminal or back to your `.md` document.
[R Markdown](https://bookdown.org/yihui/rmarkdown/basics.html#basics) inspired.

## Quickstart


`> git clone https://github.com/maxim-uvarov/numd; cd numd`
`> use numd`
`> numd run --quiet README.md`

## How it works

```nushell
# the 'numd run' commands opens a specified file (the path to the file is provided as a first argument)
# it looks for nushell code chunks
# it splits text to lines
# the lines with comments it just prints as it is
# the lines that start with `>` symbol it prints out as it is and executes, to recive the output
> ls
╭───name────┬─type─┬──size──┬────modified────╮
│ LICENSE   │ file │ 1.1 KB │ 4 days ago     │
│ README.md │ file │ 1.3 KB │ 12 seconds ago │
│ examples  │ dir  │  288 B │ 2 hours ago    │
│ nu-utils  │ dir  │  256 B │ 39 minutes ago │
│ numd.nu   │ file │ 3.9 KB │ 13 seconds ago │
╰───────────┴──────┴────────┴────────────────╯

> date now
Mon, 5 Feb 2024 13:59:28 +0000 (now)
```
