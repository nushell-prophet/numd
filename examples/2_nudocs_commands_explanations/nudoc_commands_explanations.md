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
╭──────────────────────────────────────────lines──────────────────────────────────────────┬────row_types────┬─block_index─╮
│ # This is a simple markdown example                                                     │                 │           0 │
│                                                                                         │                 │           0 │
│ ## Example 1                                                                            │                 │           0 │
│                                                                                         │                 │           0 │
│ the chunk below will be executed as it is, but won't yeld any output                    │                 │           0 │
│                                                                                         │                 │           0 │
│ ```nu                                                                                   │ ```nu           │           1 │
│ let $var1 = pwd                                                                         │ ```nu           │           1 │
│ ```                                                                                     │ ```             │           2 │
│                                                                                         │                 │           3 │
│ ## Example 2                                                                            │                 │           3 │
│                                                                                         │                 │           3 │
│ ```nu                                                                                   │ ```nu           │           4 │
│ # This chunk will produce some output in the separate block                             │ ```nu           │           4 │
│ ls; # mind that this ls won't print in the markdown as it is used without `echo` or `>` │ ```nu           │           4 │
│ $var1 | path join 'nonsense'                                                            │ ```nu           │           4 │
│ ```                                                                                     │ ```             │           5 │
│ ```nudoc-output                                                                         │ ```nudoc-output │           6 │
│ /Users/user/git/nudoc/nonsense                                                          │ ```nudoc-output │           6 │
│ ```                                                                                     │ ```             │           7 │
│                                                                                         │                 │           8 │
│ ## Example 3                                                                            │                 │           8 │
│                                                                                         │                 │           8 │
│ ```nu                                                                                   │ ```nu           │           9 │
│ # This chunk will write results into itself                                             │ ```nu           │           9 │
│ > whoami                                                                                │ ```nu           │           9 │
│ user                                                                                    │ ```nu           │           9 │
│ > date now                                                                              │ ```nu           │           9 │
│ Tue, 26 Mar 2024 13:57:15 +0000 (now)                                                   │ ```nu           │           9 │
│ ```                                                                                     │ ```             │          10 │
╰──────────────────────────────────────────lines──────────────────────────────────────────┴────row_types────┴─block_index─╯
```

```nu
let $intermid_script_path = $intermid_script_path
        | default ( $nu.temp-path | path join $'nudoc-(tstamp).nu' )

gen-intermid-script $md_orig_table $intermid_script_path

open $intermid_script_path | lines | each {$'//  ($in)'} | str join (char nl)
```

```nu
let $nu_res_stdout_lines = run-intermid-script $intermid_script_path $stop_on_error
$nu_res_stdout_lines | table | lines | each {$'//  ($in)'} | str join (char nl)
```


```nu
let $nu_res_with_block_index = parse-block-index $nu_res_stdout_lines
$nu_res_with_block_index | table | lines | each {$'//  ($in)'} | str join (char nl)
```

```nu
let $md_res = assemble-markdown $md_orig_table $nu_res_with_block_index
$md_res | lines | each {$'//  ($in)'} | str join (char nl)
```
