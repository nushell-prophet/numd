
    # ```nu
[bell book candle] | where ($it =~ 'b')


    # ```nu
[1, 2, 3, 4] | insert 2 10

# [1, 2, 10, 3, 4]


    # ```nu
[1, 2, 3, 4] | update 1 10

# [1, 10, 3, 4]


    # ```nu
let colors = [yellow green]
let colors = ($colors | prepend red)
let colors = ($colors | append purple)
let colors = ("black" | append $colors)
$colors # [black red yellow green purple blue]


    # ```nu
let colors = [red yellow green purple]
let colors = ($colors | skip 1)
let colors = ($colors | drop 2)
$colors # [yellow]


    # ```nu
let colors = [red yellow green purple black magenta]
let colors = ($colors | last 3)
$colors # [purple black magenta]


    # ```nu
let colors = [yellow green purple]
let colors = ($colors | first 2)
$colors # [yellow green]


    # ```nu
let x = [1 2]
[ ...$x 3 ...(4..7 | take 2) ]


    # ```nu
let names = [Mark Tami Amanda Jeremy]
$names | each { |elt| $"Hello, ($elt)!" }
# Outputs "Hello, Mark!" and three more similar lines.

$names | enumerate | each { |elt| $"($elt.index + 1) - ($elt.item)" }
# Outputs "1 - Mark", "2 - Tami", etc.


    # ```nu
let colors = [red orange yellow green blue purple]
$colors | where ($it | str ends-with 'e')
# The block passed to `where` must evaluate to a boolean.
# This outputs the list [orange blue purple].


    # ```nu
let scores = [7 10 8 6 7]
$scores | where $it > 7 # [10 8]


    # ```nu
let scores = [3 8 4]
$"total = ($scores | reduce { |elt, acc| $acc + $elt })" # total = 15
$"total = ($scores | math sum)" # easier approach, same result
$"product = ($scores | reduce --fold 1 { |elt, acc| $acc * $elt })" # product = 96
$scores | enumerate | reduce --fold 0 { |elt, acc| $acc + $elt.index * $elt.item } # 0*3 + 1*8 + 2*4 = 16


    # ```nu
let names = [Mark Tami Amanda Jeremy]
$names.1 # gives Tami


    # ```nu
let names = [Mark Tami Amanda Jeremy]
let index = 1
$names | get $index # gives Tami


    # ```nu
let colors = [red green blue]
$colors | is-empty # false

let colors = []
$colors | is-empty # true


    # ```nu
let colors = [red green blue]
'blue' in $colors # true
'yellow' in $colors # false
'gold' not-in $colors # true


    # ```nu
let colors = [red green blue]
# Do any color names end with "e"?
$colors | any {|elt| $elt | str ends-with "e" } # true

# Is the length of any color name less than 3?
$colors | any {|elt| ($elt | str length) < 3 } # false

let scores = [3 8 4]
# Are any scores greater than 7?
$scores | any {|elt| $elt > 7 } # true

# Are any scores odd?
$scores | any {|elt| $elt mod 2 == 1 } # true


    # ```nu
let colors = [red green blue]
# Do all color names end with "e"?
$colors | all {|elt| $elt | str ends-with "e" } # false

# Is the length of all color names greater than or equal to 3?
$colors | all {|elt| ($elt | str length) >= 3 } # true

let scores = [3 8 4]
# Are all scores greater than 7?
$scores | all {|elt| $elt > 7 } # false

# Are all scores even?
$scores | all {|elt| $elt mod 2 == 0 } # false


    # ```nu
[1 [2 3] 4 [5 6]] | flatten # [1 2 3 4 5 6]

[[1 2] [3 [4 5 [6 7 8]]]] | flatten | flatten | flatten # [1 2 3 4 5 6 7 8]


    # ```nu
let zones = [UTC CET Europe/Moscow Asia/Yekaterinburg]
# Show world clock for selected time zones
let base_time = '2024-01-15 12:00:00' | into datetime --timezone UTC
$zones | wrap 'Zone' | upsert Time {|row| ($base_time | date to-timezone $row.Zone | format date '%Y.%m.%d %H:%M')}
