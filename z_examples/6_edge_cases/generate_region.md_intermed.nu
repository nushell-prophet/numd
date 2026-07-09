# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd

const init_numd_pwd_const = '/Users/user/git/ai-sandbox-dev-container/numd'

# numd config example 1
# This file is prepended to the intermediate script before execution

$env.config.footer_mode = 'always'
$env.config.table = {
    mode: rounded
    index_mode: never
    show_empty: false
    padding: {left: 1, right: 1}
    trim: {methodology: truncating, wrapping_try_keep_words: false, truncating_suffix: '...'}
    header_on_separator: true
    abbreviated_row_count: 1000
}

"#code-block-marker-open-1
<!-- numd-gen-start: [[name value]; [alpha 1] [beta 2]] | to md -->" | print
[[name value]; [alpha 1] [beta 2]] | to md | table --width ($env.numd?.table-width? | default 120) | default '' | into string | str replace --regex '\s*$' '' | print
"<!-- numd-gen-end -->" | print
print ''
