# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd
const init_numd_pwd_const = '/Users/user/git/numd'
    print "#code-block-starting-line-in-original-md-5"
    print "```nu"
    print ("# This setting is for overriding the author's usual small number of `abbreviated_row_count`.
$env.config.table.abbreviated_row_count = 100

# The `$init_numd_pwd_const` constant points to the current working directory from where the `numd` command was initiated.
# It is added by `numd` in every intermediate script to make it available in cases like below.
# We use `path join` here to construct working paths for both Windows and Unix
use ($init_numd_pwd_const | path join numd run1.nu) *
use ($init_numd_pwd_const | path join numd nu-utils numd-internals.nu) *" | nu-highlight)

    print "```\n```output-numd"

# This setting is for overriding the author's usual small number of `abbreviated_row_count`.
$env.config.table.abbreviated_row_count = 100

# The `$init_numd_pwd_const` constant points to the current working directory from where the `numd` command was initiated.
# It is added by `numd` in every intermediate script to make it available in cases like below.
# We use `path join` here to construct working paths for both Windows and Unix
use ($init_numd_pwd_const | path join numd run1.nu) *
use ($init_numd_pwd_const | path join numd nu-utils numd-internals.nu) *

    print "```"

    print "#code-block-starting-line-in-original-md-22"
    print "```nu indent-output"
    print ("# Here we set the `$file` variable (which will be used in several commands throughout this script) to point to `examples/1_simple_markdown/simple_markdown.md`.
let $file = $init_numd_pwd_const | path join examples 1_simple_markdown simple_markdown.md

let $md_orig = open -r $file | replace-output-numd-fences
let $md_orig_table = $md_orig | detect-code-blocks
$md_orig_table" | nu-highlight)

    print "```\n```output-numd"

# Here we set the `$file` variable (which will be used in several commands throughout this script) to point to `examples/1_simple_markdown/simple_markdown.md`.
let $file = $init_numd_pwd_const | path join examples 1_simple_markdown simple_markdown.md

let $md_orig = open -r $file | replace-output-numd-fences
let $md_orig_table = $md_orig | detect-code-blocks
$md_orig_table | table | into string | lines | each {$'//  ($in)' | str trim --right} | str join (char nl) | print; print ''

    print "```"

    print "#code-block-starting-line-in-original-md-69"
    print "```nu indent-output"
    print ("# Here we emulate that the `$intermid_script_path` options is not set
let $intermid_script_path = $file
    | path-modify --prefix $'numd-temp-(tstamp)' --suffix '.nu'

gen-intermid-script $md_orig_table
| save -f $intermid_script_path

open $intermid_script_path" | nu-highlight)

    print "```\n```output-numd"

# Here we emulate that the `$intermid_script_path` options is not set
let $intermid_script_path = $file
    | path-modify --prefix $'numd-temp-(tstamp)' --suffix '.nu'

gen-intermid-script $md_orig_table
| save -f $intermid_script_path

open $intermid_script_path | table | into string | lines | each {$'//  ($in)' | str trim --right} | str join (char nl) | print; print ''

    print "```"

    print "#code-block-starting-line-in-original-md-125"
    print "```nu indent-output"
    print ("# the flag `$no_fail_on_error` is set to false
let $no_fail_on_error = false

let $nu_res_stdout_lines = run-intermid-script $intermid_script_path $no_fail_on_error
rm $intermid_script_path
$nu_res_stdout_lines" | nu-highlight)

    print "```\n```output-numd"

# the flag `$no_fail_on_error` is set to false
let $no_fail_on_error = false

let $nu_res_stdout_lines = run-intermid-script $intermid_script_path $no_fail_on_error
rm $intermid_script_path
$nu_res_stdout_lines | table | into string | lines | each {$'//  ($in)' | str trim --right} | str join (char nl) | print; print ''

    print "```"

    print "#code-block-starting-line-in-original-md-167"
    print "```nu indent-output"
    print ("let $nu_res_with_block_index = parse-block-index $nu_res_stdout_lines
$nu_res_with_block_index" | nu-highlight)

    print "```\n```output-numd"

let $nu_res_with_block_index = parse-block-index $nu_res_stdout_lines
$nu_res_with_block_index | table | into string | lines | each {$'//  ($in)' | str trim --right} | str join (char nl) | print; print ''

    print "```"

    print "#code-block-starting-line-in-original-md-202"
    print "```nu indent-output"
    print ("let $md_res = assemble-markdown $md_orig_table $nu_res_with_block_index
    | prettify-markdown

$md_res" | nu-highlight)

    print "```\n```output-numd"

let $md_res = assemble-markdown $md_orig_table $nu_res_with_block_index
    | prettify-markdown

$md_res | table | into string | lines | each {$'//  ($in)' | str trim --right} | str join (char nl) | print; print ''

    print "```"

    print "#code-block-starting-line-in-original-md-245"
    print "```nu indent-output"
    print ("calc-changes-stats $file $md_orig $md_res" | nu-highlight)

    print "```\n```output-numd"

calc-changes-stats $file $md_orig $md_res | table | into string | lines | each {$'//  ($in)' | str trim --right} | str join (char nl) | print; print ''

    print "```"
