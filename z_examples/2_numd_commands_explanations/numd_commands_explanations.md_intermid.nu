# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd
const init_numd_pwd_const = '/Users/user/git/numd'
"# numd commands explanation

In the code block below, we set settings and variables for executing this entire document.
" | print
"```nu" | print
"# This setting is for overriding the author's usual small number of `abbreviated_row_count`.
$env.config.table.abbreviated_row_count = 100

# The `$init_numd_pwd_const` constant points to the current working directory from where the `numd` command was initiated.
# It is added by `numd` in every intermediate script to make it available in cases like below.
# We use `path join` here to construct working paths for both Windows and Unix
use ($init_numd_pwd_const | path join numd run1.nu) *
use ($init_numd_pwd_const | path join numd nu-utils numd-internals.nu) *" | nu-highlight | print

"```\n```output-numd" | print

# This setting is for overriding the author's usual small number of `abbreviated_row_count`.
$env.config.table.abbreviated_row_count = 100

# The `$init_numd_pwd_const` constant points to the current working directory from where the `numd` command was initiated.
# It is added by `numd` in every intermediate script to make it available in cases like below.
# We use `path join` here to construct working paths for both Windows and Unix
use ($init_numd_pwd_const | path join numd run1.nu) *
use ($init_numd_pwd_const | path join numd nu-utils numd-internals.nu) *

"```" | print

"
## numd-internals.nu

### find-code-blocks

This command is used for parsing initial markdown to detect executable code blocks.
" | print
"```nu indent-output" | print
"# Here we set the `$file` variable (which will be used in several commands throughout this script) to point to `z_examples/1_simple_markdown/simple_markdown.md`.
let $file = $init_numd_pwd_const | path join z_examples 1_simple_markdown simple_markdown.md

let $md_orig = open -r $file | toggle-output-fences
let $md_orig_table = $md_orig | find-code-blocks
$md_orig_table" | nu-highlight | print

"```\n```output-numd" | print

# Here we set the `$file` variable (which will be used in several commands throughout this script) to point to `z_examples/1_simple_markdown/simple_markdown.md`.
let $file = $init_numd_pwd_const | path join z_examples 1_simple_markdown simple_markdown.md

let $md_orig = open -r $file | toggle-output-fences
let $md_orig_table = $md_orig | find-code-blocks
$md_orig_table | table | into string | lines | each {$'//  ($in)' | str trim --right} | str join (char nl) | print; print ''

"```" | print

"
## generate-intermediate-script

The `generate-intermediate-script` command generates a script that contains code from all executable blocks and `numd` service commands used for capturing outputs.
" | print
"```nu indent-output" | print
"# Here we emulate that the `$intermid_script_path` options is not set
let $intermid_script_path = $file
    | modify-path --prefix $'numd-temp-(generate-timestamp)' --suffix '.nu'

generate-intermediate-script $md_orig_table
| save -f $intermid_script_path

open $intermid_script_path" | nu-highlight | print

"```\n```output-numd" | print

# Here we emulate that the `$intermid_script_path` options is not set
let $intermid_script_path = $file
    | modify-path --prefix $'numd-temp-(generate-timestamp)' --suffix '.nu'

generate-intermediate-script $md_orig_table
| save -f $intermid_script_path

open $intermid_script_path | table | into string | lines | each {$'//  ($in)' | str trim --right} | str join (char nl) | print; print ''

"```" | print

"
## execute-intermediate-script

The `execute-intermediate-script` command runs and captures outputs of the executed intermediate script.
" | print
"```nu indent-output" | print
"# the flag `$no_fail_on_error` is set to false
let $no_fail_on_error = false

let $nu_res_stdout_lines = execute-intermediate-script $intermid_script_path $no_fail_on_error false
rm $intermid_script_path
$nu_res_stdout_lines" | nu-highlight | print

"```\n```output-numd" | print

# the flag `$no_fail_on_error` is set to false
let $no_fail_on_error = false

let $nu_res_stdout_lines = execute-intermediate-script $intermid_script_path $no_fail_on_error false
rm $intermid_script_path
$nu_res_stdout_lines | table | into string | lines | each {$'//  ($in)' | str trim --right} | str join (char nl) | print; print ''

"```" | print

"" | print
"```nu indent-output" | print
"let $md_res = $nu_res_stdout_lines
    | str join (char nl)
    | clean-markdown

$md_res" | nu-highlight | print

"```\n```output-numd" | print

let $md_res = $nu_res_stdout_lines
    | str join (char nl)
    | clean-markdown

$md_res | table | into string | lines | each {$'//  ($in)' | str trim --right} | str join (char nl) | print; print ''

"```" | print

"
## compute-change-stats

The `compute-change-stats` command displays stats on the changes made.
" | print
"```nu indent-output" | print
"compute-change-stats $file $md_orig $md_res" | nu-highlight | print

"```\n```output-numd" | print

compute-change-stats $file $md_orig $md_res | table | into string | lines | each {$'//  ($in)' | str trim --right} | str join (char nl) | print; print ''

"```" | print
