# numd - reproducible Nushell Markdown Notebooks

Execute chunks of nushell code within markdown documents, output results to the terminal or write them back to your `.md` document.

numd is inspired by [R Markdown](https://bookdown.org/yihui/rmarkdown/basics.html#basics).

## Quickstart


```
git clone https://github.com/maxim-uvarov/numd; cd numd
use numd
numd run --quiet README.md
```

The code above isn't executed and updated by numd, as it lacks an opening '```nushell' specification tag.

## How it works

```nushell
# The 'numd run' command opens a specified file.
# (The path to the file should be provided as the first argument.)
# It looks for nushell code chunks.
# It splits text into lines.
# The lines with comments it just prints as they are.
# The lines that start with the `>` symbol it prints out as they are and executes, to receive the output.
# Eventually, the script updates nushell code chunks.
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
