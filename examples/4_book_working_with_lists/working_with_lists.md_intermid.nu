# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd
cd /Users/user/git/numd
const init_numd_pwd_const = '/Users/user/git/numd'
print "###code-block-starting-line-in-original-md-13"
print "```nu"
print ("> [1, 2, 3, 4] \| insert 2 10" | nu-highlight)
[1, 2, 3, 4] | insert 2 10 | print; print ''

print ("\# [1, 2, 10, 3, 4]" | nu-highlight)

print "```"
print "###code-block-starting-line-in-original-md-28"
print "```nu"
print ("> [1, 2, 3, 4] \| update 1 10" | nu-highlight)
[1, 2, 3, 4] | update 1 10 | print; print ''

print ("\# [1, 10, 3, 4]" | nu-highlight)

print "```"
print "###code-block-starting-line-in-original-md-46"
print "```nu"
print ("let colors = [yellow green]
let colors = \(\$colors \| prepend red\)
let colors = \(\$colors \| append purple\)
let colors = \(\$colors ++ \"blue\"\)
let colors = \(\"black\" ++ \$colors\)
\$colors \# [black red yellow green purple blue]" | nu-highlight)
print '```
```output-numd'
let colors = [yellow green]
let colors = ($colors | prepend red)
let colors = ($colors | append purple)
let colors = ($colors ++ "blue")
let colors = ("black" ++ $colors)
$colors | print; print ''

print "```"
print "###code-block-starting-line-in-original-md-67"
print "```nu"
print ("let colors = [red yellow green purple]
let colors = \(\$colors \| skip 1\)
let colors = \(\$colors \| drop 2\)
\$colors \# [yellow]" | nu-highlight)
print '```
```output-numd'
let colors = [red yellow green purple]
let colors = ($colors | skip 1)
let colors = ($colors | drop 2)
$colors | print; print ''

print "```"
print "###code-block-starting-line-in-original-md-81"
print "```nu"
print ("let colors = [red yellow green purple black magenta]
let colors = \(\$colors \| last 3\)
\$colors \# [purple black magenta]" | nu-highlight)
print '```
```output-numd'
let colors = [red yellow green purple black magenta]
let colors = ($colors | last 3)
$colors | print; print ''

print "```"
print "###code-block-starting-line-in-original-md-96"
print "```nu"
print ("let colors = [yellow green purple]
let colors = \(\$colors \| first 2\)
\$colors \# [yellow green]" | nu-highlight)
print '```
```output-numd'
let colors = [yellow green purple]
let colors = ($colors | first 2)
$colors | print; print ''

print "```"
print "###code-block-starting-line-in-original-md-114"
print "```nu"
print ("let names = [Mark Tami Amanda Jeremy]
\$names \| each \{ \|it\| \$\"Hello, \(\$it\)!\" \}
\# Outputs \"Hello, Mark!\" and three more similar lines.

\$names \| enumerate \| each \{ \|it\| \$\"\(\$it.index + 1\) - \(\$it.item\)\" \}
\# Outputs \"1 - Mark\", \"2 - Tami\", etc." | nu-highlight)
print '```
```output-numd'
let names = [Mark Tami Amanda Jeremy]
$names | each { |it| $"Hello, ($it)!" }
# Outputs "Hello, Mark!" and three more similar lines.

$names | enumerate | each { |it| $"($it.index + 1) - ($it.item)" } | print; print ''

print "```"
print "###code-block-starting-line-in-original-md-135"
print "```nu"
print ("let colors = [red orange yellow green blue purple]
\$colors \| where \(\$it \| str ends-with \'e\'\)
\# The block passed to `where` must evaluate to a boolean.
\# This outputs the list [orange blue purple]." | nu-highlight)
print '```
```output-numd'
let colors = [red orange yellow green blue purple]
$colors | where ($it | str ends-with 'e')
# The block passed to `where` must evaluate to a boolean. | print; print ''

print "```"
print "###code-block-starting-line-in-original-md-144"
print "```nu"
print ("let scores = [7 10 8 6 7]
\$scores \| where \$it > 7 \# [10 8]" | nu-highlight)
print '```
```output-numd'
let scores = [7 10 8 6 7]
$scores | where $it > 7 | print; print ''

print "```"
print "###code-block-starting-line-in-original-md-161"
print "```nu"
print ("let scores = [3 8 4]
\$\"total = \(\$scores \| reduce \{ \|it, acc\| \$acc + \$it \}\)\" \# total = 15

\$\"total = \(\$scores \| math sum\)\" \# easier approach, same result

\$\"product = \(\$scores \| reduce --fold 1 \{ \|it, acc\| \$acc * \$it \}\)\" \# product = 96

\$scores \| enumerate \| reduce --fold 0 \{ \|it, acc\| \$acc + \$it.index * \$it.item \} \# 0*3 + 1*8 + 2*4 = 16" | nu-highlight)
print '```
```output-numd'
let scores = [3 8 4]
$"total = ($scores | reduce { |it, acc| $acc + $it })" # total = 15

$"total = ($scores | math sum)" # easier approach, same result

$"product = ($scores | reduce --fold 1 { |it, acc| $acc * $it })" # product = 96

$scores | enumerate | reduce --fold 0 { |it, acc| $acc + $it.index * $it.item } | print; print ''

print "```"
print "###code-block-starting-line-in-original-md-181"
print "```nu"
print ("let names = [Mark Tami Amanda Jeremy]
\$names.1 \# gives Tami" | nu-highlight)
print '```
```output-numd'
let names = [Mark Tami Amanda Jeremy]
$names.1 | print; print ''

print "```"
print "###code-block-starting-line-in-original-md-191"
print "```nu"
print ("let names = [Mark Tami Amanda Jeremy]
let index = 1
\$names \| get \$index \# gives Tami" | nu-highlight)
print '```
```output-numd'
let names = [Mark Tami Amanda Jeremy]
let index = 1
$names | get $index | print; print ''

print "```"
print "###code-block-starting-line-in-original-md-206"
print "```nu"
print ("let colors = [red green blue]
\$colors \| is-empty \# false

let colors = []
\$colors \| is-empty \# true" | nu-highlight)
print '```
```output-numd'
let colors = [red green blue]
$colors | is-empty # false

let colors = []
$colors | is-empty | print; print ''

print "```"
print "###code-block-starting-line-in-original-md-219"
print "```nu"
print ("let colors = [red green blue]
\'blue\' in \$colors \# true
\'yellow\' in \$colors \# false
\'gold\' not-in \$colors \# true" | nu-highlight)
print '```
```output-numd'
let colors = [red green blue]
'blue' in $colors # true
'yellow' in $colors # false
'gold' not-in $colors | print; print ''

print "```"
print "###code-block-starting-line-in-original-md-233"
print "```nu"
print ("let colors = [red green blue]
\# Do any color names end with \"e\"?
\$colors \| any \{\|it\| \$it \| str ends-with \"e\" \} \# true

\# Is the length of any color name less than 3?
\$colors \| any \{\|it\| \(\$it \| str length\) < 3 \} \# false

let scores = [3 8 4]
\# Are any scores greater than 7?
\$scores \| any \{\|it\| \$it > 7 \} \# true

\# Are any scores odd?
\$scores \| any \{\|it\| \$it mod 2 == 1 \} \# true" | nu-highlight)
print '```
```output-numd'
let colors = [red green blue]
# Do any color names end with "e"?
$colors | any {|it| $it | str ends-with "e" } # true

# Is the length of any color name less than 3?
$colors | any {|it| ($it | str length) < 3 } # false

let scores = [3 8 4]
# Are any scores greater than 7?
$scores | any {|it| $it > 7 } # true

# Are any scores odd?
$scores | any {|it| $it mod 2 == 1 } | print; print ''

print "```"
print "###code-block-starting-line-in-original-md-256"
print "```nu"
print ("let colors = [red green blue]
\# Do all color names end with \"e\"?
\$colors \| all \{\|it\| \$it \| str ends-with \"e\" \} \# false

\# Is the length of all color names greater than or equal to 3?
\$colors \| all \{\|it\| \(\$it \| str length\) >= 3 \} \# true

let scores = [3 8 4]
\# Are all scores greater than 7?
\$scores \| all \{\|it\| \$it > 7 \} \# false

\# Are all scores even?
\$scores \| all \{\|it\| \$it mod 2 == 0 \} \# false" | nu-highlight)
print '```
```output-numd'
let colors = [red green blue]
# Do all color names end with "e"?
$colors | all {|it| $it | str ends-with "e" } # false

# Is the length of all color names greater than or equal to 3?
$colors | all {|it| ($it | str length) >= 3 } # true

let scores = [3 8 4]
# Are all scores greater than 7?
$scores | all {|it| $it > 7 } # false

# Are all scores even?
$scores | all {|it| $it mod 2 == 0 } | print; print ''

print "```"
print "###code-block-starting-line-in-original-md-282"
print "```nu"
print ("[1 [2 3] 4 [5 6]] \| flatten \# [1 2 3 4 5 6]

[[1 2] [3 [4 5 [6 7 8]]]] \| flatten \| flatten \| flatten" | nu-highlight)
print '```
```output-numd'
[1 [2 3] 4 [5 6]] | flatten # [1 2 3 4 5 6]

[[1 2] [3 [4 5 [6 7 8]]]] | flatten | flatten | flatten | print; print ''

print "```"
print "###code-block-starting-line-in-original-md-303"
print "```nu"
print ("let zones = [UTC CET Europe\/Moscow Asia\/Yekaterinburg]

\# Show world clock for selected time zones
\$zones \| wrap \'Zone\' \| upsert Time \{\|it\| \(date now \| date to-timezone \$it.Zone \| format date \'%Y.%m.%d %H:%M\'\)\}" | nu-highlight)
print '```
```output-numd'
let zones = [UTC CET Europe/Moscow Asia/Yekaterinburg]

# Show world clock for selected time zones
$zones | wrap 'Zone' | upsert Time {|it| (date now | date to-timezone $it.Zone | format date '%Y.%m.%d %H:%M')} | print; print ''

print "```"