# numd commands explanation

In the code block below, we set settings and variables for executing this entire document.

```nu
# This setting is for overriding the author's usual small number of `abbreviated_row_count`.
$env.config.table.abbreviated_row_count = 100

# The `$init_numd_pwd_const` constant points to the current working directory from where the `numd` command was initiated.
# It is added by `numd` in every intermediate script to make it available in cases like below.
# We use `path join` here to construct working paths for both Windows and Unix
use ($init_numd_pwd_const | path join numd commands.nu) *
```

## numd-internals.nu

### find-code-blocks

This command is used for parsing initial markdown to detect executable code blocks.

```nu indent-output
# Here we set the `$file` variable (which will be used in several commands throughout this script) to point to `z_examples/1_simple_markdown/simple_markdown.md`.
let $file = $init_numd_pwd_const | path join z_examples 1_simple_markdown simple_markdown.md

let $md_orig = open -r $file | toggle-output-fences
let $original_md_table = $md_orig | find-code-blocks | group-by-block-index
$original_md_table | table -e
```

Output:

```
//  ╭─block_index──┬────row_type─────┬───────────────────────────────────line────────────────────────────────────┬─────action─────╮
//  │            0 │ text            │ ╭───────────────────────────────────────────────────────────────────────╮ │ print-as-it-is │
//  │              │                 │ │ # This is a simple markdown example                                   │ │                │
//  │              │                 │ │                                                                       │ │                │
//  │              │                 │ │ ## Example 1                                                          │ │                │
//  │              │                 │ │                                                                       │ │                │
//  │              │                 │ │ the block below will be executed as it is, but won't yield any output │ │                │
//  │              │                 │ │                                                                       │ │                │
//  │              │                 │ ╰───────────────────────────────────────────────────────────────────────╯ │                │
//  │            1 │ ```nu           │ ╭───────────────────╮                                                     │ execute        │
//  │              │                 │ │ ```nu             │                                                     │                │
//  │              │                 │ │ let $var1 = 'foo' │                                                     │                │
//  │              │                 │ │ ```               │                                                     │                │
//  │              │                 │ ╰───────────────────╯                                                     │                │
//  │            2 │ text            │ ╭──────────────╮                                                          │ print-as-it-is │
//  │              │                 │ │              │                                                          │                │
//  │              │                 │ │ ## Example 2 │                                                          │                │
//  │              │                 │ │              │                                                          │                │
//  │              │                 │ ╰──────────────╯                                                          │                │
//  │            3 │ ```nu           │ ╭───────────────────────────────────────────────────────────╮             │ execute        │
//  │              │                 │ │ ```nu                                                     │             │                │
//  │              │                 │ │ # This block will produce some output in a separate block │             │                │
//  │              │                 │ │ $var1 | path join 'baz' 'bar'                             │             │                │
//  │              │                 │ │ ```                                                       │             │                │
//  │              │                 │ ╰───────────────────────────────────────────────────────────╯             │                │
//  │            4 │ ```output-numd  │ ╭────────────────╮                                                        │ delete         │
//  │              │                 │ │ ```output-numd │                                                        │                │
//  │              │                 │ │ foo/baz/bar    │                                                        │                │
//  │              │                 │ │ ```            │                                                        │                │
//  │              │                 │ ╰────────────────╯                                                        │                │
//  │            5 │ text            │ ╭──────────────╮                                                          │ print-as-it-is │
//  │              │                 │ │              │                                                          │                │
//  │              │                 │ │ ## Example 3 │                                                          │                │
//  │              │                 │ │              │                                                          │                │
//  │              │                 │ ╰──────────────╯                                                          │                │
//  │            6 │ ```nu           │ ╭─────────────────────────────────────────╮                               │ execute        │
//  │              │                 │ │ ```nu                                   │                               │                │
//  │              │                 │ │ # This block will output results inline │                               │                │
//  │              │                 │ │ > whoami                                │                               │                │
//  │              │                 │ │ user                                    │                               │                │
//  │              │                 │ │                                         │                               │                │
//  │              │                 │ │ > 2 + 2                                 │                               │                │
//  │              │                 │ │ 4                                       │                               │                │
//  │              │                 │ │ ```                                     │                               │                │
//  │              │                 │ ╰─────────────────────────────────────────╯                               │                │
//  ╰─block_index──┴────row_type─────┴───────────────────────────────────line────────────────────────────────────┴─────action─────╯
```

## generate-intermediate-script

The `generate-intermediate-script` command generates a script that contains code from all executable blocks and `numd` service commands used for capturing outputs.

```nu indent-output
# Here we emulate that the `$intermed_script_path` options is not set
let $intermediate_script_path = $file
    | modify-path --prefix $'numd-temp-(generate-timestamp)' --suffix '.nu'

decortate-original-code-blocks $original_md_table
| generate-intermediate-script
| save -f $intermediate_script_path

open $intermediate_script_path
```

Output:

```
//  # this script was generated automatically using numd
//  # https://github.com/nushell-prophet/numd
//
//  const init_numd_pwd_const = '/Users/user/git/numd'
//
//  "#code-block-marker-open-1
//  ```nu" | print
//  "let $var1 = 'foo'" | nu-highlight | print
//
//  "```\n```output-numd" | print
//
//  let $var1 = 'foo'
//
//  "```" | print
//
//  "#code-block-marker-open-3
//  ```nu" | print
//  "# This block will produce some output in a separate block
//  $var1 | path join 'baz' 'bar'" | nu-highlight | print
//
//  "```\n```output-numd" | print
//
//  # This block will produce some output in a separate block
//  $var1 | path join 'baz' 'bar' | table | print; print ''
//
//  "```" | print
//
//  "#code-block-marker-open-6
//  ```nu" | print
//  "# This block will output results inline" | nu-highlight | print
//
//
//  "> whoami" | nu-highlight | print
//
//  whoami | table | print; print ''
//
//  "> 2 + 2" | nu-highlight | print
//
//  2 + 2 | table | print; print ''
//
//  "```" | print
```

## execute-intermediate-script

The `execute-intermediate-script` command runs and captures outputs of the executed intermediate script.

```nu indent-output
# the flag `$no_fail_on_error` is set to false
let $no_fail_on_error = false

let $nu_res_stdout_lines = execute-intermediate-script $intermediate_script_path $no_fail_on_error false
rm $intermediate_script_path
$nu_res_stdout_lines
```

Output:

```
//  #code-block-marker-open-1
//  ```nu
//  let $var1 = 'foo'
//  ```
//  ```output-numd
//  ```
//  #code-block-marker-open-3
//  ```nu
//  # This block will produce some output in a separate block
//  $var1 | path join 'baz' 'bar'
//  ```
//  ```output-numd
//  foo/baz/bar
//
//  ```
//  #code-block-marker-open-6
//  ```nu
//  # This block will output results inline
//  > whoami
//  user
//
//  > 2 + 2
//  4
//
//  ```
```

```nu indent-output
let $md_res = $nu_res_stdout_lines
    | str join (char nl)
    | clean-markdown

$md_res
```

Output:

```
//  #code-block-marker-open-1
//  ```nu
//  let $var1 = 'foo'
//  ```
//  #code-block-marker-open-3
//  ```nu
//  # This block will produce some output in a separate block
//  $var1 | path join 'baz' 'bar'
//  ```
//  ```output-numd
//  foo/baz/bar
//
//  ```
//  #code-block-marker-open-6
//  ```nu
//  # This block will output results inline
//  > whoami
//  user
//
//  > 2 + 2
//  4
//
//  ```
```

## compute-change-stats

The `compute-change-stats` command displays stats on the changes made.

```nu indent-output
compute-change-stats $file $md_orig $md_res
```

Output:

```
//  ╭──────────────────┬────────────────────╮
//  │ filename         │ simple_markdown.md │
//  │ nushell_blocks   │ 3                  │
//  │ levenshtein_dist │ 157                │
//  │ diff_lines       │ -7 (-23.3%)        │
//  │ diff_words       │ -11 (-17.5%)       │
//  │ diff_chars       │ -72 (-18.8%)       │
//  ╰──────────────────┴────────────────────╯
```
