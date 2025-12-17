# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd

const init_numd_pwd_const = '/Users/user/git/numd'

# numd config loaded from `numd_config_example1.nu`

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
```nu" | print
"[bell book candle] | where ($it =~ 'b')" | nu-highlight | print

[bell book candle] | where ($it =~ 'b') | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"```" | print

"#code-block-marker-open-3
```nu" | print
"[1, 2, 3, 4] | insert 2 10" | nu-highlight | print

[1, 2, 3, 4] | insert 2 10 | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"# [1, 2, 10, 3, 4]" | nu-highlight | print


"```" | print

"#code-block-marker-open-5
```nu" | print
"[1, 2, 3, 4] | update 1 10" | nu-highlight | print

[1, 2, 3, 4] | update 1 10 | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"# [1, 10, 3, 4]" | nu-highlight | print


"```" | print

"#code-block-marker-open-7
```nu" | print
"let colors = [yellow green]
let colors = ($colors | prepend red)
let colors = ($colors | append purple)
let colors = (\"black\" | append $colors)
$colors # [black red yellow green purple blue]" | nu-highlight | print

let colors = [yellow green]
let colors = ($colors | prepend red)
let colors = ($colors | append purple)
let colors = ("black" | append $colors)
$colors | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"```" | print

"#code-block-marker-open-9
```nu" | print
"let colors = [red yellow green purple]
let colors = ($colors | skip 1)
let colors = ($colors | drop 2)
$colors # [yellow]" | nu-highlight | print

let colors = [red yellow green purple]
let colors = ($colors | skip 1)
let colors = ($colors | drop 2)
$colors | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"```" | print

"#code-block-marker-open-11
```nu" | print
"let colors = [red yellow green purple black magenta]
let colors = ($colors | last 3)
$colors # [purple black magenta]" | nu-highlight | print

let colors = [red yellow green purple black magenta]
let colors = ($colors | last 3)
$colors | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"```" | print

"#code-block-marker-open-13
```nu" | print
"let colors = [yellow green purple]
let colors = ($colors | first 2)
$colors # [yellow green]" | nu-highlight | print

let colors = [yellow green purple]
let colors = ($colors | first 2)
$colors | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"```" | print

"#code-block-marker-open-15
```nu" | print
"let x = [1 2]
[ ...$x 3 ...(4..7 | take 2) ]" | nu-highlight | print

let x = [1 2]
[ ...$x 3 ...(4..7 | take 2) ] | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"```" | print

"#code-block-marker-open-17
```nu" | print
"let names = [Mark Tami Amanda Jeremy]
$names | each { |elt| $\"Hello, ($elt)!\" }
# Outputs \"Hello, Mark!\" and three more similar lines." | nu-highlight | print

let names = [Mark Tami Amanda Jeremy]
$names | each { |elt| $"Hello, ($elt)!" } | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"$names | enumerate | each { |elt| $\"($elt.index + 1) - ($elt.item)\" }
# Outputs \"1 - Mark\", \"2 - Tami\", etc." | nu-highlight | print

$names | enumerate | each { |elt| $"($elt.index + 1) - ($elt.item)" } | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"```" | print

"#code-block-marker-open-19
```nu" | print
"let colors = [red orange yellow green blue purple]
$colors | where ($it | str ends-with 'e')
# The block passed to `where` must evaluate to a boolean.
# This outputs the list [orange blue purple]." | nu-highlight | print

let colors = [red orange yellow green blue purple]
$colors | where ($it | str ends-with 'e')
# The block passed to `where` must evaluate to a boolean.
print ''
"```" | print

"#code-block-marker-open-21
```nu" | print
"let scores = [7 10 8 6 7]
$scores | where $it > 7 # [10 8]" | nu-highlight | print

let scores = [7 10 8 6 7]
$scores | where $it > 7 | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"```" | print

"#code-block-marker-open-23
```nu" | print
"let scores = [3 8 4]
$\"total = ($scores | reduce { |elt, acc| $acc + $elt })\" # total = 15
$\"total = ($scores | math sum)\" # easier approach, same result
$\"product = ($scores | reduce --fold 1 { |elt, acc| $acc * $elt })\" # product = 96
$scores | enumerate | reduce --fold 0 { |elt, acc| $acc + $elt.index * $elt.item } # 0*3 + 1*8 + 2*4 = 16" | nu-highlight | print

let scores = [3 8 4]
$"total = ($scores | reduce { |elt, acc| $acc + $elt })" # total = 15
$"total = ($scores | math sum)" # easier approach, same result
$"product = ($scores | reduce --fold 1 { |elt, acc| $acc * $elt })" # product = 96
$scores | enumerate | reduce --fold 0 { |elt, acc| $acc + $elt.index * $elt.item } | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"```" | print

"#code-block-marker-open-25
```nu" | print
"let names = [Mark Tami Amanda Jeremy]
$names.1 # gives Tami" | nu-highlight | print

let names = [Mark Tami Amanda Jeremy]
$names.1 | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"```" | print

"#code-block-marker-open-27
```nu" | print
"let names = [Mark Tami Amanda Jeremy]
let index = 1
$names | get $index # gives Tami" | nu-highlight | print

let names = [Mark Tami Amanda Jeremy]
let index = 1
$names | get $index | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"```" | print

"#code-block-marker-open-29
```nu" | print
"let colors = [red green blue]
$colors | is-empty # false" | nu-highlight | print

let colors = [red green blue]
$colors | is-empty | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"let colors = []
$colors | is-empty # true" | nu-highlight | print

let colors = []
$colors | is-empty | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"```" | print

"#code-block-marker-open-31
```nu" | print
"let colors = [red green blue]
'blue' in $colors # true
'yellow' in $colors # false
'gold' not-in $colors # true" | nu-highlight | print

let colors = [red green blue]
'blue' in $colors # true
'yellow' in $colors # false
'gold' not-in $colors | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"```" | print

"#code-block-marker-open-33
```nu" | print
"let colors = [red green blue]
# Do any color names end with \"e\"?
$colors | any {|elt| $elt | str ends-with \"e\" } # true" | nu-highlight | print

let colors = [red green blue]
# Do any color names end with "e"?
$colors | any {|elt| $elt | str ends-with "e" } | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"# Is the length of any color name less than 3?
$colors | any {|elt| ($elt | str length) < 3 } # false" | nu-highlight | print

# Is the length of any color name less than 3?
$colors | any {|elt| ($elt | str length) < 3 } | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"let scores = [3 8 4]
# Are any scores greater than 7?
$scores | any {|elt| $elt > 7 } # true" | nu-highlight | print

let scores = [3 8 4]
# Are any scores greater than 7?
$scores | any {|elt| $elt > 7 } | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"# Are any scores odd?
$scores | any {|elt| $elt mod 2 == 1 } # true" | nu-highlight | print

# Are any scores odd?
$scores | any {|elt| $elt mod 2 == 1 } | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"```" | print

"#code-block-marker-open-35
```nu" | print
"let colors = [red green blue]
# Do all color names end with \"e\"?
$colors | all {|elt| $elt | str ends-with \"e\" } # false" | nu-highlight | print

let colors = [red green blue]
# Do all color names end with "e"?
$colors | all {|elt| $elt | str ends-with "e" } | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"# Is the length of all color names greater than or equal to 3?
$colors | all {|elt| ($elt | str length) >= 3 } # true" | nu-highlight | print

# Is the length of all color names greater than or equal to 3?
$colors | all {|elt| ($elt | str length) >= 3 } | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"let scores = [3 8 4]
# Are all scores greater than 7?
$scores | all {|elt| $elt > 7 } # false" | nu-highlight | print

let scores = [3 8 4]
# Are all scores greater than 7?
$scores | all {|elt| $elt > 7 } | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"# Are all scores even?
$scores | all {|elt| $elt mod 2 == 0 } # false" | nu-highlight | print

# Are all scores even?
$scores | all {|elt| $elt mod 2 == 0 } | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"```" | print

"#code-block-marker-open-37
```nu" | print
"[1 [2 3] 4 [5 6]] | flatten # [1 2 3 4 5 6]" | nu-highlight | print

[1 [2 3] 4 [5 6]] | flatten | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"[[1 2] [3 [4 5 [6 7 8]]]] | flatten | flatten | flatten # [1 2 3 4 5 6 7 8]" | nu-highlight | print

[[1 2] [3 [4 5 [6 7 8]]]] | flatten | flatten | flatten | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"```" | print

"#code-block-marker-open-39
```nu" | print
"let zones = [UTC CET Europe/Moscow Asia/Yekaterinburg]
# Show world clock for selected time zones
let base_time = '2024-01-15 12:00:00' | into datetime --timezone UTC
$zones | wrap 'Zone' | upsert Time {|row| ($base_time | date to-timezone $row.Zone | format date '%Y.%m.%d %H:%M')}" | nu-highlight | print

let zones = [UTC CET Europe/Moscow Asia/Yekaterinburg]
# Show world clock for selected time zones
let base_time = '2024-01-15 12:00:00' | into datetime --timezone UTC
$zones | wrap 'Zone' | upsert Time {|row| ($base_time | date to-timezone $row.Zone | format date '%Y.%m.%d %H:%M')} | table --width ($env.numd?.table-width? | default 120) | default '' | into string | lines | each {$'# => ($in)' | str trim --right} | str join (char nl) | str replace -r '\s*$' "\n" | print; print ''
print ''
"```" | print
