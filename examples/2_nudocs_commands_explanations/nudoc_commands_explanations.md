# Nudoc commands explanation

```nu
$env.config.table.abbreviated_row_count = 100

# I source run here to export it's internal commands
source ('nudoc' | path join run1.nu)
let $file = ('examples' | path join 1_simple_markdown simple_markdown.md)
let $output_md_path = null
let $intermid_script_path = null
let $no_fail_on_error = false
```

```nu
let $md_orig = open -r $file
let $md_orig_table = detect-code-chunks $md_orig
$md_orig_table | table | lines | each {$'//  ($in)' | str trim | str trim} | str join (char nl)
```
```nudoc-output
//  ╭──────────────────────────────────────────lines──────────────────────────────────────────┬────row_types────┬─block_index─╮
//  │ # This is a simple markdown example                                                     │                 │           0 │
//  │                                                                                         │                 │           0 │
//  │ ## Example 1                                                                            │                 │           0 │
//  │                                                                                         │                 │           0 │
//  │ the chunk below will be executed as it is, but won't yeld any output                    │                 │           0 │
//  │                                                                                         │                 │           0 │
//  │ ```nu                                                                                   │ ```nu           │           1 │
//  │ let $var1 = 'foo'                                                                       │ ```nu           │           1 │
//  │ ```                                                                                     │ ```             │           2 │
//  │                                                                                         │                 │           3 │
//  │ ## Example 2                                                                            │                 │           3 │
//  │                                                                                         │                 │           3 │
//  │ ```nu                                                                                   │ ```nu           │           4 │
//  │ # This chunk will produce some output in the separate block                             │ ```nu           │           4 │
//  │ ls; # mind that this ls won't print in the markdown as it is used without `echo` or `>` │ ```nu           │           4 │
//  │ $var1 | path join 'baz' 'bar'                                                           │ ```nu           │           4 │
//  │ ```                                                                                     │ ```             │           5 │
//  │ ```nudoc-output                                                                         │ ```nudoc-output │           6 │
//  │ foo/baz/bar                                                                             │ ```nudoc-output │           6 │
//  │ ```                                                                                     │ ```             │           7 │
//  │                                                                                         │                 │           8 │
//  │ ## Example 3                                                                            │                 │           8 │
//  │                                                                                         │                 │           8 │
//  │ ```nu                                                                                   │ ```nu           │           9 │
//  │ # This chunk will output results inline                                                 │ ```nu           │           9 │
//  │ > whoami                                                                                │ ```nu           │           9 │
//  │ user                                                                                    │ ```nu           │           9 │
//  │ > date now                                                                              │ ```nu           │           9 │
//  │ Thu, 28 Mar 2024 04:18:53 +0000 (now)                                                   │ ```nu           │           9 │
//  │ ```                                                                                     │ ```             │          10 │
//  ╰──────────────────────────────────────────lines──────────────────────────────────────────┴────row_types────┴─block_index─╯
```

```nu
let $intermid_script_path = $intermid_script_path
        | default ( $nu.temp-path | path join $'nudoc-(tstamp).nu' )

gen-intermid-script $md_orig_table $intermid_script_path

open $intermid_script_path | lines | each {$'//  ($in)' | str trim} | str join (char nl)
```
```nudoc-output
//  # this script was generated automatically using nudoc
//  # https://github.com/nushell-prophet/nudoc
//  print "###nudoc-block-1"
//  print "```nu"
//  print ("let $var1 = 'foo'" | nu-highlight)
//  print '```
//  ```nudoc-output'
//  let $var1 = 'foo'
//
//  print "###nudoc-block-4"
//  print "```nu"
//  print ("# This chunk will produce some output in the separate block
//  ls; # mind that this ls won't print in the markdown as it is used without `echo` or `>`
//  $var1 | path join 'baz' 'bar'" | nu-highlight)
//  print '```
//  ```nudoc-output'
//  # This chunk will produce some output in the separate block
//  ls; # mind that this ls won't print in the markdown as it is used without `echo` or `>`
//  $var1 | path join 'baz' 'bar' | echo $in
//
//  print "###nudoc-block-9"
//  print "```nu"
//  print ("# This chunk will output results inline" | nu-highlight)
//
//  print ("> whoami" | nu-highlight)
//  whoami | echo $in
//
//  print ("> date now" | nu-highlight)
//  date now | echo $in
```

```nu
let $nu_res_stdout_lines = run-intermid-script $intermid_script_path $no_fail_on_error
$nu_res_stdout_lines | table | lines | each {$'//  ($in)' | str trim} | str join (char nl)
```
```nudoc-output
//  ╭─────────────────────────────────────────────────────────────────────────────────────────╮
//  │ ###nudoc-block-1                                                                        │
//  │ ```nu                                                                                   │
//  │ let $var1 = 'foo'                                                                       │
//  │ ```                                                                                     │
//  │ ```nudoc-output                                                                         │
//  │ ###nudoc-block-4                                                                        │
//  │ ```nu                                                                                   │
//  │ # This chunk will produce some output in the separate block                             │
//  │ ls; # mind that this ls won't print in the markdown as it is used without `echo` or `>` │
//  │ $var1 | path join 'baz' 'bar'                                                           │
//  │ ```                                                                                     │
//  │ ```nudoc-output                                                                         │
//  │ foo/baz/bar                                                                             │
//  │ ###nudoc-block-9                                                                        │
//  │ ```nu                                                                                   │
//  │ # This chunk will output results inline                                                 │
//  │ > whoami                                                                                │
//  │ user                                                                                    │
//  │ > date now                                                                              │
//  │ Thu, 28 Mar 2024 04:18:54 +0000 (now)                                                   │
//  ╰─────────────────────────────────────────────────────────────────────────────────────────╯
```

```nu
let $nu_res_with_block_index = parse-block-index $nu_res_stdout_lines
$nu_res_with_block_index | table | lines | each {$'//  ($in)' | str trim} | str join (char nl)
```
```nudoc-output
//  ╭─block_index─┬──────────────────────────────────────────lines──────────────────────────────────────────╮
//  │           1 │ ```nu                                                                                   │
//  │             │ let $var1 = 'foo'                                                                       │
//  │             │ ```                                                                                     │
//  │             │ ```nudoc-output                                                                         │
//  │             │ ```                                                                                     │
//  │           4 │ ```nu                                                                                   │
//  │             │ # This chunk will produce some output in the separate block                             │
//  │             │ ls; # mind that this ls won't print in the markdown as it is used without `echo` or `>` │
//  │             │ $var1 | path join 'baz' 'bar'                                                           │
//  │             │ ```                                                                                     │
//  │             │ ```nudoc-output                                                                         │
//  │             │ foo/baz/bar                                                                             │
//  │             │ ```                                                                                     │
//  │           9 │ ```nu                                                                                   │
//  │             │ # This chunk will output results inline                                                 │
//  │             │ > whoami                                                                                │
//  │             │ user                                                                                    │
//  │             │ > date now                                                                              │
//  │             │ Thu, 28 Mar 2024 04:18:54 +0000 (now)                                                   │
//  │             │ ```                                                                                     │
//  ╰─block_index─┴──────────────────────────────────────────lines──────────────────────────────────────────╯
```

```nu
let $md_res = assemble-markdown $md_orig_table $nu_res_with_block_index
$md_res | lines | each {$'//  ($in)' | str trim} | str join (char nl)
```
```nudoc-output
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
//  ```nudoc-output
//  foo/baz/bar
//  ```
//
//  ## Example 3
//
//  ```nu
//  # This chunk will output results inline
//  > whoami
//  user
//  > date now
//  Thu, 28 Mar 2024 04:18:54 +0000 (now)
//  ```
```nu
calc-changes 'simple_markdown.md' $md_orig $md_res
```
```nudoc-output
╭────────────┬────────────────────╮
│ filename   │ simple_markdown.md │
│ lines      │ 0% from 30         │
│ words      │ +21.6% from 88     │
│ chars      │ +27.3% from 512    │
│ levenstein │ 141                │
╰────────────┴────────────────────╯
```
