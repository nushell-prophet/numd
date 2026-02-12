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

## parse-markdown-to-blocks

This command is used for parsing initial markdown to detect executable code blocks.

```nu
# Here we set the `$file` variable (which will be used in several commands throughout this script) to point to `z_examples/1_simple_markdown/simple_markdown.md`.
let $file = $init_numd_pwd_const | path join z_examples 1_simple_markdown simple_markdown.md
let $md_orig = open -r $file | convert-output-fences
let $original_md_table = $md_orig | parse-markdown-to-blocks

$original_md_table | table -e --width 120
# => ╭───┬─────────────┬──────────────────────┬─────────────────────────────────────────────────────────────────────────┬───╮
# => │ # │ block_index │       row_type       │                                  line                                   │ a │
# => │   │             │                      │                                                                         │ c │
# => │   │             │                      │                                                                         │ t │
# => │   │             │                      │                                                                         │ i │
# => │   │             │                      │                                                                         │ o │
# => │   │             │                      │                                                                         │ n │
# => ├───┼─────────────┼──────────────────────┼─────────────────────────────────────────────────────────────────────────┼───┤
# => │ 0 │           0 │ text                 │ ╭───┬─────────────────────────────────────────────────────────────────╮ │ p │
# => │   │             │                      │ │ 0 │ # This is a simple markdown example                             │ │ r │
# => │   │             │                      │ │ 1 │                                                                 │ │ i │
# => │   │             │                      │ │ 2 │ ## Example 1                                                    │ │ n │
# => │   │             │                      │ │ 3 │                                                                 │ │ t │
# => │   │             │                      │ │ 4 │ the block below will be executed as it is, but won't yield any  │ │ - │
# => │   │             │                      │ │   │ output                                                          │ │ a │
# => │   │             │                      │ │ 5 │                                                                 │ │ s │
# => │   │             │                      │ ╰───┴─────────────────────────────────────────────────────────────────╯ │ - │
# => │   │             │                      │                                                                         │ i │
# => │   │             │                      │                                                                         │ t │
# => │   │             │                      │                                                                         │ - │
# => │   │             │                      │                                                                         │ i │
# => │   │             │                      │                                                                         │ s │
# => │ 1 │           1 │ ```nu                │ ╭───┬───────────────────╮                                               │ e │
# => │   │             │                      │ │ 0 │ ```nu             │                                               │ x │
# => │   │             │                      │ │ 1 │ let $var1 = 'foo' │                                               │ e │
# => │   │             │                      │ │ 2 │ ```               │                                               │ c │
# => │   │             │                      │ ╰───┴───────────────────╯                                               │ u │
# => │   │             │                      │                                                                         │ t │
# => │   │             │                      │                                                                         │ e │
# => │ 2 │           2 │ text                 │ ╭───┬──────────────╮                                                    │ p │
# => │   │             │                      │ │ 0 │              │                                                    │ r │
# => │   │             │                      │ │ 1 │ ## Example 2 │                                                    │ i │
# => │   │             │                      │ │ 2 │              │                                                    │ n │
# => │   │             │                      │ ╰───┴──────────────╯                                                    │ t │
# => │   │             │                      │                                                                         │ - │
# => │   │             │                      │                                                                         │ a │
# => │   │             │                      │                                                                         │ s │
# => │   │             │                      │                                                                         │ - │
# => │   │             │                      │                                                                         │ i │
# => │   │             │                      │                                                                         │ t │
# => │   │             │                      │                                                                         │ - │
# => │   │             │                      │                                                                         │ i │
# => │   │             │                      │                                                                         │ s │
# => │ 3 │           3 │ ```nu separate-block │ ╭───┬───────────────────────────────────────────────────────────╮       │ e │
# => │   │             │                      │ │ 0 │ ```nu separate-block                                      │       │ x │
# => │   │             │                      │ │ 1 │ # This block will produce some output in a separate block │       │ e │
# => │   │             │                      │ │ 2 │ $var1 | path join 'baz' 'bar'                             │       │ c │
# => │   │             │                      │ │ 3 │ ```                                                       │       │ u │
# => │   │             │                      │ ╰───┴───────────────────────────────────────────────────────────╯       │ t │
# => │   │             │                      │                                                                         │ e │
# => │ 4 │           4 │ ```output-numd       │ ╭───┬──────────────────╮                                                │ d │
# => │   │             │                      │ │ 0 │ ```output-numd   │                                                │ e │
# => │   │             │                      │ │ 1 │ # => foo/baz/bar │                                                │ l │
# => │   │             │                      │ │ 2 │ ```              │                                                │ e │
# => │   │             │                      │ ╰───┴──────────────────╯                                                │ t │
# => │   │             │                      │                                                                         │ e │
# => │ 5 │           5 │ text                 │ ╭───┬──────────────╮                                                    │ p │
# => │   │             │                      │ │ 0 │              │                                                    │ r │
# => │   │             │                      │ │ 1 │ ## Example 3 │                                                    │ i │
# => │   │             │                      │ │ 2 │              │                                                    │ n │
# => │   │             │                      │ ╰───┴──────────────╯                                                    │ t │
# => │   │             │                      │                                                                         │ - │
# => │   │             │                      │                                                                         │ a │
# => │   │             │                      │                                                                         │ s │
# => │   │             │                      │                                                                         │ - │
# => │   │             │                      │                                                                         │ i │
# => │   │             │                      │                                                                         │ t │
# => │   │             │                      │                                                                         │ - │
# => │   │             │                      │                                                                         │ i │
# => │   │             │                      │                                                                         │ s │
# => │ 6 │           6 │ ```nu                │ ╭───┬─────────────────────────────────────────╮                         │ e │
# => │   │             │                      │ │ 0 │ ```nu                                   │                         │ x │
# => │   │             │                      │ │ 1 │ # This block will output results inline │                         │ e │
# => │   │             │                      │ │ 2 │ whoami                                  │                         │ c │
# => │   │             │                      │ │ 3 │ # => user                               │                         │ u │
# => │   │             │                      │ │ 4 │                                         │                         │ t │
# => │   │             │                      │ │ 5 │ 2 + 2                                   │                         │ e │
# => │   │             │                      │ │ 6 │ # => 4                                  │                         │   │
# => │   │             │                      │ │ 7 │ ```                                     │                         │   │
# => │   │             │                      │ ╰───┴─────────────────────────────────────────╯                         │   │
# => │ 7 │           7 │ text                 │ ╭───┬──────────────╮                                                    │ p │
# => │   │             │                      │ │ 0 │              │                                                    │ r │
# => │   │             │                      │ │ 1 │ ## Example 4 │                                                    │ i │
# => │   │             │                      │ │ 2 │              │                                                    │ n │
# => │   │             │                      │ ╰───┴──────────────╯                                                    │ t │
# => │   │             │                      │                                                                         │ - │
# => │   │             │                      │                                                                         │ a │
# => │   │             │                      │                                                                         │ s │
# => │   │             │                      │                                                                         │ - │
# => │   │             │                      │                                                                         │ i │
# => │   │             │                      │                                                                         │ t │
# => │   │             │                      │                                                                         │ - │
# => │   │             │                      │                                                                         │ i │
# => │   │             │                      │                                                                         │ s │
# => │ 8 │           8 │ ```                  │ ╭───┬─────────────────────────────────────────────────────────────────╮ │ p │
# => │   │             │                      │ │ 0 │ ```                                                             │ │ r │
# => │   │             │                      │ │ 1 │ # This block doesn't have a language identifier in the opening  │ │ i │
# => │   │             │                      │ │   │ fence                                                           │ │ n │
# => │   │             │                      │ │ 2 │ ```                                                             │ │ t │
# => │   │             │                      │ ╰───┴─────────────────────────────────────────────────────────────────╯ │ - │
# => │   │             │                      │                                                                         │ a │
# => │   │             │                      │                                                                         │ s │
# => │   │             │                      │                                                                         │ - │
# => │   │             │                      │                                                                         │ i │
# => │   │             │                      │                                                                         │ t │
# => │   │             │                      │                                                                         │ - │
# => │   │             │                      │                                                                         │ i │
# => │   │             │                      │                                                                         │ s │
# => ╰───┴─────────────┴──────────────────────┴─────────────────────────────────────────────────────────────────────────┴───╯
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

## extract-block-index

The `extract-block-index` command parses execution output, using `#code-block-marker-open-N` markers to associate each output block with its original block index.

```nu
let $nu_res_with_block_index = $nu_res_stdout_lines
    | str replace -ar "\n{2,}```\n" "\n```\n"
    | lines
    | extract-block-index

$nu_res_with_block_index | table -e --width 120
# => ╭───┬─────────────┬───────────────────────────────────────────────────────────╮
# => │ # │ block_index │                           line                            │
# => ├───┼─────────────┼───────────────────────────────────────────────────────────┤
# => │ 0 │           1 │ ```nu                                                     │
# => │   │             │ let $var1 = 'foo'                                         │
# => │   │             │ ```                                                       │
# => │ 1 │           3 │ ```nu separate-block                                      │
# => │   │             │ # This block will produce some output in a separate block │
# => │   │             │ $var1 | path join 'baz' 'bar'                             │
# => │   │             │ ```                                                       │
# => │   │             │ ```output-numd                                            │
# => │   │             │ # => foo/baz/bar                                          │
# => │   │             │ ```                                                       │
# => │ 2 │           6 │ ```nu                                                     │
# => │   │             │ # This block will output results inline                   │
# => │   │             │ whoami                                                    │
# => │   │             │ # => user                                                 │
# => │   │             │                                                           │
# => │   │             │                                                           │
# => │   │             │                                                           │
# => │   │             │ 2 + 2                                                     │
# => │   │             │ # => 4                                                    │
# => │   │             │ ```                                                       │
# => ╰───┴─────────────┴───────────────────────────────────────────────────────────╯
```

## merge-markdown

The `merge-markdown` command merges execution results back into the original markdown structure, combining unchanged text blocks with updated code blocks. The `clean-markdown` command then removes unnecessary empty lines and trailing spaces.

```nu
let $md_res = merge-markdown $original_md_table $nu_res_with_block_index
    | clean-markdown

$md_res
# => # This is a simple markdown example
# =>
# => ## Example 1
# =>
# => the block below will be executed as it is, but won't yield any output
# =>
# => ```nu
# => let $var1 = 'foo'
# => ```
# =>
# => ## Example 2
# =>
# => ```nu separate-block
# => # This block will produce some output in a separate block
# => $var1 | path join 'baz' 'bar'
# => ```
# => ```output-numd
# => # => foo/baz/bar
# => ```
# =>
# => ## Example 3
# =>
# => ```nu
# => # This block will output results inline
# => whoami
# => # => user
# =>
# => 2 + 2
# => # => 4
# => ```
# =>
# => ## Example 4
# =>
# => ```
# => # This block doesn't have a language identifier in the opening fence
# => ```
```

## compute-change-stats

The `compute-change-stats` command displays stats on the changes made.

```nu
compute-change-stats $file $md_orig $md_res
# => ╭──────────────────┬────────────────────╮
# => │ filename         │ simple_markdown.md │
# => │ nushell_blocks   │ 3                  │
# => │ levenshtein_dist │ 0                  │
# => │ diff_lines       │ 0%                 │
# => │ diff_words       │ 0%                 │
# => │ diff_chars       │ 0%                 │
# => ╰──────────────────┴────────────────────╯
```
