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
"let $two_single_lines_text = r#'\"High up in the mountains, a Snake crawled and lay in a damp gorge, coiled
    into a knot, staring out at the sea.'#" | nu-highlight | print

"```\n```output-numd" | print

let $two_single_lines_text = r#'"High up in the mountains, a Snake crawled and lay in a damp gorge, coiled
    into a knot, staring out at the sea.'#

"```" | print

"#code-block-marker-open-3
```nu" | print
"$two_single_lines_text" | nu-highlight | print

"```\n```output-numd" | print

$two_single_lines_text | table --width 120 | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''

"```" | print
