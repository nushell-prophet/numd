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
# Here we set the `$file` variable (which will be used in several commands throughout this script) to point to `z_examples/1_simple_markdown/simple_markdown.md`.
let $file = $init_numd_pwd_const | path join z_examples 1_simple_markdown simple_markdown.md

let $md_orig = open -r $file | replace-output-numd-fences
let $md_orig_table = $md_orig | detect-code-blocks
$md_orig_table
```

Output:

```
//  ╭─────────────────────────────────line──────────────────────────────────┬────row_type────┬─block_line─╮
//  │ # This is a simple markdown example                                   │                │          1 │
//  │                                                                       │                │          1 │
//  │ ## Example 1                                                          │                │          1 │
//  │                                                                       │                │          1 │
//  │ the block below will be executed as it is, but won't yield any output │                │          1 │
//  │                                                                       │                │          1 │
//  │ ```nu                                                                 │ ```nu          │          7 │
//  │ let $var1 = 'foo'                                                     │ ```nu          │          7 │
//  │ ```                                                                   │ ```nu          │          7 │
//  │                                                                       │                │         10 │
//  │ ## Example 2                                                          │                │         10 │
//  │                                                                       │                │         10 │
//  │ ```nu                                                                 │ ```nu          │         13 │
//  │ # This block will produce some output in a separate block             │ ```nu          │         13 │
//  │ $var1 | path join 'baz' 'bar'                                         │ ```nu          │         13 │
//  │ ```                                                                   │ ```nu          │         13 │
//  │ ```output-numd                                                        │ ```output-numd │         17 │
//  │ foo/baz/bar                                                           │ ```output-numd │         17 │
//  │ ```                                                                   │ ```output-numd │         17 │
//  │                                                                       │                │         20 │
//  │ ## Example 3                                                          │                │         20 │
//  │                                                                       │                │         20 │
//  │ ```nu                                                                 │ ```nu          │         23 │
//  │ # This block will output results inline                               │ ```nu          │         23 │
//  │ > whoami                                                              │ ```nu          │         23 │
//  │ user                                                                  │ ```nu          │         23 │
//  │                                                                       │ ```nu          │         23 │
//  │ > 2 + 2                                                               │ ```nu          │         23 │
//  │ 4                                                                     │ ```nu          │         23 │
//  │ ```                                                                   │ ```nu          │         23 │
//  ╰─────────────────────────────────line──────────────────────────────────┴────row_type────┴─block_line─╯
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
//  "# This is a simple markdown example
//
//  ## Example 1
//
//  the block below will be executed as it is, but won't yield any output
//  " | print
//      print "```nu"
//      print ("let $var1 = 'foo'" | nu-highlight)
//
//      print "```\n```output-numd"
//
//  let $var1 = 'foo'
//
//      print "```"
//
//  "
//  ## Example 2
//  " | print
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
//  "
//  ## Example 3
//  " | print
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

let $nu_res_stdout_lines = run-intermid-script $intermid_script_path $no_fail_on_error false
rm $intermid_script_path
$nu_res_stdout_lines
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
//  ```output-numd
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
//
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
//
//  ```
```

```nu indent-output
let $md_res = $nu_res_stdout_lines
    | str join (char nl)
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
//  │ levenshtein_dist │ 1                  │
//  │ diff_lines       │ -1 (-3.2%)         │
//  │ diff_words       │ 0%                 │
//  │ diff_chars       │ -1 (-0.3%)         │
//  ╰──────────────────┴────────────────────╯
```
