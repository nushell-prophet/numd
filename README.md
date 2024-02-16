# numd - reproducible Nushell Markdown Notebooks

Execute chunks of nushell code within markdown documents, output results to the terminal or write them back to your `.md` document.

numd is inspired by [R Markdown](https://bookdown.org/yihui/rmarkdown/basics.html#basics).

## Quickstart


```
git clone https://github.com/maxim-uvarov/numd; cd numd
use numd
numd run --quiet README.md
```

🗒 The code above isn't executed and updated by numd, as it lacks an opening ````nushell` language idnetifier in the opening code fence tag.

## How it works

1. The 'numd run' command opens a file from the first argument.
2. It looks for ````nushell` code chunks.
3. In the code chunks, that entirely doesn't have lines starting with `>` symbol, numd executes the whole code chunks as they are, and if they produce any output (like in `print 'this'`), then the output is written in the ````numd-output` chunks, next to the executed code chunks.
4. In the code chunks, that contain one or more lines starting with `>` symbol, numd filters only lines that start with `>` or `#` symbol, execute those lines one by one and output their results just after the executed line.
5. Numd output results into the terminal (if the `--queit` flag is not used)
6. Numd update results in the file, which was provided as the first argument after confirmation.

```nushell
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
