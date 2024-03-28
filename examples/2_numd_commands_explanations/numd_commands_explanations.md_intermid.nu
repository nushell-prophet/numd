# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd
cd /Users/user/git/nudoc
print "###numd-block-1"
print "```nu"
print ("$env.config.table.abbreviated_row_count = 100

# I source run here to export it's internal commands
source ('numd' | path join run1.nu)
let $file = ('examples' | path join 1_simple_markdown simple_markdown.md)
let $output_md_path = null
let $intermid_script_path = null
let $no_fail_on_error = false" | nu-highlight)
print '```
```numd-output'
$env.config.table.abbreviated_row_count = 100

# I source run here to export it's internal commands
source ('numd' | path join run1.nu)
let $file = ('examples' | path join 1_simple_markdown simple_markdown.md)
let $output_md_path = null
let $intermid_script_path = null
let $no_fail_on_error = false

print "###numd-block-4"
print "```nu"
print ("let $md_orig = open -r $file
let $md_orig_table = detect-code-chunks $md_orig
$md_orig_table | table | lines | each {$'//  ($in)' | str trim | str trim} | str join (char nl)" | nu-highlight)
print '```
```numd-output'
let $md_orig = open -r $file
let $md_orig_table = detect-code-chunks $md_orig
$md_orig_table | table | lines | each {$'//  ($in)' | str trim | str trim} | str join (char nl) | echo $in

print "###numd-block-9"
print "```nu"
print ("let $intermid_script_path = $intermid_script_path
        | default ( $nu.temp-path | path join $'numd-(tstamp).nu' )

gen-intermid-script $md_orig_table $intermid_script_path

open $intermid_script_path | lines | each {$'//  ($in)' | str trim} | str join (char nl)" | nu-highlight)
print '```
```numd-output'
let $intermid_script_path = $intermid_script_path
        | default ( $nu.temp-path | path join $'numd-(tstamp).nu' )

gen-intermid-script $md_orig_table $intermid_script_path

open $intermid_script_path | lines | each {$'//  ($in)' | str trim} | str join (char nl) | echo $in

print "###numd-block-14"
print "```nu"
print ("let $nu_res_stdout_lines = run-intermid-script $intermid_script_path $no_fail_on_error
$nu_res_stdout_lines | table | lines | each {$'//  ($in)' | str trim} | str join (char nl)" | nu-highlight)
print '```
```numd-output'
let $nu_res_stdout_lines = run-intermid-script $intermid_script_path $no_fail_on_error
$nu_res_stdout_lines | table | lines | each {$'//  ($in)' | str trim} | str join (char nl) | echo $in

print "###numd-block-19"
print "```nu"
print ("let $nu_res_with_block_index = parse-block-index $nu_res_stdout_lines
$nu_res_with_block_index | table | lines | each {$'//  ($in)' | str trim} | str join (char nl)" | nu-highlight)
print '```
```numd-output'
let $nu_res_with_block_index = parse-block-index $nu_res_stdout_lines
$nu_res_with_block_index | table | lines | each {$'//  ($in)' | str trim} | str join (char nl) | echo $in

print "###numd-block-24"
print "```nu"
print ("let $md_res = assemble-markdown $md_orig_table $nu_res_with_block_index
$md_res | lines | each {$'//  ($in)' | str trim} | str join (char nl)" | nu-highlight)
print '```
```numd-output'
let $md_res = assemble-markdown $md_orig_table $nu_res_with_block_index
$md_res | lines | each {$'//  ($in)' | str trim} | str join (char nl) | echo $in

print "###numd-block-28"
print "```nu"
print ("calc-changes 'simple_markdown.md' $md_orig $md_res" | nu-highlight)
print '```
```numd-output'
calc-changes 'simple_markdown.md' $md_orig $md_res | echo $in
