# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd
cd /Users/user/git/numd
const init_numd_pwd_const = '/Users/user/git/numd'
    print "#code-block-starting-line-in-original-md-5"
    print "```nu"
    print ("$env.config.table.abbreviated_row_count = 100

# The `$init_numd_pwd_const` constant points to the current working directory from where the `numd` command was initiated.
# It is added by `numd` in every intermediate script to make it available in cases like below.
use ($init_numd_pwd_const | path join numd run1.nu) *
use ($init_numd_pwd_const | path join numd nu-utils numd-internals.nu) *

# The variables in this block are named according to the names of corresponding command options and flags.
let $file = ($init_numd_pwd_const | path join examples 1_simple_markdown simple_markdown.md)
let $output_md_path = null
let $intermid_script_path = null
let $no_fail_on_error = false" | nu-highlight)

    print "```\n```output-numd"

$env.config.table.abbreviated_row_count = 100

# The `$init_numd_pwd_const` constant points to the current working directory from where the `numd` command was initiated.
# It is added by `numd` in every intermediate script to make it available in cases like below.
use ($init_numd_pwd_const | path join numd run1.nu) *
use ($init_numd_pwd_const | path join numd nu-utils numd-internals.nu) *

# The variables in this block are named according to the names of corresponding command options and flags.
let $file = ($init_numd_pwd_const | path join examples 1_simple_markdown simple_markdown.md)
let $output_md_path = null
let $intermid_script_path = null
let $no_fail_on_error = false

    print "```"

    print "#code-block-starting-line-in-original-md-26"
    print "```nu indent-output"
    print ("let $md_orig = open -r $file
let $md_orig_table = detect-code-blocks $md_orig
$md_orig_table" | nu-highlight)

    print "```\n```output-numd"

let $md_orig = open -r $file
let $md_orig_table = detect-code-blocks $md_orig
$md_orig_table | table | into string | lines | each {$'//  ($in)' | str trim} | str join (char nl) | print; print ''

    print "```"

    print "#code-block-starting-line-in-original-md-70"
    print "```nu indent-output"
    print ("let $intermid_script_path = $intermid_script_path
        | default ( $file
            | path-modify --prefix $'numd-temp-(tstamp)' --suffix '.nu' )

gen-intermid-script $md_orig_table
| save -f $intermid_script_path

open $intermid_script_path" | nu-highlight)

    print "```\n```output-numd"

let $intermid_script_path = $intermid_script_path
        | default ( $file
            | path-modify --prefix $'numd-temp-(tstamp)' --suffix '.nu' )

gen-intermid-script $md_orig_table
| save -f $intermid_script_path

open $intermid_script_path | table | into string | lines | each {$'//  ($in)' | str trim} | str join (char nl) | print; print ''

    print "```"

    print "#code-block-starting-line-in-original-md-127"
    print "```nu indent-output"
    print ("let $nu_res_stdout_lines = run-intermid-script $intermid_script_path $no_fail_on_error
rm $intermid_script_path
$nu_res_stdout_lines" | nu-highlight)

    print "```\n```output-numd"

let $nu_res_stdout_lines = run-intermid-script $intermid_script_path $no_fail_on_error
rm $intermid_script_path
$nu_res_stdout_lines | table | into string | lines | each {$'//  ($in)' | str trim} | str join (char nl) | print; print ''

    print "```"

    print "#code-block-starting-line-in-original-md-166"
    print "```nu indent-output"
    print ("let $nu_res_with_block_index = parse-block-index $nu_res_stdout_lines
$nu_res_with_block_index" | nu-highlight)

    print "```\n```output-numd"

let $nu_res_with_block_index = parse-block-index $nu_res_stdout_lines
$nu_res_with_block_index | table | into string | lines | each {$'//  ($in)' | str trim} | str join (char nl) | print; print ''

    print "```"

    print "#code-block-starting-line-in-original-md-201"
    print "```nu indent-output"
    print ("let $md_res = assemble-markdown $md_orig_table $nu_res_with_block_index
    | prettify-markdown

$md_res" | nu-highlight)

    print "```\n```output-numd"

let $md_res = assemble-markdown $md_orig_table $nu_res_with_block_index
    | prettify-markdown

$md_res | table | into string | lines | each {$'//  ($in)' | str trim} | str join (char nl) | print; print ''

    print "```"

    print "#code-block-starting-line-in-original-md-244"
    print "```nu indent-output"
    print ("calc-changes $file $md_orig $md_res" | nu-highlight)

    print "```\n```output-numd"

calc-changes $file $md_orig $md_res | table | into string | lines | each {$'//  ($in)' | str trim} | str join (char nl) | print; print ''

    print "```"
