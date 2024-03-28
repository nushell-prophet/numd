# this script was generated automatically using nudoc
# https://github.com/nushell-prophet/nudoc
print "###nudoc-block-1"
print "```nu"
print ("$env.config.table.abbreviated_row_count = 100

# I source run here to export it's internal commands
source '/Users/user/git/nudoc/nudoc/run1.nu'
let $file = '/Users/user/git/nudoc/examples/1_simple_markdown/simple_markdown.md'
let $output_md_path = null
let $echo = false
let $no_backup = false
let $no_save = false
let $no_info = false
let $intermid_script_path = null
let $stop_on_error = false" | nu-highlight)
print '```
```nudoc-output'
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

print "###nudoc-block-4"
print "```nu"
print ("let $md_orig = open -r $file
let $md_orig_table = detect-code-chunks $md_orig
$md_orig_table | table | lines | each {$'//  ($in)'} | str join (char nl)" | nu-highlight)
print '```
```nudoc-output'
let $md_orig = open -r $file
let $md_orig_table = detect-code-chunks $md_orig
$md_orig_table | table | lines | each {$'//  ($in)'} | str join (char nl) | echo $in

print "###nudoc-block-9"
print "```nu"
print ("let $intermid_script_path = $intermid_script_path
        | default ( $nu.temp-path | path join $'nudoc-(tstamp).nu' )

gen-intermid-script $md_orig_table $intermid_script_path

open $intermid_script_path | lines | each {$'//  ($in)'} | str join (char nl)" | nu-highlight)
print '```
```nudoc-output'
let $intermid_script_path = $intermid_script_path
        | default ( $nu.temp-path | path join $'nudoc-(tstamp).nu' )

gen-intermid-script $md_orig_table $intermid_script_path

open $intermid_script_path | lines | each {$'//  ($in)'} | str join (char nl) | echo $in

print "###nudoc-block-14"
print "```nu"
print ("let $nu_res_stdout_lines = run-intermid-script $intermid_script_path $stop_on_error
$nu_res_stdout_lines | table | lines | each {$'//  ($in)'} | str join (char nl)" | nu-highlight)
print '```
```nudoc-output'
let $nu_res_stdout_lines = run-intermid-script $intermid_script_path $stop_on_error
$nu_res_stdout_lines | table | lines | each {$'//  ($in)'} | str join (char nl) | echo $in

print "###nudoc-block-19"
print "```nu"
print ("let $nu_res_with_block_index = parse-block-index $nu_res_stdout_lines
$nu_res_with_block_index | table | lines | each {$'//  ($in)'} | str join (char nl)" | nu-highlight)
print '```
```nudoc-output'
let $nu_res_with_block_index = parse-block-index $nu_res_stdout_lines
$nu_res_with_block_index | table | lines | each {$'//  ($in)'} | str join (char nl) | echo $in

print "###nudoc-block-24"
print "```nu"
print ("let $md_res = assemble-markdown $md_orig_table $nu_res_with_block_index
$md_res | lines | each {$'//  ($in)'} | str join (char nl)" | nu-highlight)
print '```
```nudoc-output'
let $md_res = assemble-markdown $md_orig_table $nu_res_with_block_index
$md_res | lines | each {$'//  ($in)'} | str join (char nl) | echo $in

print "###nudoc-block-27"
print "```nu"
print ("calc-changes 'in-nudoc-demo' $md_orig $md_res" | nu-highlight)
print '```
```nudoc-output'
calc-changes 'in-nudoc-demo' $md_orig $md_res | echo $in

print "###nudoc-block-31"
print "```nu"
print ("calc-changes 'in-nudoc-demo' 'abcd efg' 'abcd efgh'" | nu-highlight)
print '```
```nudoc-output'
calc-changes 'in-nudoc-demo' 'abcd efg' 'abcd efgh' | echo $in
