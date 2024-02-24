print `###nudoc-block-1`
print ("> [1, 2, 3, 4] | insert 2 10" | nu-highlight)
do {nu -c "[1, 2, 3, 4] | insert 2 10"} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print ("# [1, 2, 10, 3, 4]" | nu-highlight)

print `###nudoc-block-4`
print ("> [1, 2, 3, 4] | update 1 10" | nu-highlight)
do {nu -c "[1, 2, 3, 4] | update 1 10"} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print ("# [1, 10, 3, 4]" | nu-highlight)

print `###nudoc-block-7`
print ("let colors = [yellow green]
let colors = ($colors | prepend red)
let colors = ($colors | append purple)
let colors = ($colors ++ \"blue\")
let colors = (\"black\" ++ $colors)
$colors # [black red yellow green purple blue]" | nu-highlight)
print '```
```nudoc-output'
let colors = [yellow green]
let colors = ($colors | prepend red)
let colors = ($colors | append purple)
let colors = ($colors ++ "blue")
let colors = ("black" ++ $colors)
$colors | print $in
print `###nudoc-block-10`
print ("let colors = [red yellow green purple]
let colors = ($colors | skip 1)
let colors = ($colors | drop 2)
$colors # [yellow]" | nu-highlight)
print '```
```nudoc-output'
let colors = [red yellow green purple]
let colors = ($colors | skip 1)
let colors = ($colors | drop 2)
$colors | print $in
print `###nudoc-block-13`
print ("let colors = [red yellow green purple black magenta]
let colors = ($colors | last 3)
$colors # [purple black magenta]" | nu-highlight)
print '```
```nudoc-output'
let colors = [red yellow green purple black magenta]
let colors = ($colors | last 3)
$colors | print $in
print `###nudoc-block-16`
print ("let colors = [yellow green purple]
let colors = ($colors | first 2)
$colors # [yellow green]" | nu-highlight)
print '```
```nudoc-output'
let colors = [yellow green purple]
let colors = ($colors | first 2)
$colors | print $in
print `###nudoc-block-19`
print ("let names = [Mark Tami Amanda Jeremy]
$names | each { |it| $\"Hello, ($it)!\" }
# Outputs \"Hello, Mark!\" and three more similar lines.

$names | enumerate | each { |it| $\"($it.index + 1) - ($it.item)\" }
# Outputs \"1 - Mark\", \"2 - Tami\", etc." | nu-highlight)
print '```
```nudoc-output'
let names = [Mark Tami Amanda Jeremy]
$names | each { |it| $"Hello, ($it)!" }

$names | enumerate | each { |it| $"($it.index + 1) - ($it.item)" } | print $in
print `###nudoc-block-22`
print ("let colors = [red orange yellow green blue purple]
$colors | where ($it | str ends-with 'e')
# The block passed to `where` must evaluate to a boolean.
# This outputs the list [orange blue purple]." | nu-highlight)
print '```
```nudoc-output'
let colors = [red orange yellow green blue purple]
$colors | where ($it | str ends-with 'e')
print `###nudoc-block-25`
print ("let scores = [7 10 8 6 7]
$scores | where $it > 7 # [10 8]" | nu-highlight)
print '```
```nudoc-output'
let scores = [7 10 8 6 7]
$scores | where $it > 7 | print $in
print `###nudoc-block-28`
print ("let scores = [3 8 4]
$\"total = ($scores | reduce { |it, acc| $acc + $it })\" # total = 15

$\"total = ($scores | math sum)\" # easier approach, same result

$\"product = ($scores | reduce --fold 1 { |it, acc| $acc * $it })\" # product = 96

$scores | enumerate | reduce --fold 0 { |it, acc| $acc + $it.index * $it.item } # 0*3 + 1*8 + 2*4 = 16" | nu-highlight)
print '```
```nudoc-output'
let scores = [3 8 4]
$"total = ($scores | reduce { |it, acc| $acc + $it })"

$"total = ($scores | math sum)"

$"product = ($scores | reduce --fold 1 { |it, acc| $acc * $it })"

$scores | enumerate | reduce --fold 0 { |it, acc| $acc + $it.index * $it.item } | print $in
print `###nudoc-block-31`
print ("let names = [Mark Tami Amanda Jeremy]
$names.1 # gives Tami" | nu-highlight)
print '```
```nudoc-output'
let names = [Mark Tami Amanda Jeremy]
$names.1 | print $in
print `###nudoc-block-34`
print ("let names = [Mark Tami Amanda Jeremy]
let index = 1
$names | get $index # gives Tami" | nu-highlight)
print '```
```nudoc-output'
let names = [Mark Tami Amanda Jeremy]
let index = 1
$names | get $index | print $in
print `###nudoc-block-37`
print ("let colors = [red green blue]
$colors | is-empty # false

let colors = []
$colors | is-empty # true" | nu-highlight)
print '```
```nudoc-output'
let colors = [red green blue]
$colors | is-empty

let colors = []
$colors | is-empty | print $in
print `###nudoc-block-40`
print ("let colors = [red green blue]
'blue' in $colors # true
'yellow' in $colors # false
'gold' not-in $colors # true" | nu-highlight)
print '```
```nudoc-output'
let colors = [red green blue]
'blue' in $colors
'yellow' in $colors
'gold' not-in $colors | print $in
print `###nudoc-block-43`
print ("let colors = [red green blue]
# Do any color names end with \"e\"?
$colors | any {|it| $it | str ends-with \"e\" } # true

# Is the length of any color name less than 3?
$colors | any {|it| ($it | str length) < 3 } # false

let scores = [3 8 4]
# Are any scores greater than 7?
$scores | any {|it| $it > 7 } # true

# Are any scores odd?
$scores | any {|it| $it mod 2 == 1 } # true" | nu-highlight)
print '```
```nudoc-output'
let colors = [red green blue]
$colors | any {|it| $it | str ends-with "e" }
$colors | any {|it| ($it | str length) < 3 }

let scores = [3 8 4]
$scores | any {|it| $it > 7 }
$scores | any {|it| $it mod 2 == 1 } | print $in
print `###nudoc-block-46`
print ("let colors = [red green blue]
# Do all color names end with \"e\"?
$colors | all {|it| $it | str ends-with \"e\" } # false

# Is the length of all color names greater than or equal to 3?
$colors | all {|it| ($it | str length) >= 3 } # true

let scores = [3 8 4]
# Are all scores greater than 7?
$scores | all {|it| $it > 7 } # false

# Are all scores even?
$scores | all {|it| $it mod 2 == 0 } # false" | nu-highlight)
print '```
```nudoc-output'
let colors = [red green blue]
$colors | all {|it| $it | str ends-with "e" }
$colors | all {|it| ($it | str length) >= 3 }

let scores = [3 8 4]
$scores | all {|it| $it > 7 }
$scores | all {|it| $it mod 2 == 0 } | print $in
print `###nudoc-block-49`
print ("[1 [2 3] 4 [5 6]] | flatten # [1 2 3 4 5 6]

[[1 2] [3 [4 5 [6 7 8]]]] | flatten | flatten | flatten" | nu-highlight)
print '```
```nudoc-output'
[1 [2 3] 4 [5 6]] | flatten

[[1 2] [3 [4 5 [6 7 8]]]] | flatten | flatten | flatten | print $in
print `###nudoc-block-52`
print ("let zones = [UTC CET Europe/Moscow Asia/Yekaterinburg]

# Show world clock for selected time zones
$zones | wrap 'Zone' | upsert Time {|it| (date now | date to-timezone $it.Zone | format date '%Y.%m.%d %H:%M')}" | nu-highlight)
print '```
```nudoc-output'
let zones = [UTC CET Europe/Moscow Asia/Yekaterinburg]
$zones | wrap 'Zone' | upsert Time {|it| (date now | date to-timezone $it.Zone | format date '%Y.%m.%d %H:%M')} | print $in