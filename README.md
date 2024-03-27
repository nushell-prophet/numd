<h1 align="center">nudoc - reproducible Nushell Markdown documents</h1>

Execute chunks of nushell code within markdown documents, output results to the terminal or write them back to your `.md` document.

nudoc is inspired by [R Markdown](https://bookdown.org/yihui/rmarkdown/basics.html#basics).

## Quickstart

```nushell no-run
> git clone https://github.com/nushell101/nudoc; cd nudoc
> nupm install --force --path . # optionally you can install this module via nupm
> use nudoc
> nudoc run README.md --no-save
```

## How it works

`nudoc run` parses the initial file, generates a script to execute the found commands, executes this script in a new nushell instance, parses the results, updates the initial document accordingly and output the resulting document into terminal.

Expirienced nushell users can undersand the logic better looking on [examples](./examples/). Especially, seing [nudoc in action describing it's own commands](./examples/2_nudocs_commands_explanations/nudoc_commands_explanations_out.md)

### Details of parsing

2. `nudoc` looks for ` ```nushell ` or ` ```nu ` code chunks.
3. In the code chunks, that entirely don't have lines starting with the `>` symbol, nudoc executes the whole code chunks as they are, and if they produce any output (like in `print 'this'`), then the output is written in the ` ```nudoc-output ` chunks, next to the executed code chunks.
4. In the code chunks that contain one or more lines starting with `>` symbol, nudoc filters only lines that start with the `>` or `#` symbol, executes those lines one by one and output their results just after the executed line.

```nushell
# Eventually, the script updates nushell code chunks.
> use nudoc
> nudoc run --help
run nushell code chunks in a markdown file, outputs results back to the `.md` and optionally to terminal

Usage:
  > run {flags} <file>

Flags:
  -o, --output-md-path <Filepath> - path to a resulting `.md` file; if omitted, updates the original file
  --echo - output resulting markdown to the terminal
  --no-backup - overwrite the existing `.md` file without backup
  --no-save - do not save changes to the `.md` file
  --no-info - do not output stats of changes in `.md` file
  --intermid-script-path <Filepath> - optional a path for an intermediate script (useful for debugging purposes)
  --no-fail-on-error - skip errors (and don't update markdown anyway)
  -h, --help - Display the help message for this command

Parameters:
  file <path>: path to a `.md` file containing nushell code to be executed

Input/output types:
  ╭─input─┬─output─╮
  │ any   │ any    │
  ╰─input─┴─output─╯

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
Wed, 27 Mar 2024 14:13:23 +0000 (now)
> git rev-list --count HEAD
171

> git log -1 --format="%cd" --date=iso
2024-03-27 14:05:47 +0000
```

## Examples

```nushell no-run
nudoc run examples/3_book_types_of_data/types_of_data.md --output-md-path examples/3_book_types_of_data/types_of_data_out.md --no-backup --intermid-script-path examples/3_book_types_of_data/types_of_data.md_intermid.nu
```

The results of the command above are provided in the files of the example folder.
