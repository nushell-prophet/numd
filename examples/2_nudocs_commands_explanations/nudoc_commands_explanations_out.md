# Nudoc commands explanation

```nu
$env.config.table.abbreviated_row_count = 100

# I source run here to export it's internal commands
source '/Users/user/git/nudoc/nudoc/run1.nu'
let $file = '/Users/user/git/nudoc/examples/1_simple_markdown/simple_markdown.md'
let $output_md_path = null
let $echo = false
let $no_backup = false
let $no_save = false
let $no_info = false
let $intermid_script_path = null
let $stop_on_error = false
```

```nu
let $md_orig = open -r $file
let $md_orig_table = detect-code-chunks $md_orig
$md_orig_table | table | lines | each {$'//  ($in)'} | str join (char nl)
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
//  │ /Users/user/git/nudoc/nonsense                                                          │ ```nudoc-output │           6 │
//  │ ```                                                                                     │ ```             │           7 │
//  │                                                                                         │                 │           8 │
//  │ ## Example 3                                                                            │                 │           8 │
//  │                                                                                         │                 │           8 │
//  │ ```nu                                                                                   │ ```nu           │           9 │
//  │ # This chunk will write results into itself                                             │ ```nu           │           9 │
//  │ > whoami                                                                                │ ```nu           │           9 │
//  │ user                                                                                    │ ```nu           │           9 │
//  │ > date now                                                                              │ ```nu           │           9 │
//  │ Tue, 26 Mar 2024 13:57:15 +0000 (now)                                                   │ ```nu           │           9 │
//  │ ```                                                                                     │ ```             │          10 │
//  ╰──────────────────────────────────────────lines──────────────────────────────────────────┴────row_types────┴─block_index─╯
```

```nu
let $intermid_script_path = $intermid_script_path
        | default ( $nu.temp-path | path join $'nudoc-(tstamp).nu' )

gen-intermid-script $md_orig_table $intermid_script_path

open $intermid_script_path | lines | each {$'//  ($in)'} | str join (char nl)
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
//  print ("# This chunk will write results into itself" | nu-highlight)
//  
//  print ("> whoami" | nu-highlight)
//  whoami | echo $in
//  
//  print ("> date now" | nu-highlight)
//  date now | echo $in
```

```nu
let $nu_res_stdout_lines = run-intermid-script $intermid_script_path $stop_on_error
$nu_res_stdout_lines | table | lines | each {$'//  ($in)'} | str join (char nl)
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
//  │ # This chunk will write results into itself                                             │
//  │ > whoami                                                                                │
//  │ user                                                                                    │
//  │ > date now                                                                              │
//  │ Wed, 27 Mar 2024 13:59:38 +0000 (now)                                                   │
//  ╰─────────────────────────────────────────────────────────────────────────────────────────╯
```

```nu
let $nu_res_with_block_index = parse-block-index $nu_res_stdout_lines
$nu_res_with_block_index | table | lines | each {$'//  ($in)'} | str join (char nl)
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
//  │             │ # This chunk will write results into itself                                             │
//  │             │ > whoami                                                                                │
//  │             │ user                                                                                    │
//  │             │ > date now                                                                              │
//  │             │ Wed, 27 Mar 2024 13:59:38 +0000 (now)                                                   │
//  │             │ ```                                                                                     │
//  ╰─block_index─┴──────────────────────────────────────────lines──────────────────────────────────────────╯
```

```nu
let $md_res = assemble-markdown $md_orig_table $nu_res_with_block_index
$md_res | lines | each {$'//  ($in)'} | str join (char nl)
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
//  # This chunk will write results into itself
//  > whoami
//  user
//  > date now
//  Wed, 27 Mar 2024 13:59:38 +0000 (now)
//  ```
