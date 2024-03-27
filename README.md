<h1 align="center">nudoc - reproducible Nushell Markdown documents</h1>

Execute chunks of nushell code within markdown documents, output results to the terminal or write them back to your `.md` document.

nudoc is inspired by [R Markdown](https://bookdown.org/yihui/rmarkdown/basics.html#basics).

## Quickstart

```nushell no-run
> git clone https://github.com/nushell101/nudoc; cd nudoc
> nupm install --force --path . # optionally you can install this module via nupm
> use nudoc
> nudoc run README.md --no-save
> nudoc run --help
```

## How it works

`nudoc run` parses the initial file, generates a script to execute the found commands, executes this script in a new nushell instance, parses the results, updates the initial document accordingly and output the resulting document into terminal.

### Details of parsing

2. `nudoc` looks for ` ```nushell ` or ` ```nu ` code chunks.
3. In the code chunks, that entirely don't have lines starting with the `>` symbol, nudoc executes the whole code chunks as they are, and if they produce any output (like in `print 'this'`), then the output is written in the ` ```nudoc-output ` chunks, next to the executed code chunks.
4. In the code chunks that contain one or more lines starting with `>` symbol, nudoc filters only lines that start with the `>` or `#` symbol, executes those lines one by one and output their results just after the executed line.

```nushell
# Eventually, the script updates nushell code chunks.
> ls
╭───────────────name───────────────┬─type─┬──size──┬────modified────╮
│ LICENSE                          │ file │ 1.1 KB │ a month ago    │
│ README.md                        │ file │ 2.5 KB │ a minute ago   │
│ docs                             │ dir  │   64 B │ 3 weeks ago    │
│ examples                         │ dir  │  832 B │ 36 minutes ago │
│ nudoc                            │ dir  │  192 B │ 3 hours ago    │
│ nupm.nuon                        │ file │  115 B │ 2 days ago     │
│ repository-maintenance           │ dir  │   96 B │ 3 weeks ago    │
│ test                             │ dir  │  192 B │ 3 hours ago    │
│ testing.nu                       │ file │  262 B │ 2 days ago     │
╰───────────────name───────────────┴─type─┴──size──┴────modified────╯

> date now
Wed, 27 Mar 2024 11:34:43 +0000 (now)
> git rev-list --count HEAD
164

> git log -1 --format="%cd" --date=iso
2024-03-27 08:12:19 +0000
```

## Examples

```nushell no-run
nudoc run examples/3_book_types_of_data/types_of_data.md --output-md-path examples/3_book_types_of_data/types_of_data_out.md --no-backup --intermid-script-path examples/3_book_types_of_data/types_of_data.md_intermid.nu
```

The results of the command above are provided in the files of the example folder.
