# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd

const init_numd_pwd_const = '/Users/user/git/numd'

# numd config loaded from `numd_config_example1.yaml`

$env.config.footer_mode = 'always';
$env.config.table = {mode: rounded, index_mode: never,
show_empty: false, padding: {left: 1, right: 1},
trim: {methodology: truncating, wrapping_try_keep_words: false, truncating_suffix: ...},
header_on_separator: true, abbreviated_row_count: 1000}

"#code-block-marker-open-0
```nu" | print
"let $var1 = 'foo'" | nu-highlight | print

let $var1 = 'foo'
print ''
"```" | print

"#code-block-marker-open-2
```nu" | print
"# This block will produce some output in a separate block
$var1 | path join 'baz' 'bar'" | nu-highlight | print

# This block will produce some output in a separate block
$var1 | path join 'baz' 'bar' | table --width 120 | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"```" | print

"#code-block-marker-open-4
```nu" | print
"# This block will output results inline
whoami" | nu-highlight | print

# This block will output results inline
whoami | table --width 120 | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"2 + 2" | nu-highlight | print

2 + 2 | table --width 120 | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"```" | print
