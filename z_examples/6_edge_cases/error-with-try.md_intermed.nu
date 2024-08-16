# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd

const init_numd_pwd_const = '/Users/user/git/numd'

# numd config loaded from `/Users/user/git/numd/numd_config_example1.yaml`

$env.config.footer_mode = 'always';
$env.config.table = {mode: rounded, index_mode: never,
show_empty: false, padding: {left: 1, right: 1},
trim: {methodology: truncating, wrapping_try_keep_words: false, truncating_suffix: ...},
header_on_separator: true, abbreviated_row_count: 1000}

"```nushell no-run
> lssomething
╭───────┬────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ msg   │ External command failed                                                                                                                                                                    │
│ debug │ ExternalCommand { label: \"Command `lssomething` not found\", help: \"`lssomething` is neither a Nushell built-in or a known external command\", span: Span { start: 1967901, end: 1967912 } } │
│ raw   │ ExternalCommand { label: \"Command `lssomething` not found\", help: \"`lssomething` is neither a Nushell built-in or a known external command\", span: Span { start: 1967901, end: 1967912 } } │
╰───────┴────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
```" | print
"" | print
"```nushell try, new-instance" | print
"> lssomething" | nu-highlight | print

/Users/user/.cargo/bin/nu -c "lssomething"| complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | table | print; print ''

"```" | print
