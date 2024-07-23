
    # ```nu
# This setting is for overriding the author's usual small number of `abbreviated_row_count`.
$env.config.table.abbreviated_row_count = 100

# The `$init_numd_pwd_const` constant points to the current working directory from where the `numd` command was initiated.
# It is added by `numd` in every intermediate script to make it available in cases like below.
# We use `path join` here to construct working paths for both Windows and Unix
use ($init_numd_pwd_const | path join numd run1.nu) *
use ($init_numd_pwd_const | path join numd nu-utils numd-internals.nu) *


    # ```nu indent-output
# Here we set the `$file` variable (which will be used in several commands throughout this script) to point to `z_examples/1_simple_markdown/simple_markdown.md`.
let $file = $init_numd_pwd_const | path join z_examples 1_simple_markdown simple_markdown.md

let $md_orig = open -r $file | toggle-output-fences
let $md_orig_table = $md_orig | find-code-blocks
$md_orig_table


    # ```nu indent-output
# Here we emulate that the `$intermid_script_path` options is not set
let $intermid_script_path = $file
    | modify-path --prefix $'numd-temp-(generate-timestamp)' --suffix '.nu'

generate-intermediate-script $md_orig_table
| save -f $intermid_script_path

open $intermid_script_path


    # ```nu indent-output
# the flag `$no_fail_on_error` is set to false
let $no_fail_on_error = false

let $nu_res_stdout_lines = execute-intermediate-script $intermid_script_path $no_fail_on_error false
rm $intermid_script_path
$nu_res_stdout_lines


    # ```nu indent-output
let $md_res = $nu_res_stdout_lines
    | str join (char nl)
    | clean-markdown

$md_res


    # ```nu indent-output
compute-change-stats $file $md_orig $md_res
