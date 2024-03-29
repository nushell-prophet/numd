# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd
cd /Users/user/git/nudoc
const init_numd_pwd_const = '/Users/user/git/nudoc'
print "###code-block-starting-line-in-original-md-3"
print "```nu"
print ("$env.config.table.abbreviated_row_count = 100

# I source run here to export it's internal commands
source ($init_numd_pwd_const | path join numd run1.nu)
let $file = ($init_numd_pwd_const | path join examples 1_simple_markdown simple_markdown.md)
let $output_md_path = null
let $intermid_script_path = null
let $no_fail_on_error = false" | nu-highlight)
print '```
```numd-output'
$env.config.table.abbreviated_row_count = 100

# I source run here to export it's internal commands
source ($init_numd_pwd_const | path join numd run1.nu)
let $file = ($init_numd_pwd_const | path join examples 1_simple_markdown simple_markdown.md)
let $output_md_path = null
let $intermid_script_path = null
let $no_fail_on_error = false

print "```"
print "###code-block-starting-line-in-original-md-14"
print "```nu indent-output"
print ("let $md_orig = open -r $file
let $md_orig_table = detect-code-chunks $md_orig
$md_orig_table" | nu-highlight)
print '```
```numd-output'
let $md_orig = open -r $file
let $md_orig_table = detect-code-chunks $md_orig
$md_orig_table | table | into string | lines | each {$'//  ($in)' | str trim} | str join (char nl) | echo $in

print "```"
print "###code-block-starting-line-in-original-md-54"
print "```nu indent-output"
print ("let $intermid_script_path = $intermid_script_path
        | default ( $nu.temp-path | path join $'numd-(tstamp).nu' )

gen-intermid-script $md_orig_table $intermid_script_path

open $intermid_script_path" | nu-highlight)
print '```
```numd-output'
let $intermid_script_path = $intermid_script_path
        | default ( $nu.temp-path | path join $'numd-(tstamp).nu' )

gen-intermid-script $md_orig_table $intermid_script_path

open $intermid_script_path | table | into string | lines | each {$'//  ($in)' | str trim} | str join (char nl) | echo $in

print "```"
print "###code-block-starting-line-in-original-md-100"
print "```nu indent-output"
print ("let $nu_res_stdout_lines = run-intermid-script $intermid_script_path $no_fail_on_error
$nu_res_stdout_lines" | nu-highlight)
print '```
```numd-output'
let $nu_res_stdout_lines = run-intermid-script $intermid_script_path $no_fail_on_error
$nu_res_stdout_lines | table | into string | lines | each {$'//  ($in)' | str trim} | str join (char nl) | echo $in

print "```"
print "###code-block-starting-line-in-original-md-132"
print "```nu indent-output"
print ("let $nu_res_with_block_index = parse-block-index $nu_res_stdout_lines
$nu_res_with_block_index" | nu-highlight)
print '```
```numd-output'
let $nu_res_with_block_index = parse-block-index $nu_res_stdout_lines
$nu_res_with_block_index | table | into string | lines | each {$'//  ($in)' | str trim} | str join (char nl) | echo $in

print "```"
print "###code-block-starting-line-in-original-md-164"
print "```nu indent-output"
print ("let $md_res = assemble-markdown $md_orig_table $nu_res_with_block_index
$md_res" | nu-highlight)
print '```
```numd-output'
let $md_res = assemble-markdown $md_orig_table $nu_res_with_block_index
$md_res | table | into string | lines | each {$'//  ($in)' | str trim} | str join (char nl) | echo $in

print "```"
print "###code-block-starting-line-in-original-md-200"
print "```nu indent-output"
print ("calc-changes 'simple_markdown.md' $md_orig $md_res" | nu-highlight)
print '```
```numd-output'
calc-changes 'simple_markdown.md' $md_orig $md_res | table | into string | lines | each {$'//  ($in)' | str trim} | str join (char nl) | echo $in

print "```"