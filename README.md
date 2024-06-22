<h1 align="center">numd - reproducible Nushell Markdown documents</h1>

Execute blocks of nushell code within markdown documents, write results back to your `.md` document, or output them to the terminal.

`numd` is inspired by [R Markdown](https://bookdown.org/yihui/rmarkdown/basics.html#basics).

## Quickstart

```nushell no-run
# this block won't run as it has the option `no-run` in its code fence
> git clone https://github.com/nushell-prophet/numd; cd numd
> nupm install --force --path . # optionally you can install this module via nupm
> use numd
> numd run README.md --no-save
```

## How it works

`numd run` parses the initial file ([example](/examples/1_simple_markdown/simple_markdown.md)), generates a script to execute the found commands ([example](/examples/1_simple_markdown/simple_markdown.md_intermid.nu)), executes this script in a new nushell instance, parses the results, updates the initial document accordingly, and/or outputs the resulting document into the terminal along with basic changes [stats](#stats-of-changes).

Experienced nushell users can understand the logic better by looking at [examples](./examples/). Especially, seeing [numd in action describing its own commands](./examples/2_numd_commands_explanations/numd_commands_explanations.md).

### Details on parsing code blocks and displaying the output

1. `numd` looks for code blocks marked with ` ```nushell ` or ` ```nu `.
2. In code blocks that do not contain any lines starting with the `>` symbol, `numd` executes the entire code block as is. If the code produces any output, the output is added next to the code block after an empty line, a line with the word `Output:`, and another empty line. The output is enclosed in code fences without a language identifier.
3. In code blocks that contain one or more lines starting with the `>` symbol, `numd` filters only lines that start with the `>` or `#` symbol. It executes or prints those lines one by one, and outputs the results immediately after the executed line.

### `numd run` flags and params

```nushell
> use numd
> numd run --help
Run Nushell code blocks in a markdown file, output results back to the `.md`, and optionally to terminal

Usage:
  > run {flags} <file>

Flags:
  -o, --output-md-path <Filepath> - path to a resulting `.md` file; if omitted, updates the original file
  --echo - output resulting markdown to the terminal
  --save-ansi - save ANSI formatted version
  --no-backup - overwrite the existing `.md` file without backup
  --no-save - do not save changes to the `.md` file
  --no-info - do not output stats of changes
  --intermid-script <Filepath> - optional path for an intermediate script (useful for debugging purposes)
  --no-fail-on-error - skip errors (and don't update markdown in case of errors anyway)
  --prepend-intermid <String> - prepend text (code) into the intermediate script, useful for customizing Nushell output settings
  --diff - use diff for printing changes
  --width <Int> - set the `table --width` option value
  -h, --help - Display the help message for this command

Parameters:
  file <path>: path to a `.md` file containing Nushell code to be executed

Input/output types:
  ╭──input──┬─output──╮
  │ nothing │ nothing │
  │ nothing │ string  │
  │ nothing │ record  │
  ╰──input──┴─output──╯
```

### Supported nushell code block options

`numd` understands the following block options. Several comma-separated block options will be combined together. The block options should be in the [infostring](https://github.github.com/gfm/#info-string) of the opening code fence like the example: ` ```nushell try, new-instance `

```nushell
> numd code-block-options --list
╭─────long──────┬─short─┬──────────────────description──────────────────╮
│ no-output     │ O     │ don't try printing result                     │
│ try           │ t     │ try handling errors                           │
│ new-instance  │ n     │ execute the block in the new Nushell instance │
│ no-run        │ N     │ don't execute the code in block               │
│ indent-output │ i     │ indent the output visually                    │
╰─────long──────┴─short─┴──────────────────description──────────────────╯
```

### Stats of changes

By default, `numd` provides basic stats on changes made.

```nushell
> numd run examples/1_simple_markdown/simple_markdown_with_no_output.md --no-save
╭──────────────────────┬───────────────────────────────────╮
│ filename             │ simple_markdown_with_no_output.md │
│ nushell_code_blocks  │ 3                                 │
│ levenshtein_distance │ 38                                │
│ diff_lines           │ +9 (37.5%)                        │
│ diff_words           │ +6 (10.7%)                        │
│ diff_chars           │ +38 (11%)                         │
╰──────────────────────┴───────────────────────────────────╯
```

Also, the `--diff` flag can be used to display the diff of changes.

```nushell indent-output
numd run examples/1_simple_markdown/simple_markdown_with_no_output.md --diff --no-save --no-info
```

Output:

```
//    $var1 | path join 'baz' 'bar'
//    ```
//    
//  + Output:
//  + 
//  + ```
//  + foo/baz/bar
//  + ```
//  + 
//    ## Example 3
//    
//    ```nu
//    # This block will output results inline
//    > whoami
//  + user
//  + 
//    > 2 + 2
//  + 4
//    ```
```

### `numd clear-outputs`

```nu
> numd clear-outputs --help
Remove numd execution outputs from the file

Usage:
  > clear-outputs {flags} <file>

Flags:
  -o, --output-md-path <Filepath> - path to a resulting `.md` file; if omitted, updates the original file
  --echo - output resulting markdown to the terminal instead of writing to file
  --strip-markdown - keep only Nushell script, strip all markdown tags
  -h, --help - Display the help message for this command

Parameters:
  file <path>: path to a `.md` file containing numd output to be cleared

Input/output types:
  ╭──input──┬─output──╮
  │ nothing │ nothing │
  │ nothing │ string  │
  │ nothing │ record  │
  ╰──input──┴─output──╯
```

### `numd capture`

`numd` can use the `display_output` hook to write the current session prompts together with their output into a specified markdown file. There are corresponding commands `numd capture start` and `numd capture stop`.

```nushell
> numd capture start --help
start capturing commands and their outputs into a file

Usage:
  > start {flags} (file)

Flags:
  --separate - don't use `>` notation, create separate blocks for each pipeline
  -h, --help - Display the help message for this command

Parameters:
  file <path>:  (optional, default: 'numd_capture.md')

Input/output types:
  ╭──input──┬─output──╮
  │ nothing │ nothing │
  ╰──input──┴─output──╯
```

```nushell
> numd capture stop --help
stop capturing commands and their outputs

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

> sys host | get boot_time
Fri, 24 May 2024 07:47:15 +0000 (3 weeks ago)

> 2 + 2
4

> git tag | lines | sort -n | last
0.1.7
```

## Real fight examples to try

```nushell no-output
# output the result of execution to terminal without updating the file
numd run examples/1_simple_markdown/simple_markdown.md --echo --no-save

# run examples in the `types_of_data.md` file,
# save intermid nushell script to `types_of_data.md_intermid.nu`
(
    numd run examples/3_book_types_of_data/types_of_data.md
        --no-backup
        --intermid-script examples/3_book_types_of_data/types_of_data.md_intermid.nu
)
```
