# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd

const init_numd_pwd_const = '/Users/user/git/numd'

# numd config loaded from `/Users/user/git/numd/numd_config_example1.yaml`

$env.config.footer_mode = 'always';
$env.config.table = {mode: rounded, index_mode: never,
show_empty: false, padding: {left: 1, right: 1},
trim: {methodology: truncating, wrapping_try_keep_words: false, truncating_suffix: ...},
header_on_separator: true, abbreviated_row_count: 1000}

"#code-block-marker-open-1
```nu" | print
"> [1, 2, 3, 4] | insert 2 10" | nu-highlight | print

[1, 2, 3, 4] | insert 2 10 | table | print; print ''

"# [1, 2, 10, 3, 4]" | nu-highlight | print


"```" | print

"#code-block-marker-open-3
```nu" | print
"> [1, 2, 3, 4] | update 1 10" | nu-highlight | print

[1, 2, 3, 4] | update 1 10 | table | print; print ''

"# [1, 10, 3, 4]" | nu-highlight | print


"```" | print

"#code-block-marker-open-5
```nu" | print
"let colors = [yellow green]
let colors = ($colors | prepend red)
let colors = ($colors | append purple)
let colors = ($colors ++ \"blue\")
let colors = (\"black\" ++ $colors)
$colors # [black red yellow green purple blue]" | nu-highlight | print

"```\n```output-numd" | print

let colors = [yellow green]
let colors = ($colors | prepend red)
let colors = ($colors | append purple)
let colors = ($colors ++ "blue")
let colors = ("black" ++ $colors)
$colors | table | print; print ''

"```" | print

"#code-block-marker-open-8
```nu" | print
"let colors = [red yellow green purple]
let colors = ($colors | skip 1)
let colors = ($colors | drop 2)
$colors # [yellow]" | nu-highlight | print

"```\n```output-numd" | print

let colors = [red yellow green purple]
let colors = ($colors | skip 1)
let colors = ($colors | drop 2)
$colors | table | print; print ''

"```" | print

"#code-block-marker-open-11
```nu" | print
"let colors = [red yellow green purple black magenta]
let colors = ($colors | last 3)
$colors # [purple black magenta]" | nu-highlight | print

"```\n```output-numd" | print

let colors = [red yellow green purple black magenta]
let colors = ($colors | last 3)
$colors | table | print; print ''

"```" | print

"#code-block-marker-open-14
```nu" | print
"let colors = [yellow green purple]
let colors = ($colors | first 2)
$colors # [yellow green]" | nu-highlight | print

"```\n```output-numd" | print

let colors = [yellow green purple]
let colors = ($colors | first 2)
$colors | table | print; print ''

"```" | print

"#code-block-marker-open-17
```nu" | print
"let names = [Mark Tami Amanda Jeremy]
$names | each { |it| $\"Hello, ($it)!\" }
# Outputs \"Hello, Mark!\" and three more similar lines.

$names | enumerate | each { |it| $\"($it.index + 1) - ($it.item)\" }
# Outputs \"1 - Mark\", \"2 - Tami\", etc." | nu-highlight | print

"```\n```output-numd" | print

let names = [Mark Tami Amanda Jeremy]
$names | each { |it| $"Hello, ($it)!" }
# Outputs "Hello, Mark!" and three more similar lines.

$names | enumerate | each { |it| $"($it.index + 1) - ($it.item)" } | table | print; print ''

"```" | print

"#code-block-marker-open-20
```nu" | print
"let colors = [red orange yellow green blue purple]
$colors | where ($it | str ends-with 'e')
# The block passed to `where` must evaluate to a boolean.
# This outputs the list [orange blue purple]." | nu-highlight | print

"```\n```output-numd" | print

let colors = [red orange yellow green blue purple]
$colors | where ($it | str ends-with 'e')
# The block passed to `where` must evaluate to a boolean.

"```" | print

"#code-block-marker-open-22
```nu" | print
"let scores = [7 10 8 6 7]
$scores | where $it > 7 # [10 8]" | nu-highlight | print

"```\n```output-numd" | print

let scores = [7 10 8 6 7]
$scores | where $it > 7 | table | print; print ''

"```" | print

"#code-block-marker-open-25
```nu" | print
"let scores = [3 8 4]
$\"total = ($scores | reduce { |it, acc| $acc + $it })\" # total = 15

$\"total = ($scores | math sum)\" # easier approach, same result

$\"product = ($scores | reduce --fold 1 { |it, acc| $acc * $it })\" # product = 96

$scores | enumerate | reduce --fold 0 { |it, acc| $acc + $it.index * $it.item } # 0*3 + 1*8 + 2*4 = 16" | nu-highlight | print

"```\n```output-numd" | print

let scores = [3 8 4]
$"total = ($scores | reduce { |it, acc| $acc + $it })" # total = 15

$"total = ($scores | math sum)" # easier approach, same result

$"product = ($scores | reduce --fold 1 { |it, acc| $acc * $it })" # product = 96

$scores | enumerate | reduce --fold 0 { |it, acc| $acc + $it.index * $it.item } | table | print; print ''

"```" | print

"#code-block-marker-open-28
```nu" | print
"let names = [Mark Tami Amanda Jeremy]
$names.1 # gives Tami" | nu-highlight | print

"```\n```output-numd" | print

let names = [Mark Tami Amanda Jeremy]
$names.1 | table | print; print ''

"```" | print

"#code-block-marker-open-31
```nu" | print
"let names = [Mark Tami Amanda Jeremy]
let index = 1
$names | get $index # gives Tami" | nu-highlight | print

"```\n```output-numd" | print

let names = [Mark Tami Amanda Jeremy]
let index = 1
$names | get $index | table | print; print ''

"```" | print

"#code-block-marker-open-34
```nu" | print
"let colors = [red green blue]
$colors | is-empty # false

let colors = []
$colors | is-empty # true" | nu-highlight | print

"```\n```output-numd" | print

let colors = [red green blue]
$colors | is-empty # false

let colors = []
$colors | is-empty | table | print; print ''

"```" | print

"#code-block-marker-open-37
```nu" | print
"let colors = [red green blue]
'blue' in $colors # true
'yellow' in $colors # false
'gold' not-in $colors # true" | nu-highlight | print

"```\n```output-numd" | print

let colors = [red green blue]
'blue' in $colors # true
'yellow' in $colors # false
'gold' not-in $colors | table | print; print ''

"```" | print

"#code-block-marker-open-40
```nu" | print
"let colors = [red green blue]
# Do any color names end with \"e\"?
$colors | any {|it| $it | str ends-with \"e\" } # true

# Is the length of any color name less than 3?
$colors | any {|it| ($it | str length) < 3 } # false

let scores = [3 8 4]
# Are any scores greater than 7?
$scores | any {|it| $it > 7 } # true

# Are any scores odd?
$scores | any {|it| $it mod 2 == 1 } # true" | nu-highlight | print

"```\n```output-numd" | print

let colors = [red green blue]
# Do any color names end with "e"?
$colors | any {|it| $it | str ends-with "e" } # true

# Is the length of any color name less than 3?
$colors | any {|it| ($it | str length) < 3 } # false

let scores = [3 8 4]
# Are any scores greater than 7?
$scores | any {|it| $it > 7 } # true

# Are any scores odd?
$scores | any {|it| $it mod 2 == 1 } | table | print; print ''

"```" | print

"#code-block-marker-open-43
```nu" | print
"let colors = [red green blue]
# Do all color names end with \"e\"?
$colors | all {|it| $it | str ends-with \"e\" } # false

# Is the length of all color names greater than or equal to 3?
$colors | all {|it| ($it | str length) >= 3 } # true

let scores = [3 8 4]
# Are all scores greater than 7?
$scores | all {|it| $it > 7 } # false

# Are all scores even?
$scores | all {|it| $it mod 2 == 0 } # false" | nu-highlight | print

"```\n```output-numd" | print

let colors = [red green blue]
# Do all color names end with "e"?
$colors | all {|it| $it | str ends-with "e" } # false

# Is the length of all color names greater than or equal to 3?
$colors | all {|it| ($it | str length) >= 3 } # true

let scores = [3 8 4]
# Are all scores greater than 7?
$scores | all {|it| $it > 7 } # false

# Are all scores even?
$scores | all {|it| $it mod 2 == 0 } | table | print; print ''

"```" | print

"#code-block-marker-open-46
```nu" | print
"[1 [2 3] 4 [5 6]] | flatten # [1 2 3 4 5 6]

[[1 2] [3 [4 5 [6 7 8]]]] | flatten | flatten | flatten" | nu-highlight | print

"```\n```output-numd" | print

[1 [2 3] 4 [5 6]] | flatten # [1 2 3 4 5 6]

[[1 2] [3 [4 5 [6 7 8]]]] | flatten | flatten | flatten | table | print; print ''

"```" | print

"#code-block-marker-open-49
```nu no-run" | print
"> let zones = [UTC CET Europe/Moscow Asia/Yekaterinburg]" | nu-highlight | print

let zones = [UTC CET Europe/Moscow Asia/Yekaterinburg]

"# Show world clock for selected time zones" | nu-highlight | print


"> $zones | wrap 'Zone' | upsert Time {|it| (date now | date to-timezone $it.Zone | format date '%Y.%m.%d %H:%M')}" | nu-highlight | print

$zones | wrap 'Zone' | upsert Time {|it| (date now | date to-timezone $it.Zone | format date '%Y.%m.%d %H:%M')} | table | print; print ''

"```" | print
