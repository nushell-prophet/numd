# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd
const init_numd_pwd_const = '/Users/user/git/numd'
"# numd commands explanation

In the code block below, we set settings and variables for executing this entire document.
" | print
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

"
## numd-internals.nu

### detect-code-blocks

This command is used for parsing initial markdown to detect executable code blocks.
" | print
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

"
## gen-intermid-script

The `gen-intermid-script` command generates a script that contains code from all executable blocks and `numd` service commands used for capturing outputs.
" | print
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

"
## run-intermid-script

The `run-intermid-script` command runs and captures outputs of the executed intermediate script.
" | print
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

"
## parse-block-index

The `parse-block-index` command parses the captured output, and groups them by executed blocks.
" | print
    print "```nu indent-output"
    print ("let $nu_res_with_block_index = parse-block-index $nu_res_stdout_lines
$nu_res_with_block_index" | nu-highlight)

    print "```\n```output-numd"

let $nu_res_with_block_index = parse-block-index $nu_res_stdout_lines
$nu_res_with_block_index | table | into string | lines | each {$'//  ($in)' | str trim --right} | str join (char nl) | print; print ''

    print "```"

"
## assemble-markdown

The `assemble-markdown` command cleans outdated commands outputs in the `$md_orig_table` and combines them with `$nu_res_with_block_index` (the variable from the previous step). Additionally, `prettify-markdown` is used here to remove empty blocks and unnecessary empty lines.
" | print
    print "```nu indent-output"
    print ("let $md_res = assemble-markdown $md_orig_table $nu_res_with_block_index
    | prettify-markdown

$md_res" | nu-highlight)

    print "```\n```output-numd"

let $md_res = assemble-markdown $md_orig_table $nu_res_with_block_index
    | prettify-markdown

$md_res | table | into string | lines | each {$'//  ($in)' | str trim --right} | str join (char nl) | print; print ''

    print "```"

"
## calc-changes-stats

The `calc-changes-stats` command displays stats on the changes made.
" | print
    print "```nu indent-output"
    print ("calc-changes-stats $file $md_orig $md_res" | nu-highlight)

    print "```\n```output-numd"

calc-changes-stats $file $md_orig $md_res | table | into string | lines | each {$'//  ($in)' | str trim --right} | str join (char nl) | print; print ''

    print "```"
