# numd commands explanation

In the code block below, we set settings and variables for executing this entire document.

```nu
# This setting is for overriding the author's usual small number of `abbreviated_row_count`.
$env.config.table.abbreviated_row_count = 100

# The `$init_numd_pwd_const` constant points to the current working directory from where the `numd` command was initiated.
# It is added by `numd` in every intermediate script to make it available in cases like below.
# We use `path join` here to construct working paths for both Windows and Unix
use ($init_numd_pwd_const | path join numd run1.nu) *
use ($init_numd_pwd_const | path join numd nu-utils numd-internals.nu) *
```

## numd-internals.nu

### detect-code-blocks

This command is used for parsing initial markdown to detect executable code blocks.

```nu indent-output
# Here we set the `$file` variable (which will be used in several commands throughout this script) to point to `examples/1_simple_markdown/simple_markdown.md`.
let $file = $init_numd_pwd_const | path join examples 1_simple_markdown simple_markdown.md

let $md_orig = open -r $file | replace-output-numd-fences
let $md_orig_table = $md_orig | detect-code-blocks
$md_orig_table
```

Output:

```
//  ╭─#──┬─────────────────────────────────line──────────────────────────────────┬────row_type────┬─block_line─╮
//  │ 0  │ # This is a simple markdown example                                   │                │          1 │
//  │ 1  │                                                                       │                │          1 │
//  │ 2  │ ## Example 1                                                          │                │          1 │
//  │ 3  │                                                                       │                │          1 │
//  │ 4  │ the block below will be executed as it is, but won't yield any output │                │          1 │
//  │ 5  │                                                                       │                │          1 │
//  │ 6  │ ```nu                                                                 │ ```nu          │          7 │
//  │ 7  │ let $var1 = 'foo'                                                     │ ```nu          │          7 │
//  │ 8  │ ```                                                                   │ ```nu          │          7 │
//  │ 9  │                                                                       │                │         10 │
//  │ 10 │ ## Example 2                                                          │                │         10 │
//  │ 11 │                                                                       │                │         10 │
//  │ 12 │ ```nu                                                                 │ ```nu          │         13 │
//  │ 13 │ # This block will produce some output in a separate block             │ ```nu          │         13 │
//  │ 14 │ $var1 | path join 'baz' 'bar'                                         │ ```nu          │         13 │
//  │ 15 │ ```                                                                   │ ```nu          │         13 │
//  │ 16 │ ```output-numd                                                        │ ```output-numd │         17 │
//  │ 17 │ foo/baz/bar                                                           │ ```output-numd │         17 │
//  │ 18 │ ```                                                                   │ ```output-numd │         17 │
//  │ 19 │                                                                       │                │         20 │
//  │ 20 │ ## Example 3                                                          │                │         20 │
//  │ 21 │                                                                       │                │         20 │
//  │ 22 │ ```nu                                                                 │ ```nu          │         23 │
//  │ 23 │ # This block will output results inline                               │ ```nu          │         23 │
//  │ 24 │ > whoami                                                              │ ```nu          │         23 │
//  │ 25 │ user                                                                  │ ```nu          │         23 │
//  │ 26 │                                                                       │ ```nu          │         23 │
//  │ 27 │ > 2 + 2                                                               │ ```nu          │         23 │
//  │ 28 │ 4                                                                     │ ```nu          │         23 │
//  │ 29 │ ```                                                                   │ ```nu          │         23 │
//  ╰─#──┴─────────────────────────────────line──────────────────────────────────┴────row_type────┴─block_line─╯
```

## gen-intermid-script

The `gen-intermid-script` command generates a script that contains code from all executable blocks and `numd` service commands used for capturing outputs.

```nu indent-output
# Here we emulate that the `$intermid_script_path` options is not set
let $intermid_script_path = $file
    | path-modify --prefix $'numd-temp-(tstamp)' --suffix '.nu'

gen-intermid-script $md_orig_table
| save -f $intermid_script_path

open $intermid_script_path
```

Output:

```
//  # this script was generated automatically using numd
//  # https://github.com/nushell-prophet/numd
//  const init_numd_pwd_const = '/Users/user/git/numd'
//      print "#code-block-starting-line-in-original-md-7"
//      print "```nu"
//      print ("let $var1 = 'foo'" | nu-highlight)
//
//      print "```\n```output-numd"
//
//  let $var1 = 'foo'
//
//      print "```"
//
//      print "#code-block-starting-line-in-original-md-13"
//      print "```nu"
//      print ("# This block will produce some output in a separate block
//  $var1 | path join 'baz' 'bar'" | nu-highlight)
//
//      print "```\n```output-numd"
//
//  # This block will produce some output in a separate block
//  $var1 | path join 'baz' 'bar' | print; print ''
//
//      print "```"
//
//      print "#code-block-starting-line-in-original-md-23"
//      print "```nu"
//      print ("# This block will output results inline" | nu-highlight)
//
//
//      print ("> whoami" | nu-highlight)
//
//  whoami | print; print ''
//
//      print ("> 2 + 2" | nu-highlight)
//
//  2 + 2 | print; print ''
//
//      print "```"
```

## run-intermid-script

The `run-intermid-script` command runs and captures outputs of the executed intermediate script.

```nu indent-output
# the flag `$no_fail_on_error` is set to false
let $no_fail_on_error = false

let $nu_res_stdout_lines = run-intermid-script $intermid_script_path $no_fail_on_error
rm $intermid_script_path
$nu_res_stdout_lines
```

Output:

```
//  ╭────┬───────────────────────────────────────────────────────────╮
//  │  0 │ #code-block-starting-line-in-original-md-7                │
//  │  1 │ ```nu                                                     │
//  │  2 │ let $var1 = 'foo'                                         │
//  │  3 │ ```                                                       │
//  │  4 │ ```output-numd                                            │
//  │  5 │ ```                                                       │
//  │  6 │ #code-block-starting-line-in-original-md-13               │
//  │  7 │ ```nu                                                     │
//  │  8 │ # This block will produce some output in a separate block │
//  │  9 │ $var1 | path join 'baz' 'bar'                             │
//  │ 10 │ ```                                                       │
//  │ 11 │ ```output-numd                                            │
//  │ 12 │ foo/baz/bar                                               │
//  │ 13 │                                                           │
//  │ 14 │ ```                                                       │
//  │ 15 │ #code-block-starting-line-in-original-md-23               │
//  │ 16 │ ```nu                                                     │
//  │ 17 │ # This block will output results inline                   │
//  │ 18 │ > whoami                                                  │
//  │ 19 │ user                                                      │
//  │ 20 │                                                           │
//  │ 21 │ > 2 + 2                                                   │
//  │ 22 │ 4                                                         │
//  │ 23 │                                                           │
//  │ 24 │ ```                                                       │
//  ╰────┴───────────────────────────────────────────────────────────╯
```

## parse-block-index

The `parse-block-index` command parses the captured output, and groups them by executed blocks.

```nu indent-output
let $nu_res_with_block_index = parse-block-index $nu_res_stdout_lines
$nu_res_with_block_index
```

Output:

```
//  ╭─#─┬─block_line─┬───────────────────────────line────────────────────────────╮
//  │ 0 │          7 │ ```nu                                                     │
//  │   │            │ let $var1 = 'foo'                                         │
//  │   │            │ ```                                                       │
//  │   │            │ ```output-numd                                            │
//  │   │            │ ```                                                       │
//  │ 1 │         13 │ ```nu                                                     │
//  │   │            │ # This block will produce some output in a separate block │
//  │   │            │ $var1 | path join 'baz' 'bar'                             │
//  │   │            │ ```                                                       │
//  │   │            │ ```output-numd                                            │
//  │   │            │ foo/baz/bar                                               │
//  │   │            │                                                           │
//  │   │            │ ```                                                       │
//  │ 2 │         23 │ ```nu                                                     │
//  │   │            │ # This block will output results inline                   │
//  │   │            │ > whoami                                                  │
//  │   │            │ user                                                      │
//  │   │            │                                                           │
//  │   │            │ > 2 + 2                                                   │
//  │   │            │ 4                                                         │
//  │   │            │                                                           │
//  │   │            │ ```                                                       │
//  ╰─#─┴─block_line─┴───────────────────────────line────────────────────────────╯
```

## assemble-markdown

The `assemble-markdown` command cleans outdated commands outputs in the `$md_orig_table` and combines them with `$nu_res_with_block_index` (the variable from the previous step). Additionally, `prettify-markdown` is used here to remove empty blocks and unnecessary empty lines.

```nu indent-output
let $md_res = assemble-markdown $md_orig_table $nu_res_with_block_index
    | prettify-markdown

$md_res
```

Output:

```
//  # This is a simple markdown example
//
//  ## Example 1
//
//  the block below will be executed as it is, but won't yield any output
//
//  ```nu
//  let $var1 = 'foo'
//  ```
//
//  ## Example 2
//
//  ```nu
//  # This block will produce some output in a separate block
//  $var1 | path join 'baz' 'bar'
//  ```
//  ```output-numd
//  foo/baz/bar
//  ```
//
//  ## Example 3
//
//  ```nu
//  # This block will output results inline
//  > whoami
//  user
//
//  > 2 + 2
//  4
//  ```
```

## calc-changes-stats

The `calc-changes-stats` command displays stats on the changes made.

```nu indent-output
calc-changes-stats $file $md_orig $md_res
```

Output:

```
//  ╭──────────────────┬────────────────────╮
//  │ filename         │ simple_markdown.md │
//  │ nushell_blocks   │ 3                  │
//  │ levenshtein_dist │ 0                  │
//  │ diff_lines       │ 0%                 │
//  │ diff_words       │ 0%                 │
//  │ diff_chars       │ 0%                 │
//  ╰──────────────────┴────────────────────╯
```
