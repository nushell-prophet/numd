# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd

const init_numd_pwd_const = '/Users/user/git/numd'

# numd config loaded from `numd_config_example1.yaml`

$env.config.footer_mode = 'always';
$env.config.table = {mode: rounded, index_mode: never,
show_empty: false, padding: {left: 1, right: 1},
trim: {methodology: truncating, wrapping_try_keep_words: false, truncating_suffix: ...},
header_on_separator: true, abbreviated_row_count: 1000}

"#code-block-marker-open-1
```nu" | print
"# This setting is for overriding the author's usual small number of `abbreviated_row_count`.
$env.config.table.abbreviated_row_count = 100

# The `$init_numd_pwd_const` constant points to the current working directory from where the `numd` command was initiated.
# It is added by `numd` in every intermediate script to make it available in cases like below.
# We use `path join` here to construct working paths for both Windows and Unix
use ($init_numd_pwd_const | path join numd commands.nu) *" | nu-highlight | print

"```\n```output-numd" | print

# This setting is for overriding the author's usual small number of `abbreviated_row_count`.
$env.config.table.abbreviated_row_count = 100

# The `$init_numd_pwd_const` constant points to the current working directory from where the `numd` command was initiated.
# It is added by `numd` in every intermediate script to make it available in cases like below.
# We use `path join` here to construct working paths for both Windows and Unix
use ($init_numd_pwd_const | path join numd commands.nu) *

"```" | print

"#code-block-marker-open-3
```nu" | print
"# Here we set the `$file` variable (which will be used in several commands throughout this script) to point to `z_examples/1_simple_markdown/simple_markdown.md`.
let $file = $init_numd_pwd_const | path join z_examples 1_simple_markdown simple_markdown.md

let $md_orig = open -r $file | toggle-output-fences
let $original_md_table = $md_orig | find-code-blocks
$original_md_table | table -e --width 120" | nu-highlight | print

"```\n```output-numd" | print

# Here we set the `$file` variable (which will be used in several commands throughout this script) to point to `z_examples/1_simple_markdown/simple_markdown.md`.
let $file = $init_numd_pwd_const | path join z_examples 1_simple_markdown simple_markdown.md

let $md_orig = open -r $file | toggle-output-fences
let $original_md_table = $md_orig | find-code-blocks
$original_md_table | table -e --width 120 | table --width 120 | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''

"```" | print

"#code-block-marker-open-6
```nu" | print
"# Here we emulate that the `$intermed_script_path` options is not set
let $intermediate_script_path = $file
    | modify-path --prefix $'numd-temp-(generate-timestamp)' --suffix '.nu'

decorate-original-code-blocks $original_md_table
| generate-intermediate-script
| save -f $intermediate_script_path

open $intermediate_script_path" | nu-highlight | print

"```\n```output-numd" | print

# Here we emulate that the `$intermed_script_path` options is not set
let $intermediate_script_path = $file
    | modify-path --prefix $'numd-temp-(generate-timestamp)' --suffix '.nu'

decorate-original-code-blocks $original_md_table
| generate-intermediate-script
| save -f $intermediate_script_path

open $intermediate_script_path | table --width 120 | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''

"```" | print

"#code-block-marker-open-9
```nu" | print
"# the flag `$no_fail_on_error` is set to false
let $no_fail_on_error = false

let $nu_res_stdout_lines = execute-intermediate-script $intermediate_script_path $no_fail_on_error false
rm $intermediate_script_path
$nu_res_stdout_lines" | nu-highlight | print

"```\n```output-numd" | print

# the flag `$no_fail_on_error` is set to false
let $no_fail_on_error = false

let $nu_res_stdout_lines = execute-intermediate-script $intermediate_script_path $no_fail_on_error false
rm $intermediate_script_path
$nu_res_stdout_lines | table --width 120 | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''

"```" | print

"#code-block-marker-open-12
```nu" | print
"let $md_res = $nu_res_stdout_lines
    | str join (char nl)
    | clean-markdown

$md_res" | nu-highlight | print

"```\n```output-numd" | print

let $md_res = $nu_res_stdout_lines
    | str join (char nl)
    | clean-markdown

$md_res | table --width 120 | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''

"```" | print

"#code-block-marker-open-15
```nu" | print
"compute-change-stats $file $md_orig $md_res" | nu-highlight | print

"```\n```output-numd" | print

compute-change-stats $file $md_orig $md_res | table --width 120 | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''

"```" | print
