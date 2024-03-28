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

### `nudoc run` flags and params

```nushell
# Eventually, the script updates nushell code chunks.
use nudoc
nudoc run --help
```
```nudoc-output
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
  ╭──input──┬─output──╮
  │ nothing │ nothing │
  │ nothing │ string  │
  │ nothing │ record  │
  ╰──input──┴─output──╯
```

### Supported nushell code block options

Nudoc understands the folowing coma separated block options.
They should be in the [infostring](https://github.github.com/gfm/#info-string) of the opening code fence like the example: ` ```nushell try, new-instance `

```nushell
nudoc code-block-options --list
```
```nudoc-output
╭─────long─────┬─short─┬────────description────────╮
│ no-output    │ O     │ don't try printing result │
│ try          │ t     │ try handling errors       │
│ new-instance │ n     │ execute outside           │
│ no-run       │ N     │ dont execute the code     │
╰─────long─────┴─short─┴────────description────────╯
```

### Stats of changes

By default nudoc provides basic stats on changes made.

```nushell
nudoc run examples/1_simple_markdown/simple_markdown_with_no_output.md --no-save
```
```nudoc-output
╭────────────┬───────────────────────────────────╮
│ filename   │ simple_markdown_with_no_output.md │
│ lines      │ +20% from 25                      │
│ words      │ +20.5% from 73                    │
│ chars      │ +17.2% from 437                   │
│ levenstein │ 75                                │
╰────────────┴───────────────────────────────────╯
```

### `nudoc catpure`

Nudoc can use the `display_output` hook to write the current sesssion prompts together with their output into a specified markdown file. There are according commands `nudoc capture start` and `nudoc capture stop`.

```nushell
> nudoc capture start --help
start capturing commands and their results in the current session into a file

Usage:
  > start (file) 

Flags:
  -h, --help - Display the help message for this command

Parameters:
  file <path>:  (optional, default: 'capture.md')

Input/output types:
  ╭──input──┬─output──╮
  │ nothing │ nothing │
  ╰──input──┴─output──╯

> nudoc capture stop --help
stop capturing commands and their results

Usage:
  > stop 

Flags:
  -h, --help - Display the help message for this command

Input/output types:
  ╭──input──┬─output──╮
  │ nothing │ nothing │
  ╰──input──┴─output──╯
```

### Some random familiar examples

```nushell
> ls
╭──────────name──────────┬─type─┬──size──┬────modified────╮
│ LICENSE                │ file │ 1.1 KB │ a month ago    │
│ README.md              │ file │ 6.5 KB │ 13 seconds ago │
│ examples               │ dir  │  224 B │ 15 hours ago   │
│ nudoc                  │ dir  │  224 B │ 31 minutes ago │
│ nupm.nuon              │ file │  115 B │ 15 hours ago   │
│ repository-maintenance │ dir  │   96 B │ 15 hours ago   │
│ testing.nu             │ file │  421 B │ 2 hours ago    │
╰──────────name──────────┴─type─┴──size──┴────modified────╯

> date now
Thu, 28 Mar 2024 05:52:06 +0000 (now)
> git rev-list --count HEAD
181

> git log -1 --format="%cd" --date=iso
2024-03-28 05:34:58 +0000
```

## Examples

```nushell no-run
nudoc run examples/3_book_types_of_data/types_of_data.md --output-md-path examples/3_book_types_of_data/types_of_data_out.md --no-backup --intermid-script-path examples/3_book_types_of_data/types_of_data.md_intermid.nu
```

The results of the command above are provided in the files of the example folder.
