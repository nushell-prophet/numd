# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd

const init_numd_pwd_const = '/Users/user/git/numd'

# numd config loaded from `/Users/user/git/numd/numd_config_example1.yaml`

$env.config.footer_mode = 'always';
$env.config.table = {mode: rounded, index_mode: never,
show_empty: false, padding: {left: 1, right: 1},
trim: {methodology: truncating, wrapping_try_keep_words: false, truncating_suffix: ...},
header_on_separator: true, abbreviated_row_count: 1000}

"# numd commands explanation\n\nIn the code block below, we set settings and variables for executing this entire document.\n" | print
"```nu" | print
"# This setting is for overriding the author's usual small number of `abbreviated_row_count`.\n$env.config.table.abbreviated_row_count = 100\n\n# The `$init_numd_pwd_const` constant points to the current working directory from where the `numd` command was initiated.\n# It is added by `numd` in every intermediate script to make it available in cases like below.\n# We use `path join` here to construct working paths for both Windows and Unix\nuse ($init_numd_pwd_const | path join numd run1.nu) *\nuse ($init_numd_pwd_const | path join numd nu-utils numd-internals.nu) *" | nu-highlight | print

"```\n```output-numd" | print

# This setting is for overriding the author's usual small number of `abbreviated_row_count`.
$env.config.table.abbreviated_row_count = 100

# The `$init_numd_pwd_const` constant points to the current working directory from where the `numd` command was initiated.
# It is added by `numd` in every intermediate script to make it available in cases like below.
# We use `path join` here to construct working paths for both Windows and Unix
use ($init_numd_pwd_const | path join numd run1.nu) *
use ($init_numd_pwd_const | path join numd nu-utils numd-internals.nu) *

"```" | print

"\n## numd-internals.nu\n\n### find-code-blocks\n\nThis command is used for parsing initial markdown to detect executable code blocks.\n" | print
"```nu indent-output" | print
"# Here we set the `$file` variable (which will be used in several commands throughout this script) to point to `z_examples/1_simple_markdown/simple_markdown.md`.\nlet $file = $init_numd_pwd_const | path join z_examples 1_simple_markdown simple_markdown.md\n\nlet $md_orig = open -r $file | toggle-output-fences\nlet $md_orig_table = $md_orig | find-code-blocks\n$md_orig_table" | nu-highlight | print

"```\n```output-numd" | print

# Here we set the `$file` variable (which will be used in several commands throughout this script) to point to `z_examples/1_simple_markdown/simple_markdown.md`.
let $file = $init_numd_pwd_const | path join z_examples 1_simple_markdown simple_markdown.md

let $md_orig = open -r $file | toggle-output-fences
let $md_orig_table = $md_orig | find-code-blocks
$md_orig_table | table | lines | each {$'//  ($in)' | str trim --right} | str join (char nl) | table | print; print ''

"```" | print

"\n## generate-intermediate-script\n\nThe `generate-intermediate-script` command generates a script that contains code from all executable blocks and `numd` service commands used for capturing outputs.\n" | print
"```nu indent-output" | print
"# Here we emulate that the `$intermed_script_path` options is not set\nlet $intermed_script_path = $file\n    | modify-path --prefix $'numd-temp-(generate-timestamp)' --suffix '.nu'\n\ngenerate-intermediate-script $md_orig_table\n| save -f $intermed_script_path\n\nopen $intermed_script_path" | nu-highlight | print

"```\n```output-numd" | print

# Here we emulate that the `$intermed_script_path` options is not set
let $intermed_script_path = $file
    | modify-path --prefix $'numd-temp-(generate-timestamp)' --suffix '.nu'

generate-intermediate-script $md_orig_table
| save -f $intermed_script_path

open $intermed_script_path | table | lines | each {$'//  ($in)' | str trim --right} | str join (char nl) | table | print; print ''

"```" | print

"\n## execute-intermediate-script\n\nThe `execute-intermediate-script` command runs and captures outputs of the executed intermediate script.\n" | print
"```nu indent-output" | print
"# the flag `$no_fail_on_error` is set to false\nlet $no_fail_on_error = false\n\nlet $nu_res_stdout_lines = execute-intermediate-script $intermed_script_path $no_fail_on_error false\nrm $intermed_script_path\n$nu_res_stdout_lines" | nu-highlight | print

"```\n```output-numd" | print

# the flag `$no_fail_on_error` is set to false
let $no_fail_on_error = false

let $nu_res_stdout_lines = execute-intermediate-script $intermed_script_path $no_fail_on_error false
rm $intermed_script_path
$nu_res_stdout_lines | table | lines | each {$'//  ($in)' | str trim --right} | str join (char nl) | table | print; print ''

"```" | print

"" | print
"```nu indent-output" | print
"let $md_res = $nu_res_stdout_lines\n    | str join (char nl)\n    | clean-markdown\n\n$md_res" | nu-highlight | print

"```\n```output-numd" | print

let $md_res = $nu_res_stdout_lines
    | str join (char nl)
    | clean-markdown

$md_res | table | lines | each {$'//  ($in)' | str trim --right} | str join (char nl) | table | print; print ''

"```" | print

"\n## compute-change-stats\n\nThe `compute-change-stats` command displays stats on the changes made.\n" | print
"```nu indent-output" | print
"compute-change-stats $file $md_orig $md_res" | nu-highlight | print

"```\n```output-numd" | print

compute-change-stats $file $md_orig $md_res | table | lines | each {$'//  ($in)' | str trim --right} | str join (char nl) | table | print; print ''

"```" | print
