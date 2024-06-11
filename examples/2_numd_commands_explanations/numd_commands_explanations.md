# numd commands explanation

In the code chunk below, we set settings and variables for executing this whole document.

```nu
$env.config.table.abbreviated_row_count = 100

# The `$init_numd_pwd_const` constant points to the current working directory from where the `numd` command was initiated.
# It is added by `numd` in every intermediate script to make it available in cases like below.
use ($init_numd_pwd_const | path join numd run1.nu) *
use ($init_numd_pwd_const | path join numd nu-utils numd-internals.nu) *

# The variables in this chunk are named according to the names of corresponding command options and flags.
let $file = ($init_numd_pwd_const | path join examples 1_simple_markdown simple_markdown.md)
let $output_md_path = null
let $intermid_script_path = null
let $no_fail_on_error = false
```

## numd-internals.nu

### detect-code-chunks

This command is used for parsing initial markdown to detect executable code chunks.

```nu indent-output
let $md_orig = open -r $file
let $md_orig_table = detect-code-chunks $md_orig
$md_orig_table
```
```output-numd
//  ╭─────────────────────────────────line─────────────────────────────────┬────row_type────┬─block_line_in_orig_md─╮
//  │ # This is a simple markdown example                                  │                │                     1 │
//  │                                                                      │                │                     1 │
//  │ ## Example 1                                                         │                │                     1 │
//  │                                                                      │                │                     1 │
//  │ the chunk below will be executed as it is, but won't yeld any output │                │                     1 │
//  │                                                                      │                │                     1 │
//  │ ```nu                                                                │ ```nu          │                     7 │
//  │ let $var1 = 'foo'                                                    │ ```nu          │                     7 │
//  │ ```                                                                  │ ```nu          │                     7 │
//  │                                                                      │                │                    10 │
//  │ ## Example 2                                                         │                │                    10 │
//  │                                                                      │                │                    10 │
//  │ ```nu                                                                │ ```nu          │                    13 │
//  │ # This chunk will produce some output in a separate block            │ ```nu          │                    13 │
//  │ $var1 | path join 'baz' 'bar'                                        │ ```nu          │                    13 │
//  │ ```                                                                  │ ```nu          │                    13 │
//  │ ```output-numd                                                       │ ```output-numd │                    17 │
//  │ foo/baz/bar                                                          │ ```output-numd │                    17 │
//  │ ```                                                                  │ ```output-numd │                    17 │
//  │                                                                      │                │                    20 │
//  │ ## Example 3                                                         │                │                    20 │
//  │                                                                      │                │                    20 │
//  │ ```nu                                                                │ ```nu          │                    23 │
//  │ # This chunk will output results inline                              │ ```nu          │                    23 │
//  │ > whoami                                                             │ ```nu          │                    23 │
//  │ user                                                                 │ ```nu          │                    23 │
//  │                                                                      │ ```nu          │                    23 │
//  │ > 2 + 2                                                              │ ```nu          │                    23 │
//  │ 4                                                                    │ ```nu          │                    23 │
//  │ ```                                                                  │ ```nu          │                    23 │
//  ╰─────────────────────────────────line─────────────────────────────────┴────row_type────┴─block_line_in_orig_md─╯
```

## gen-intermid-script

The `gen-intermid-script` command generates a script that contains code from all executable chunks and plus `numd` service commands.

```nu indent-output
let $intermid_script_path = $intermid_script_path
        | default ( $file
            | path-modify --prefix $'numd-temp-(tstamp)' --suffix '.nu' )

gen-intermid-script $md_orig_table
| save -f $intermid_script_path

open $intermid_script_path
```
```output-numd
//  # this script was generated automatically using numd
//  # https://github.com/nushell-prophet/numd
//  cd /Users/user/git/numd
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
//      print ("# This chunk will produce some output in a separate block
//  $var1 | path join 'baz' 'bar'" | nu-highlight)
//
//      print "```\n```output-numd"
//
//  # This chunk will produce some output in a separate block
//  $var1 | path join 'baz' 'bar' | print; print ''
//
//      print "```"
//
//      print "#code-block-starting-line-in-original-md-23"
//      print "```nu"
//      print ("# This chunk will output results inline" | nu-highlight)
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
let $nu_res_stdout_lines = run-intermid-script $intermid_script_path $no_fail_on_error
rm $intermid_script_path
$nu_res_stdout_lines
```
```output-numd
//  ╭───────────────────────────────────────────────────────────╮
//  │ #code-block-starting-line-in-original-md-7                │
//  │ ```nu                                                     │
//  │ let $var1 = 'foo'                                         │
//  │ ```                                                       │
//  │ ```output-numd                                            │
//  │ ```                                                       │
//  │ #code-block-starting-line-in-original-md-13               │
//  │ ```nu                                                     │
//  │ # This chunk will produce some output in a separate block │
//  │ $var1 | path join 'baz' 'bar'                             │
//  │ ```                                                       │
//  │ ```output-numd                                            │
//  │ foo/baz/bar                                               │
//  │                                                           │
//  │ ```                                                       │
//  │ #code-block-starting-line-in-original-md-23               │
//  │ ```nu                                                     │
//  │ # This chunk will output results inline                   │
//  │ > whoami                                                  │
//  │ user                                                      │
//  │                                                           │
//  │ > 2 + 2                                                   │
//  │ 4                                                         │
//  │                                                           │
//  │ ```                                                       │
//  ╰───────────────────────────────────────────────────────────╯
```

## parse-block-index

The `parse-block-index` command parses the captured output, and groups them by executed chunks.

```nu indent-output
let $nu_res_with_block_index = parse-block-index $nu_res_stdout_lines
$nu_res_with_block_index
```
```output-numd
//  ╭─block_line_in_orig_md─┬───────────────────────────line────────────────────────────╮
//  │                     7 │ ```nu                                                     │
//  │                       │ let $var1 = 'foo'                                         │
//  │                       │ ```                                                       │
//  │                       │ ```output-numd                                            │
//  │                       │ ```                                                       │
//  │                    13 │ ```nu                                                     │
//  │                       │ # This chunk will produce some output in a separate block │
//  │                       │ $var1 | path join 'baz' 'bar'                             │
//  │                       │ ```                                                       │
//  │                       │ ```output-numd                                            │
//  │                       │ foo/baz/bar                                               │
//  │                       │                                                           │
//  │                       │ ```                                                       │
//  │                    23 │ ```nu                                                     │
//  │                       │ # This chunk will output results inline                   │
//  │                       │ > whoami                                                  │
//  │                       │ user                                                      │
//  │                       │                                                           │
//  │                       │ > 2 + 2                                                   │
//  │                       │ 4                                                         │
//  │                       │                                                           │
//  │                       │ ```                                                       │
//  ╰─block_line_in_orig_md─┴───────────────────────────line────────────────────────────╯
```

## assemble-markdown

The `assemble-markdown` command cleans outdated commands outputs in the `$md_orig_table` and combines them with `$nu_res_with_block_index` (the variable from the previous step). Additionally, `prettify-markdown` is used here to remove empty blocks and unnecessary empty lines.

```nu indent-output
let $md_res = assemble-markdown $md_orig_table $nu_res_with_block_index
    | prettify-markdown

$md_res
```
```output-numd
//  # This is a simple markdown example
//
//  ## Example 1
//
//  the chunk below will be executed as it is, but won't yeld any output
//
//  ```nu
//  let $var1 = 'foo'
//  ```
//
//  ## Example 2
//
//  ```nu
//  # This chunk will produce some output in a separate block
//  $var1 | path join 'baz' 'bar'
//  ```
//  ```output-numd
//  foo/baz/bar
//  ```
//
//  ## Example 3
//
//  ```nu
//  # This chunk will output results inline
//  > whoami
//  user
//
//  > 2 + 2
//  4
//  ```
```

## calc-changes

The `calc-changes` command displays stats on the changes made.

```nu indent-output
calc-changes $file $md_orig $md_res
```
```output-numd
//  ╭────────────────┬────────────────────╮
//  │ filename       │ simple_markdown.md │
//  │ nu_code_blocks │ 3                  │
//  │ levenstein     │ 1                  │
//  │ diff_lines     │ 0%                 │
//  │ diff_words     │ 0%                 │
//  │ diff_chars     │ +1 (0.3%)          │
//  ╰────────────────┴────────────────────╯
```
