<h1 align="center">nudoc - reproducible Nushell Markdown documents</h1>

Execute chunks of nushell code within markdown documents, output results to the terminal or write them back to your `.md` document.

nudoc is inspired by [R Markdown](https://bookdown.org/yihui/rmarkdown/basics.html#basics).

## Quickstart

```
git clone https://github.com/nushell101/nudoc; cd nudoc
# nupm install --force --path . # optionally you can install this module via nupm
use nudoc
nudoc run --quiet README.md
```
> **Note**
> The code above isn't executed and updated by nudoc, as it lacks an opening ` ```nushell ` language idnetifier in the opening code fence tag.

## How it works

`nudoc run` parses the initial file, generates a script to execute the found commands, executes this script in a new nushell instance, parses the results, updates the initial document accordingly and output the resulting document into terminal.

### Details of parsing

2. `nudoc` looks for ` ```nushell ` or ` ```nu ` code chunks.
3. In the code chunks, that entirely don't have lines starting with the `>` symbol, nudoc executes the whole code chunks as they are, and if they produce any output (like in `print 'this'`), then the output is written in the ` ```nudoc-output ` chunks, next to the executed code chunks.
4. In the code chunks that contain one or more lines starting with `>` symbol, nudoc filters only lines that start with the `>` or `#` symbol, executes those lines one by one and output their results just after the executed line.

```nushell
# Eventually, the script updates nushell code chunks.
> ls
╭──────────name──────────┬─type─┬──size──┬─modified──╮
│ LICENSE                │ file │ 1.1 KB │ a day ago │
│ README.md              │ file │ 2.2 KB │ now       │
│ examples               │ dir  │  704 B │ a day ago │
│ nudoc                  │ dir  │  224 B │ a day ago │
│ nupm.nuon              │ file │  115 B │ a day ago │
│ repository-maintenance │ dir  │   96 B │ a day ago │
╰──────────name──────────┴─type─┴──size──┴─modified──╯

> date now
Sun, 18 Feb 2024 15:32:52 +0000 (now)
> git rev-list --count HEAD
41
> git log -1 --format="%cd" --date=iso
2024-02-17 05:38:49 +0000
```

## Examples

```nushell no-run
nudoc run examples/3_book_types_of_data/types_of_data.md --output-md-path examples/3_book_types_of_data/types_of_data_out.md --no-backup --intermid-script-path examples/3_book_types_of_data/types_of_data.md_intermid.nu
```

The results of the command above are provided in the files of the example folder.
