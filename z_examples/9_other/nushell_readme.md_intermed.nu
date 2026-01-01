# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd

const init_numd_pwd_const = '/Users/user/git/numd'

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
