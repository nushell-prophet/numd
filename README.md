<h1 align="center">numd - reproducible Nushell Markdown documents</h1>

Execute chunks of nushell code within markdown documents, write results back to your `.md` document or output them to the terminal.

`numd` is inspired by [R Markdown](https://bookdown.org/yihui/rmarkdown/basics.html#basics).

## Quickstart

```nushell no-run
# this block won't run as it has option `no-run` in its code fence
> git clone https://github.com/nushell-prophet/numd; cd numd
> nupm install --force --path . # optionally you can install this module via nupm
> use numd
> numd run README.md --no-save
```

## How it works

`numd run` parses the initial file, generates a script to execute the found commands, executes this script in a new nushell instance, parses the results, updates the initial document accordingly, and/or outputs the resulting document into the terminal along with basic changes [stats](#stats-of-changes).

Experienced nushell users can understand the logic better by looking at [examples](./examples/). Especially, seeing [numd in action describing its own commands](./examples/2_numd_commands_explanations/numd_commands_explanations.md).

### Details of parsing

1. `numd` looks for ` ```nushell ` or ` ```nu ` code chunks.
2. In the code chunks, that entirely don't have lines starting with the `>` symbol, numd executes the whole code chunks as they are, and if they produce any output (like in `print 'this'`), then the output is written in the ` ```numd-output ` chunks, next to the executed code chunks.
3. In the code chunks that contain one or more lines starting with `>` symbol, numd filters only lines that start with the `>` or `#` symbol, executes those lines one by one and output their results just after the executed line.

### `numd run` flags and params

```nushell
use numd
numd run --help
```
```numd-output
run nushell code chunks in a markdown file, outputs results back to the `.md` and optionally to terminal

Usage:
  > run {flags} <file> 

Flags:
  -o, --output-md-path <Filepath> - path to a resulting `.md` file; if omitted, updates the original file
  --echo - output resulting markdown to the terminal
  --no-backup - overwrite the existing `.md` file without backup
  --no-save - do not save changes to the `.md` file
  --no-info - do not output stats of changes in `.md` file
  --intermid-script <Filepath> - optional a path for an intermediate script (useful for debugging purposes)
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

```

### Supported nushell code block options

`numd` understands the following block options. Several commaseparated block options will be combined together.
The block options should be in the [infostring](https://github.github.com/gfm/#info-string) of the opening code fence like the example: ` ```nushell try, new-instance `

```nushell
numd code-block-options --list
```
```numd-output
╭─────long──────┬─short─┬──────────────────description──────────────────╮
│ no-output     │ O     │ don't try printing result                     │
│ try           │ t     │ try handling errors                           │
│ new-instance  │ n     │ execute the chunk in the new nushell instance │
│ no-run        │ N     │ don't execute the code in chunk               │
│ indent-output │ i     │ indent the output visually                    │
╰─────long──────┴─short─┴──────────────────description──────────────────╯
```

### Stats of changes

By default `numd` provides basic stats on changes made.

```nushell
numd run examples/1_simple_markdown/simple_markdown_with_no_output.md --no-save
```
```numd-output
╭────────────┬───────────────────────────────────╮
│ filename   │ simple_markdown_with_no_output.md │
│ lines      │ +20% from 25                      │
│ words      │ +20.5% from 73                    │
│ chars      │ +16.9% from 437                   │
│ levenstein │ 74                                │
╰────────────┴───────────────────────────────────╯
```

### `numd catpure`

`numd` can use the `display_output` hook to write the current sesssion prompts together with their output into a specified markdown file. There are corresponding commands `numd capture start` and `numd capture stop`.

```nushell
> numd capture start --help
start capturing commands and their results into a file

Usage:
  > start (file) 

Flags:
  -h, --help - Display the help message for this command

Parameters:
  file <path>:  (optional, default: 'numd_capture.md')

Input/output types:
  ╭──input──┬─output──╮
  │ nothing │ nothing │
  ╰──input──┴─output──╯

> numd capture stop --help
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
> ls examples | sort-by name | reject modified size
╭─────────────────name──────────────────┬─type─╮
│ examples/1_simple_markdown            │ dir  │
│ examples/2_numd_commands_explanations │ dir  │
│ examples/3_book_types_of_data         │ dir  │
│ examples/4_book_working_with_lists    │ dir  │
╰─────────────────name──────────────────┴─type─╯

> sys | get host.boot_time
2024-03-27T07:30:08+00:00
> 2 + 2
4
> git tag | lines | sort -n | last
0.1.0
```

## Real fight examples to try

```nushell no-run
numd run examples/1_simple_markdown/simple_markdown.md --echo --no-save
numd run examples/3_book_types_of_data/types_of_data.md --output-md-path examples/3_book_types_of_data/types_of_data_out.md --no-backup --intermid-script-path examples/3_book_types_of_data/types_of_data.md_intermid.nu
```
