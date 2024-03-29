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
```numd-output
//  ╭──────────────────────────────────────────lines──────────────────────────────────────────┬───row_types────┬─block_index─╮
//  │ # This is a simple markdown example                                                     │                │           0 │
//  │                                                                                         │                │           0 │
//  │ ## Example 1                                                                            │                │           0 │
//  │                                                                                         │                │           0 │
//  │ the chunk below will be executed as it is, but won't yeld any output                    │                │           0 │
//  │                                                                                         │                │           0 │
//  │ ```nu                                                                                   │ ```nu          │           1 │
//  │ let $var1 = 'foo'                                                                       │ ```nu          │           1 │
//  │ ```                                                                                     │ ```            │           2 │
//  │                                                                                         │                │           3 │
//  │ ## Example 2                                                                            │                │           3 │
//  │                                                                                         │                │           3 │
//  │ ```nu                                                                                   │ ```nu          │           4 │
//  │ # This chunk will produce some output in the separate block                             │ ```nu          │           4 │
//  │ ls; # mind that this ls won't print in the markdown as it is used without `echo` or `>` │ ```nu          │           4 │
//  │ $var1 | path join 'baz' 'bar'                                                           │ ```nu          │           4 │
//  │ ```                                                                                     │ ```            │           5 │
//  │ ```numd-output                                                                          │ ```numd-output │           6 │
//  │ foo/baz/bar                                                                             │ ```numd-output │           6 │
//  │ ```                                                                                     │ ```            │           7 │
//  │                                                                                         │                │           8 │
//  │ ## Example 3                                                                            │                │           8 │
//  │                                                                                         │                │           8 │
//  │ ```nu                                                                                   │ ```nu          │           9 │
//  │ # This chunk will output results inline                                                 │ ```nu          │           9 │
//  │ > whoami                                                                                │ ```nu          │           9 │
//  │ user                                                                                    │ ```nu          │           9 │
//  │ > 2 + 2                                                                                 │ ```nu          │           9 │
//  │ 4                                                                                       │ ```nu          │           9 │
//  │ ```                                                                                     │ ```            │          10 │
//  ╰──────────────────────────────────────────lines──────────────────────────────────────────┴───row_types────┴─block_index─╯
```

```nu indent-output
let $intermid_script_path = $intermid_script_path
        | default ( $nu.temp-path | path join $'numd-(tstamp).nu' )

gen-intermid-script $md_orig_table $intermid_script_path

open $intermid_script_path
```
```numd-output
//  # this script was generated automatically using numd
//  # https://github.com/nushell-prophet/numd
//  cd /Users/user/git/nudoc
//  const init_numd_pwd_const = '/Users/user/git/nudoc'
//  print "###numd-block-1"
//  print "```nu"
//  print ("let $var1 = 'foo'" | nu-highlight)
//  print '```
//  ```numd-output'
//  let $var1 = 'foo'
//
//  print "```"
//  print "###numd-block-4"
//  print "```nu"
//  print ("# This chunk will produce some output in the separate block
//  ls; # mind that this ls won't print in the markdown as it is used without `echo` or `>`
//  $var1 | path join 'baz' 'bar'" | nu-highlight)
//  print '```
//  ```numd-output'
//  # This chunk will produce some output in the separate block
//  ls; # mind that this ls won't print in the markdown as it is used without `echo` or `>`
//  $var1 | path join 'baz' 'bar' | echo $in
//
//  print "```"
//  print "###numd-block-9"
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
```numd-output
//  ╭─────────────────────────────────────────────────────────────────────────────────────────╮
//  │ ###numd-block-1                                                                         │
//  │ ```nu                                                                                   │
//  │ let $var1 = 'foo'                                                                       │
//  │ ```                                                                                     │
//  │ ```numd-output                                                                          │
//  │ ```                                                                                     │
//  │ ###numd-block-4                                                                         │
//  │ ```nu                                                                                   │
//  │ # This chunk will produce some output in the separate block                             │
//  │ ls; # mind that this ls won't print in the markdown as it is used without `echo` or `>` │
//  │ $var1 | path join 'baz' 'bar'                                                           │
//  │ ```                                                                                     │
//  │ ```numd-output                                                                          │
//  │ foo/baz/bar                                                                             │
//  │ ```                                                                                     │
//  │ ###numd-block-9                                                                         │
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
```numd-output
//  ╭─block_index─┬──────────────────────────────────────────lines──────────────────────────────────────────╮
//  │           1 │ ```nu                                                                                   │
//  │             │ let $var1 = 'foo'                                                                       │
//  │             │ ```                                                                                     │
//  │             │ ```numd-output                                                                          │
//  │             │ ```                                                                                     │
//  │             │ ```                                                                                     │
//  │           4 │ ```nu                                                                                   │
//  │             │ # This chunk will produce some output in the separate block                             │
//  │             │ ls; # mind that this ls won't print in the markdown as it is used without `echo` or `>` │
//  │             │ $var1 | path join 'baz' 'bar'                                                           │
//  │             │ ```                                                                                     │
//  │             │ ```numd-output                                                                          │
//  │             │ foo/baz/bar                                                                             │
//  │             │ ```                                                                                     │
//  │             │ ```                                                                                     │
//  │           9 │ ```nu                                                                                   │
//  │             │ # This chunk will output results inline                                                 │
//  │             │ > whoami                                                                                │
//  │             │ user                                                                                    │
//  │             │ > 2 + 2                                                                                 │
//  │             │ 4                                                                                       │
//  │             │ ```                                                                                     │
//  │             │ ```                                                                                     │
//  ╰─block_index─┴──────────────────────────────────────────lines──────────────────────────────────────────╯
```

```nu indent-output
let $md_res = assemble-markdown $md_orig_table $nu_res_with_block_index
$md_res
```
```numd-output
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
//  ```numd-output
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
calc-changes 'simple_markdown.md' $md_orig $md_res
```
```numd-output
//  ╭────────────┬────────────────────╮
//  │ filename   │ simple_markdown.md │
//  │ lines      │ 0% from 30         │
//  │ words      │ 0% from 80         │
//  │ chars      │ 0% from 472        │
//  │ levenstein │ 0                  │
//  ╰────────────┴────────────────────╯
```
