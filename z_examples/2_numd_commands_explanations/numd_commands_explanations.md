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

### find-code-blocks

This command is used for parsing initial markdown to detect executable code blocks.

```nu indent-output
# Here we set the `$file` variable (which will be used in several commands throughout this script) to point to `z_examples/1_simple_markdown/simple_markdown.md`.
let $file = $init_numd_pwd_const | path join z_examples 1_simple_markdown simple_markdown.md

let $md_orig = open -r $file | toggle-output-fences
let $md_orig_table = $md_orig | find-code-blocks
$md_orig_table
```

Output:

```
//  ╭─block_index─┬────row_type────┬──────line──────┬─────action─────╮
//  │           0 │ text           │ [list 6 items] │ print-as-it-is │
//  │           1 │ ```nu          │ [list 3 items] │ execute        │
//  │           2 │ text           │ [list 3 items] │ print-as-it-is │
//  │           3 │ ```nu          │ [list 4 items] │ execute        │
//  │           4 │ ```output-numd │ [list 3 items] │ delete         │
//  │           5 │ text           │ [list 3 items] │ print-as-it-is │
//  │           6 │ ```nu          │ [list 8 items] │ execute        │
//  ╰─block_index─┴────row_type────┴──────line──────┴─────action─────╯
```

## generate-intermediate-script

The `generate-intermediate-script` command generates a script that contains code from all executable blocks and `numd` service commands used for capturing outputs.

```nu indent-output
# Here we emulate that the `$intermed_script_path` options is not set
let $intermed_script_path = $file
    | modify-path --prefix $'numd-temp-(generate-timestamp)' --suffix '.nu'

generate-intermediate-script $md_orig_table
| save -f $intermed_script_path

open $intermed_script_path
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

let $nu_res_stdout_lines = execute-intermediate-script $intermed_script_path $no_fail_on_error false
rm $intermed_script_path
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
//  ```
//  #code-block-marker-open-6
//  ```nu
//  # This block will output results inline
//  > whoami
//  user
//
//  > 2 + 2
//  4
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
//  │ levenshtein_dist │ 155                │
//  │ diff_lines       │ -9 (-30%)          │
//  │ diff_words       │ -11 (-17.5%)       │
//  │ diff_chars       │ -74 (-19.3%)       │
//  ╰──────────────────┴────────────────────╯
```
