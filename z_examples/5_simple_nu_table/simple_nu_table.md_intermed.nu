# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd

const init_numd_pwd_const = '/Users/user/git/numd'

# numd config loaded from `/Users/user/git/numd/numd_config_example1.yaml`

$env.config.footer_mode = 'always';
$env.config.table = {mode: rounded, index_mode: never,
show_empty: false, padding: {left: 1, right: 1},
trim: {methodology: truncating, wrapping_try_keep_words: false, truncating_suffix: ...},
header_on_separator: true, abbreviated_row_count: 1000}

"```nushell" | print
"> $env.numd?" | nu-highlight | print

$env.numd? | table | print; print ''

"```" | print

"" | print
"```nushell" | print
"[[a b c]; [1 2 3]]" | nu-highlight | print

"```\n```output-numd" | print

[[a b c]; [1 2 3]] | table | print; print ''

"```" | print

"" | print
"```nushell" | print
"[[column long_text];\n\n['value_1' ('Veniam cillum et et. Et et qui enim magna. Qui enim, magna eu aute lorem.' +\n                'Eu aute lorem ullamco sed ipsum incididunt irure. Lorem ullamco sed ipsum incididunt.' +\n                'Sed ipsum incididunt irure, culpa. Irure, culpa labore sit sunt.')]\n\n['value_2' ('Irure quis magna ipsum anim. Magna ipsum anim aliquip elit lorem ut. Anim aliquip ' +\n                'elit lorem, ut quis nostrud. Lorem ut quis, nostrud commodo non. Nostrud commodo non ' +\n                'cillum exercitation dolore fugiat nulla. Non cillum exercitation dolore fugiat nulla ' +\n                'ut. Exercitation dolore fugiat nulla ut adipiscing laboris elit. Fugiat nulla ut ' +\n                'adipiscing, laboris elit quis pariatur. Adipiscing laboris elit quis pariatur. ' +\n                'Elit quis pariatur, in ut anim anim ut.')]\n]" | nu-highlight | print

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
] | table | print; print ''

"```" | print
