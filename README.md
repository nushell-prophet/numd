[![CI](https://github.com/nushell-prophet/numd/actions/workflows/ci.yml/badge.svg)](https://github.com/nushell-prophet/numd/actions/workflows/ci.yml)

# numd - reproducible Nushell Markdown documents

Execute blocks of nushell code within markdown documents, write results back to your `.md` document, or output them to the terminal.

## Quickstart

```nushell no-run
# clone the repo and `cd` into it
git clone https://github.com/nushell-prophet/numd
cd numd

# use definitions from the module
use numd

# run it on any file to check
numd run z_examples/1_simple_markdown/simple_markdown.md --no-save
```

## How it works

`numd run` parses the initial file ([example](/z_examples/1_simple_markdown/simple_markdown.md)), generates a script to execute the found commands ([example](/z_examples/1_simple_markdown/simple_markdown.md_intermed.nu)), executes this script in a new nushell instance, captures the results, updates the initial document accordingly, and/or outputs the resulting document into the terminal along with basic changes [stats](#stats-of-changes).

Experienced nushell users can understand the logic better by looking at [examples](./z_examples/). Especially, seeing [numd in action describing its own commands](./z_examples/2_numd_commands_explanations/numd_commands_explanations.md).

### Details on parsing code blocks and displaying the output

1. `numd` looks for code blocks marked with ` ```nushell ` or ` ```nu `.
2. Code blocks are split into command groups by blank lines (double newlines). Each command group is executed separately.
3. Output from each command group is displayed inline with `# =>` prefix immediately after the command.
4. Multiline commands (pipelines split across lines without blank lines) are treated as a single command group.
5. Plain `#` comments are preserved; `# =>` output lines are regenerated on each run.
6. Use the `separate-block` fence option to output results in a separate code block instead of inline.

> [!NOTE]
> This readme is a live `numd` document

### `numd run` flags and params

```nushell
use numd
numd run --help
# => Run Nushell code blocks in a markdown file, output results back to the `.md`, and optionally to terminal
# =>
# => Usage:
# =>   > run {flags} <file>
# =>
# => Flags:
# =>   -h, --help: Display the help message for this command
# =>   -o, --result-md-path <path>: path to a resulting `.md` file; if omitted, updates the original file
# =>   --print-block-results: print blocks one by one as they are executed
# =>   --echo: output resulting markdown to the terminal
# =>   --save-ansi: save ANSI formatted version
# =>   --no-backup: overwrite the existing `.md` file without backup
# =>   --no-save: do not save changes to the `.md` file
# =>   --no-stats: do not output stats of changes
# =>   --save-intermed-script <path>: optional path for keeping intermediate script (useful for debugging purposes). If not set, the temporary intermediate script will be deleted.
# =>   --no-fail-on-error: skip errors (and don't update markdown in case of errors anyway)
# =>   --prepend-code <string>: prepend code into the intermediate script, useful for customizing Nushell output settings
# =>   --table-width <int>: set the `table --width` option value
# =>   --config-path <path>: path to a config file (default: '')
# =>
# => Parameters:
# =>   file <path>: path to a `.md` file containing Nushell code to be executed
# =>
# => Input/output types:
# =>   ╭─#─┬──input──┬─output──╮
# =>   │ 0 │ nothing │ string  │
# =>   │ 1 │ nothing │ nothing │
# =>   │ 2 │ nothing │ record  │
# =>   ╰─#─┴──input──┴─output──╯
# =>
# => Examples:
# =>   update readme
# =>   > numd run README.md
# =>
```

### Supported fence options

`numd` understands the following fence options. Several comma-separated fence options can be combined together. Fence options are placed in the [infostring](https://github.github.com/gfm/#info-string) of the opening code fence, for example: ` ```nushell try, new-instance `

```nushell
numd list-fence-options --list
# => ╭──────long──────┬─short─┬───────────────────────────description────────────────────────────╮
# => │ no-output      │ O     │ execute code without outputting results                          │
# => │ no-run         │ N     │ do not execute code in block                                     │
# => │ try            │ t     │ execute block inside `try {}` for error handling                 │
# => │ new-instance   │ n     │ execute block in new Nushell instance (useful with `try` block)  │
# => │ separate-block │ s     │ output results in a separate code block instead of inline `# =>` │
# => ╰──────long──────┴─short─┴───────────────────────────description────────────────────────────╯
```

### Stats of changes

By default, `numd` provides basic stats on changes made.

```nushell
let path = [z_examples 1_simple_markdown simple_markdown_with_no_output.md] | path join
numd run --no-save $path
# => ╭──────────────────┬───────────────────────────────────╮
# => │ filename         │ simple_markdown_with_no_output.md │
# => │ nushell_blocks   │ 3                                 │
# => │ levenshtein_dist │ 52                                │
# => │ diff_lines       │ +8 (25.8%)                        │
# => │ diff_words       │ +6 (8.5%)                         │
# => │ diff_chars       │ +52 (11.6%)                       │
# => ╰──────────────────┴───────────────────────────────────╯
```

### Styling outputs

It is possible to set Nushell visual settings (and all the others) using the `--prepend-code` option. Just pass a code there to be prepended into our save-intermed-script.nu and executed before all parts of the code.

```nushell
let path = $nu.temp-path | path join simple_nu_table.md

# let's generate some markdown and save it to the `simple_nu_table.md` file in the temp directory
"```nushell\n[[a b c]; [1 2 3]]\n```\n" | save -f $path

# let's run this file to see it's outputs
numd run $path --echo --no-save --no-stats --prepend-code "
    $env.config.footer_mode = 'never'
    $env.config.table.header_on_separator = false
    $env.config.table.index_mode = 'never'
    $env.config.table.mode = 'basic_compact'
"
# => ```nushell
# => [[a b c]; [1 2 3]]
# => # => +---+---+---+
# => # => | a | b | c |
# => # => | 1 | 2 | 3 |
# => # => +---+---+---+
# => ```
```

### `numd clear-outputs`

```nu
numd clear-outputs --help
# => Remove numd execution outputs from the file
# =>
# => Usage:
# =>   > clear-outputs {flags} <file>
# =>
# => Flags:
# =>   -h, --help: Display the help message for this command
# =>   -o, --result-md-path <path>: path to a resulting `.md` file; if omitted, updates the original file
# =>   --echo: output resulting markdown to the terminal instead of writing to file
# =>   --strip-markdown: keep only Nushell script, strip all markdown tags
# =>
# => Parameters:
# =>   file <path>: path to a `.md` file containing numd output to be cleared
# =>
# => Input/output types:
# =>   ╭─#─┬──input──┬─output──╮
# =>   │ 0 │ nothing │ string  │
# =>   │ 1 │ nothing │ nothing │
# =>   ╰─#─┴──input──┴─output──╯
# =>
```

### `numd capture`

`numd` can use the `display_output` hook to write the current session prompts together with their output into a specified markdown file. There are corresponding commands `numd capture start` and `numd capture stop`.

```nushell
numd capture start --help
# => start capturing commands and their outputs into a file
# =>
# => Usage:
# =>   > capture start {flags} (file)
# =>
# => Flags:
# =>   -h, --help: Display the help message for this command
# =>   --separate-blocks: create separate code blocks for each pipeline instead of inline `# =>` output
# =>
# => Parameters:
# =>   file <path>:  (optional, default: 'numd_capture.md')
# =>
# => Input/output types:
# =>   ╭─#─┬──input──┬─output──╮
# =>   │ 0 │ nothing │ nothing │
# =>   ╰─#─┴──input──┴─output──╯
# =>
```

```nushell
numd capture stop --help
# => stop capturing commands and their outputs
# =>
# => Usage:
# =>   > capture stop
# =>
# => Flags:
# =>   -h, --help: Display the help message for this command
# =>
# => Input/output types:
# =>   ╭─#─┬──input──┬─output──╮
# =>   │ 0 │ nothing │ nothing │
# =>   ╰─#─┴──input──┴─output──╯
# =>
```

### Some random familiar examples

```nushell
ls z_examples | sort-by name | reject modified size
# => ╭──────────────────name───────────────────┬─type─╮
# => │ z_examples/1_simple_markdown            │ dir  │
# => │ z_examples/2_numd_commands_explanations │ dir  │
# => │ z_examples/3_book_types_of_data         │ dir  │
# => │ z_examples/4_book_working_with_lists    │ dir  │
# => │ z_examples/5_simple_nu_table            │ dir  │
# => │ z_examples/6_edge_cases                 │ dir  │
# => │ z_examples/7_image_output               │ dir  │
# => │ z_examples/8_parse_frontmatter          │ dir  │
# => │ z_examples/999_numd_internals           │ dir  │
# => │ z_examples/99_strip_markdown            │ dir  │
# => │ z_examples/9_other                      │ dir  │
# => ╰──────────────────name───────────────────┴─type─╯

'hello world' | str length
# => 11

2 + 2
# => 4

git tag | lines | sort -n | last
# => 0.2.2
```

## Real fight examples to try

```nushell no-output
# output the result of execution to terminal without updating the file
[z_examples 1_simple_markdown simple_markdown.md]
| path join
| numd run $in --echo --no-save
```

## Development and testing

Nushell Markdown documents used together with Git could often serve as a convenient way to test custom and built-in Nushell commands.

Testing of the `numd` module is done via `toolkit.nu`:

```nushell no-run
# Run all tests (unit + integration)
nu toolkit.nu test

# Run only unit tests (uses nutest framework)
nu toolkit.nu test-unit

# Run only integration tests (executes example markdown files)
nu toolkit.nu test-integration
```

### Unit tests

Unit tests in `tests/` use the [nutest](https://github.com/vyadh/nutest) framework to test internal functions like `parse-markdown-to-blocks`, `classify-block-action`, `extract-fence-options`, etc.

### Integration tests

Integration tests run all example files in `z_examples/` through numd and report changes via Levenshtein distance. Whatever changes are made in the module - it can be easily seen if they break anything (both by the Levenshtein distance metric or by `git diff` of the updated example files versus their initial versions).

```nushell no-run
nu toolkit.nu test-integration
# => ╭───────────────────────────────────────────────┬─────────────────┬───────────────────┬────────────┬──────────────┬─────╮
# => │                   filename                    │ nushell_blocks  │ levenshtein_dist  │ diff_lines │  diff_words  │ ... │
# => ├───────────────────────────────────────────────┼─────────────────┼───────────────────┼────────────┼──────────────┼─────┤
# => │ types_of_data.md                              │              30 │               204 │ 0%         │ -29 (-1.1%)  │ ... │
# => │ working_with_lists.md                         │              20 │                 4 │ 0%         │ 0%           │ ... │
# => │ numd_commands_explanations.md                 │               6 │                 0 │ 0%         │ 0%           │ ... │
# => │ simple_markdown.md                            │               3 │                 0 │ 0%         │ 0%           │ ... │
# => │ error-with-try.md                             │               1 │                13 │ -1 (-4.3%) │ 0%           │ ... │
# => │ simple_markdown_first_block.md                │               3 │                 0 │ 0%         │ 0%           │ ... │
# => │ raw_strings_test.md                           │               2 │                 0 │ 0%         │ 0%           │ ... │
# => │ simple_nu_table.md                            │               3 │                 0 │ 0%         │ 0%           │ ... │
# => │ simple_nu_table_customized_width20.md         │               3 │               458 │ 0%         │ -42 (-23.7%) │ ... │
# => │ simple_nu_table_customized_example_config.md  │               3 │                56 │ 0%         │ -4 (-2.3%)   │ ... │
# => │ README.md                                     │               9 │                 0 │ 0%         │ 0%           │ ... │
# => ╰───────────────────────────────────────────────┴─────────────────┴───────────────────┴────────────┴──────────────┴─────╯
```
