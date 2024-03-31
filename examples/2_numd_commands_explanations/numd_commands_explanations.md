# numd commands explanation

```nu
$env.config.table.abbreviated_row_count = 100

# I source run here to export it's internal commands
source ($init_numd_pwd_const | path join numd run1.nu)
let $file = ($init_numd_pwd_const | path join examples 1_simple_markdown simple_markdown.md)
let $output_md_path = null
let $intermid_script_path = null
let $no_fail_on_error = false
```

```nu indent-output
let $md_orig = open -r $file
let $md_orig_table = detect-code-chunks $md_orig
$md_orig_table
```
```output-numd
//  ╭──────────────────────────────────────────line───────────────────────────────────────────┬────row_type────┬─block_line_in_orig_md─╮
//  │ # This is a simple markdown example                                                     │                │                     1 │
//  │                                                                                         │                │                     1 │
//  │ ## Example 1                                                                            │                │                     1 │
//  │                                                                                         │                │                     1 │
//  │ the chunk below will be executed as it is, but won't yeld any output                    │                │                     1 │
//  │                                                                                         │                │                     1 │
//  │ ```nu                                                                                   │ ```nu          │                     7 │
//  │ let $var1 = 'foo'                                                                       │ ```nu          │                     7 │
//  │ ```                                                                                     │ ```nu          │                     7 │
//  │                                                                                         │                │                    10 │
//  │ ## Example 2                                                                            │                │                    10 │
//  │                                                                                         │                │                    10 │
//  │ ```nu                                                                                   │ ```nu          │                    13 │
//  │ # This chunk will produce some output in the separate block                             │ ```nu          │                    13 │
//  │ ls; # mind that this ls won't print in the markdown as it is used without `echo` or `>` │ ```nu          │                    13 │
//  │ $var1 | path join 'baz' 'bar'                                                           │ ```nu          │                    13 │
//  │ ```                                                                                     │ ```nu          │                    13 │
//  │ ```output-numd                                                                          │ ```output-numd │                    18 │
//  │ foo/baz/bar                                                                             │ ```output-numd │                    18 │
//  │ ```                                                                                     │ ```output-numd │                    18 │
//  │                                                                                         │                │                    21 │
//  │ ## Example 3                                                                            │                │                    21 │
//  │                                                                                         │                │                    21 │
//  │ ```nu                                                                                   │ ```nu          │                    24 │
//  │ # This chunk will output results inline                                                 │ ```nu          │                    24 │
//  │ > whoami                                                                                │ ```nu          │                    24 │
//  │ user                                                                                    │ ```nu          │                    24 │
//  │ > 2 + 2                                                                                 │ ```nu          │                    24 │
//  │ 4                                                                                       │ ```nu          │                    24 │
//  │ ```                                                                                     │ ```nu          │                    24 │
//  ╰──────────────────────────────────────────line───────────────────────────────────────────┴────row_type────┴─block_line_in_orig_md─╯
```

```nu indent-output
let $intermid_script_path = $intermid_script_path
        | default ( $nu.temp-path | path join $'numd-(tstamp).nu' )

gen-intermid-script $md_orig_table $intermid_script_path

open $intermid_script_path
```
```output-numd
//  # this script was generated automatically using numd
//  # https://github.com/nushell-prophet/numd
//  cd /Users/user/git/numd
//  const init_numd_pwd_const = '/Users/user/git/numd'
//  print "###code-block-starting-line-in-original-md-7"
//  print "```nu"
//  print ("let $var1 = 'foo'" | nu-highlight)
//  print '```
//  ```output-numd'
//  let $var1 = 'foo'
//
//  print "```"
//  print "###code-block-starting-line-in-original-md-13"
//  print "```nu"
//  print ("# This chunk will produce some output in the separate block
//  ls; # mind that this ls won't print in the markdown as it is used without `echo` or `>`
//  $var1 | path join 'baz' 'bar'" | nu-highlight)
//  print '```
//  ```output-numd'
//  # This chunk will produce some output in the separate block
//  ls; # mind that this ls won't print in the markdown as it is used without `echo` or `>`
//  $var1 | path join 'baz' 'bar' | echo $in
//
//  print "```"
//  print "###code-block-starting-line-in-original-md-24"
//  print "```nu"
//  print ("# This chunk will output results inline" | nu-highlight)
//
//  print ("> whoami" | nu-highlight)
//  whoami | echo $in
//
//  print ("> 2 + 2" | nu-highlight)
//  2 + 2 | echo $in
//
//  print "```"
```

```nu indent-output
let $nu_res_stdout_lines = run-intermid-script $intermid_script_path $no_fail_on_error
$nu_res_stdout_lines
```
```output-numd
//  ╭─────────────────────────────────────────────────────────────────────────────────────────╮
//  │ ###code-block-starting-line-in-original-md-7                                            │
//  │ ```nu                                                                                   │
//  │ let $var1 = 'foo'                                                                       │
//  │ ```                                                                                     │
//  │ ```output-numd                                                                          │
//  │ ```                                                                                     │
//  │ ###code-block-starting-line-in-original-md-13                                           │
//  │ ```nu                                                                                   │
//  │ # This chunk will produce some output in the separate block                             │
//  │ ls; # mind that this ls won't print in the markdown as it is used without `echo` or `>` │
//  │ $var1 | path join 'baz' 'bar'                                                           │
//  │ ```                                                                                     │
//  │ ```output-numd                                                                          │
//  │ foo/baz/bar                                                                             │
//  │ ```                                                                                     │
//  │ ###code-block-starting-line-in-original-md-24                                           │
//  │ ```nu                                                                                   │
//  │ # This chunk will output results inline                                                 │
//  │ > whoami                                                                                │
//  │ user                                                                                    │
//  │ > 2 + 2                                                                                 │
//  │ 4                                                                                       │
//  │ ```                                                                                     │
//  ╰─────────────────────────────────────────────────────────────────────────────────────────╯
```

```nu indent-output
let $nu_res_with_block_index = parse-block-index $nu_res_stdout_lines
$nu_res_with_block_index
```
```output-numd
//  ╭─block_line_in_orig_md─┬──────────────────────────────────────────line───────────────────────────────────────────╮
//  │                     7 │ ```nu                                                                                   │
//  │                       │ let $var1 = 'foo'                                                                       │
//  │                       │ ```                                                                                     │
//  │                       │ ```output-numd                                                                          │
//  │                       │ ```                                                                                     │
//  │                    13 │ ```nu                                                                                   │
//  │                       │ # This chunk will produce some output in the separate block                             │
//  │                       │ ls; # mind that this ls won't print in the markdown as it is used without `echo` or `>` │
//  │                       │ $var1 | path join 'baz' 'bar'                                                           │
//  │                       │ ```                                                                                     │
//  │                       │ ```output-numd                                                                          │
//  │                       │ foo/baz/bar                                                                             │
//  │                       │ ```                                                                                     │
//  │                    24 │ ```nu                                                                                   │
//  │                       │ # This chunk will output results inline                                                 │
//  │                       │ > whoami                                                                                │
//  │                       │ user                                                                                    │
//  │                       │ > 2 + 2                                                                                 │
//  │                       │ 4                                                                                       │
//  │                       │ ```                                                                                     │
//  ╰─block_line_in_orig_md─┴──────────────────────────────────────────line───────────────────────────────────────────╯
```

```nu indent-output
let $md_res = assemble-markdown $md_orig_table $nu_res_with_block_index
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
//  # This chunk will produce some output in the separate block
//  ls; # mind that this ls won't print in the markdown as it is used without `echo` or `>`
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
//  > 2 + 2
//  4
//  ```
```

```nu indent-output
calc-changes $file $md_orig $md_res
```
```output-numd
//  ╭────────────┬────────────────────╮
//  │ filename   │ simple_markdown.md │
//  │ lines      │ 0% from 30         │
//  │ words      │ 0% from 80         │
//  │ chars      │ 0% from 472        │
//  │ levenstein │ 0                  │
//  ╰────────────┴────────────────────╯
```
