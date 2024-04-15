# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd
cd /Users/user/git/numd
const init_numd_pwd_const = '/Users/user/git/numd'
print "###code-block-starting-line-in-original-md-3"
print "```nu"
print ("$env.config.table.abbreviated_row_count = 100

# I source run here to export it's internal commands
use ($init_numd_pwd_const | path join numd run1.nu) *
use ($init_numd_pwd_const | path join numd nu-utils numd-internals.nu) *
let $file = ($init_numd_pwd_const | path join examples 1_simple_markdown simple_markdown.md)
let $output_md_path = null
let $intermid_script_path = null
let $no_fail_on_error = false" | nu-highlight)
print '```
```output-numd'
$env.config.table.abbreviated_row_count = 100

# I source run here to export it's internal commands
use ($init_numd_pwd_const | path join numd run1.nu) *
use ($init_numd_pwd_const | path join numd nu-utils numd-internals.nu) *
let $file = ($init_numd_pwd_const | path join examples 1_simple_markdown simple_markdown.md)
let $output_md_path = null
let $intermid_script_path = null
let $no_fail_on_error = false

print "```"
print "###code-block-starting-line-in-original-md-15"
print "```nu indent-output"
print ("let $md_orig = open -r $file
let $md_orig_table = detect-code-chunks $md_orig
$md_orig_table" | nu-highlight)
print '```
```output-numd'
let $md_orig = open -r $file
let $md_orig_table = detect-code-chunks $md_orig
$md_orig_table | table | into string | lines | each {$'//  ($in)' | str trim} | str join (char nl) | print

print "```"
print "###code-block-starting-line-in-original-md-55"
print "```nu indent-output"
print ("let $intermid_script_path = $intermid_script_path
        | default ( $file
            | path-modify --prefix $'numd-temp-(tstamp)' --suffix '.nu' )

gen-intermid-script $md_orig_table
| save -f $intermid_script_path

open $intermid_script_path" | nu-highlight)
print '```
```output-numd'
let $intermid_script_path = $intermid_script_path
        | default ( $file
            | path-modify --prefix $'numd-temp-(tstamp)' --suffix '.nu' )

gen-intermid-script $md_orig_table
| save -f $intermid_script_path

open $intermid_script_path | table | into string | lines | each {$'//  ($in)' | str trim} | str join (char nl) | print

print "```"
print "###code-block-starting-line-in-original-md-103"
print "```nu indent-output"
print ("let $nu_res_stdout_lines = run-intermid-script $intermid_script_path $no_fail_on_error
rm $intermid_script_path
$nu_res_stdout_lines" | nu-highlight)
print '```
```output-numd'
let $nu_res_stdout_lines = run-intermid-script $intermid_script_path $no_fail_on_error
rm $intermid_script_path
$nu_res_stdout_lines | table | into string | lines | each {$'//  ($in)' | str trim} | str join (char nl) | print

print "```"
print "###code-block-starting-line-in-original-md-136"
print "```nu indent-output"
print ("let $nu_res_with_block_index = parse-block-index $nu_res_stdout_lines
$nu_res_with_block_index" | nu-highlight)
print '```
```output-numd'
let $nu_res_with_block_index = parse-block-index $nu_res_stdout_lines
$nu_res_with_block_index | table | into string | lines | each {$'//  ($in)' | str trim} | str join (char nl) | print

print "```"
print "###code-block-starting-line-in-original-md-165"
print "```nu indent-output"
print ("let $md_res = assemble-markdown $md_orig_table $nu_res_with_block_index
    | prettify-markdown

$md_res" | nu-highlight)
print '```
```output-numd'
let $md_res = assemble-markdown $md_orig_table $nu_res_with_block_index
    | prettify-markdown

$md_res | table | into string | lines | each {$'//  ($in)' | str trim} | str join (char nl) | print

print "```"
print "###code-block-starting-line-in-original-md-204"
print "```nu indent-output"
print ("calc-changes $file $md_orig $md_res" | nu-highlight)
print '```
```output-numd'
calc-changes $file $md_orig $md_res | table | into string | lines | each {$'//  ($in)' | str trim} | str join (char nl) | print

print "```"