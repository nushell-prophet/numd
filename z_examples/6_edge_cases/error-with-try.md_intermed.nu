# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd

const init_numd_pwd_const = '/Users/user/git/numd'

# numd config loaded from `numd_config_example1.yaml`

$env.config.footer_mode = 'always';
$env.config.table = {mode: rounded, index_mode: never,
show_empty: false, padding: {left: 1, right: 1},
trim: {methodology: truncating, wrapping_try_keep_words: false, truncating_suffix: ...},
header_on_separator: true, abbreviated_row_count: 1000}

"#code-block-marker-open-2
```nushell try, new-instance" | print
"> lssomething" | nu-highlight | print

/Users/user/.cargo/bin/nu -c "lssomething" | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | table --width 120 | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''

"```" | print
