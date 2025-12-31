# numd commands explanation

In the code block below, we set settings and variables for executing this entire document.

```nu
# This setting is for overriding the author's usual small number of `abbreviated_row_count`.
$env.config.table.abbreviated_row_count = 100
# The `$init_numd_pwd_const` constant points to the current working directory from where the `numd` command was initiated.
# It is added by `numd` in every intermediate script to make it available in cases like below.
# We use `path join` here to construct working paths for both Windows and Unix
use ($init_numd_pwd_const | path join numd commands.nu) *
```

## numd-internals.nu

### parse-markdown-to-blocks

This command is used for parsing initial markdown to detect executable code blocks.

```nu
# Here we set the `$file` variable (which will be used in several commands throughout this script) to point to `z_examples/1_simple_markdown/simple_markdown.md`.
let $file = $init_numd_pwd_const | path join z_examples 1_simple_markdown simple_markdown.md
let $md_orig = open -r $file | convert-output-fences
let $original_md_table = $md_orig | parse-markdown-to-blocks

$original_md_table | table -e --width 120
# => ╭─block_index─┬───────row_type───────┬───────────────────────────────────line────────────────────────────────────┬─act─╮
# => │           0 │ text                 │ ╭───────────────────────────────────────────────────────────────────────╮ │ pri │
# => │             │                      │ │ # This is a simple markdown example                                   │ │ nt- │
# => │             │                      │ │                                                                       │ │ as- │
# => │             │                      │ │ ## Example 1                                                          │ │ it- │
# => │             │                      │ │                                                                       │ │ is  │
# => │             │                      │ │ the block below will be executed as it is, but won't yield any output │ │     │
# => │             │                      │ │                                                                       │ │     │
# => │             │                      │ ╰───────────────────────────────────────────────────────────────────────╯ │     │
# => │           1 │ ```nu                │ ╭───────────────────╮                                                     │ exe │
# => │             │                      │ │ ```nu             │                                                     │ cut │
# => │             │                      │ │ let $var1 = 'foo' │                                                     │ e   │
# => │             │                      │ │ ```               │                                                     │     │
# => │             │                      │ ╰───────────────────╯                                                     │     │
# => │           2 │ text                 │ ╭──────────────╮                                                          │ pri │
# => │             │                      │ │              │                                                          │ nt- │
# => │             │                      │ │ ## Example 2 │                                                          │ as- │
# => │             │                      │ │              │                                                          │ it- │
# => │             │                      │ ╰──────────────╯                                                          │ is  │
# => │           3 │ ```nu separate-block │ ╭───────────────────────────────────────────────────────────╮             │ exe │
# => │             │                      │ │ ```nu separate-block                                      │             │ cut │
# => │             │                      │ │ # This block will produce some output in a separate block │             │ e   │
# => │             │                      │ │ $var1 | path join 'baz' 'bar'                             │             │     │
# => │             │                      │ │ ```                                                       │             │     │
# => │             │                      │ ╰───────────────────────────────────────────────────────────╯             │     │
# => │           4 │ ```output-numd       │ ╭──────────────────╮                                                      │ del │
# => │             │                      │ │ ```output-numd   │                                                      │ ete │
# => │             │                      │ │ # => foo/baz/bar │                                                      │     │
# => │             │                      │ │ ```              │                                                      │     │
# => │             │                      │ ╰──────────────────╯                                                      │     │
# => │           5 │ text                 │ ╭──────────────╮                                                          │ pri │
# => │             │                      │ │              │                                                          │ nt- │
# => │             │                      │ │ ## Example 3 │                                                          │ as- │
# => │             │                      │ │              │                                                          │ it- │
# => │             │                      │ ╰──────────────╯                                                          │ is  │
# => │           6 │ ```nu                │ ╭─────────────────────────────────────────╮                               │ exe │
# => │             │                      │ │ ```nu                                   │                               │ cut │
# => │             │                      │ │ # This block will output results inline │                               │ e   │
# => │             │                      │ │ whoami                                  │                               │     │
# => │             │                      │ │ # => user                               │                               │     │
# => │             │                      │ │                                         │                               │     │
# => │             │                      │ │ 2 + 2                                   │                               │     │
# => │             │                      │ │ # => 4                                  │                               │     │
# => │             │                      │ │ ```                                     │                               │     │
# => │             │                      │ ╰─────────────────────────────────────────╯                               │     │
# => │           7 │ text                 │ ╭──────────────╮                                                          │ pri │
# => │             │                      │ │              │                                                          │ nt- │
# => │             │                      │ │ ## Example 4 │                                                          │ as- │
# => │             │                      │ │              │                                                          │ it- │
# => │             │                      │ ╰──────────────╯                                                          │ is  │
# => │           8 │ ```                  │ ╭──────────────────────────────────────────────────────────────────────╮  │ pri │
# => │             │                      │ │ ```                                                                  │  │ nt- │
# => │             │                      │ │ # This block doesn't have a language identifier in the opening fence │  │ as- │
# => │             │                      │ │ ```                                                                  │  │ it- │
# => │             │                      │ ╰──────────────────────────────────────────────────────────────────────╯  │ is  │
# => ╰─block_index─┴───────row_type───────┴───────────────────────────────────line────────────────────────────────────┴─act─╯
```

## generate-intermediate-script

The `generate-intermediate-script` command generates a script that contains code from all executable blocks and `numd` service commands used for capturing outputs.

```nu
# Here we emulate that the `$intermed_script_path` options is not set
let $intermediate_script_path = $file
    | build-modified-path --prefix $'numd-temp-(generate-timestamp)' --suffix '.nu'

decorate-original-code-blocks $original_md_table
| generate-intermediate-script
| save -f $intermediate_script_path

open $intermediate_script_path
# => # this script was generated automatically using numd
# => # https://github.com/nushell-prophet/numd
# =>
# => const init_numd_pwd_const = '/Users/user/git/numd'
# =>
# => "#code-block-marker-open-1
# => ```nu" | print
# => "let $var1 = 'foo'" | nu-highlight | print
# =>
# => let $var1 = 'foo'
# => print ''
# => "```" | print
# =>
# => "#code-block-marker-open-3
# => ```nu separate-block" | print
# => "# This block will produce some output in a separate block
# => $var1 | path join 'baz' 'bar'" | nu-highlight | print
# =>
# => "```\n```output-numd" | print
# =>
# => # This block will produce some output in a separate block
# => $var1 | path join 'baz' 'bar' | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each { $'# => ($in)' | str trim --right } | str join (char nl) | str replace -r '\s*$' (char nl) | print; print ''
# => print ''
# => "```" | print
# =>
# => "#code-block-marker-open-6
# => ```nu" | print
# => "# This block will output results inline
# => whoami" | nu-highlight | print
# =>
# => # This block will output results inline
# => whoami | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each { $'# => ($in)' | str trim --right } | str join (char nl) | str replace -r '\s*$' (char nl) | print; print ''
# => print ''
# => "2 + 2" | nu-highlight | print
# =>
# => 2 + 2 | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each { $'# => ($in)' | str trim --right } | str join (char nl) | str replace -r '\s*$' (char nl) | print; print ''
# => print ''
# => "```" | print
```

## execute-intermediate-script

The `execute-intermediate-script` command runs and captures outputs of the executed intermediate script.

```nu
# the flag `$no_fail_on_error` is set to false
let $no_fail_on_error = false
let $nu_res_stdout_lines = execute-intermediate-script $intermediate_script_path $no_fail_on_error false false
rm $intermediate_script_path

$nu_res_stdout_lines
# => #code-block-marker-open-1
# => ```nu
# => let $var1 = 'foo'
# =>
# => ```
# => #code-block-marker-open-3
# => ```nu separate-block
# => # This block will produce some output in a separate block
# => $var1 | path join 'baz' 'bar'
# => ```
# => ```output-numd
# => # => foo/baz/bar
# =>
# =>
# =>
# => ```
# => #code-block-marker-open-6
# => ```nu
# => # This block will output results inline
# => whoami
# => # => user
# =>
# =>
# =>
# => 2 + 2
# => # => 4
# =>
# =>
# =>
# => ```
```

```nu
let $md_res = $nu_res_stdout_lines
    | str join (char nl)
    | clean-markdown

$md_res
# => #code-block-marker-open-1
# => ```nu
# => let $var1 = 'foo'
# =>
# => ```
# => #code-block-marker-open-3
# => ```nu separate-block
# => # This block will produce some output in a separate block
# => $var1 | path join 'baz' 'bar'
# => ```
# => ```output-numd
# => # => foo/baz/bar
# =>
# => ```
# => #code-block-marker-open-6
# => ```nu
# => # This block will output results inline
# => whoami
# => # => user
# =>
# => 2 + 2
# => # => 4
# =>
# => ```
```

## compute-change-stats

The `compute-change-stats` command displays stats on the changes made.

```nu
compute-change-stats $file $md_orig $md_res
# => ╭──────────────────┬────────────────────╮
# => │ filename         │ simple_markdown.md │
# => │ nushell_blocks   │ 3                  │
# => │ levenshtein_dist │ 248                │
# => │ diff_lines       │ -12 (-33.3%)       │
# => │ diff_words       │ -24 (-30.8%)       │
# => │ diff_chars       │ -163 (-32.5%)      │
# => ╰──────────────────┴────────────────────╯
```
