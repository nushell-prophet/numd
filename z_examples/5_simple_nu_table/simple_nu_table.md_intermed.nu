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
```nushell" | print
"> $env.numd?" | nu-highlight | print

$env.numd? | table --width 120 | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''

"```" | print

"#code-block-marker-open-2
```nushell" | print
"[[a b c]; [1 2 3]]" | nu-highlight | print

"```\n```output-numd" | print

[[a b c]; [1 2 3]] | table --width 120 | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''

"```" | print

"#code-block-marker-open-5
```nushell" | print
"[[column long_text];

['value_1' ('Veniam cillum et et. Et et qui enim magna. Qui enim, magna eu aute lorem.' +
                'Eu aute lorem ullamco sed ipsum incididunt irure. Lorem ullamco sed ipsum incididunt.' +
                'Sed ipsum incididunt irure, culpa. Irure, culpa labore sit sunt.')]

['value_2' ('Irure quis magna ipsum anim. Magna ipsum anim aliquip elit lorem ut. Anim aliquip ' +
                'elit lorem, ut quis nostrud. Lorem ut quis, nostrud commodo non. Nostrud commodo non ' +
                'cillum exercitation dolore fugiat nulla. Non cillum exercitation dolore fugiat nulla ' +
                'ut. Exercitation dolore fugiat nulla ut adipiscing laboris elit. Fugiat nulla ut ' +
                'adipiscing, laboris elit quis pariatur. Adipiscing laboris elit quis pariatur. ' +
                'Elit quis pariatur, in ut anim anim ut.')]
]" | nu-highlight | print

"```\n```output-numd" | print

[[column long_text];

['value_1' ('Veniam cillum et et. Et et qui enim magna. Qui enim, magna eu aute lorem.' +
                'Eu aute lorem ullamco sed ipsum incididunt irure. Lorem ullamco sed ipsum incididunt.' +
                'Sed ipsum incididunt irure, culpa. Irure, culpa labore sit sunt.')]

['value_2' ('Irure quis magna ipsum anim. Magna ipsum anim aliquip elit lorem ut. Anim aliquip ' +
                'elit lorem, ut quis nostrud. Lorem ut quis, nostrud commodo non. Nostrud commodo non ' +
                'cillum exercitation dolore fugiat nulla. Non cillum exercitation dolore fugiat nulla ' +
                'ut. Exercitation dolore fugiat nulla ut adipiscing laboris elit. Fugiat nulla ut ' +
                'adipiscing, laboris elit quis pariatur. Adipiscing laboris elit quis pariatur. ' +
                'Elit quis pariatur, in ut anim anim ut.')]
] | table --width 120 | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''

"```" | print
