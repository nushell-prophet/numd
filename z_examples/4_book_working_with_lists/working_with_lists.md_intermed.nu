# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd

const init_numd_pwd_const = '/Users/user/git/numd'

# numd config loaded from `/Users/user/git/numd/numd_config_example1.yaml`

$env.config.footer_mode = 'always';
$env.config.table = {mode: rounded, index_mode: never,
show_empty: false, padding: {left: 1, right: 1},
trim: {methodology: truncating, wrapping_try_keep_words: false, truncating_suffix: ...},
header_on_separator: true, abbreviated_row_count: 1000}

"# Working with lists

## Creating lists

A list is an ordered collection of values.
You can create a `list` with square brackets, surrounded values separated by spaces and/or commas (for readability).
For example, `[foo bar baz]` or `[foo, bar, baz]`.

## Updating lists

You can [`update`](/commands/docs/update.md) and [`insert`](/commands/docs/insert.md) values into lists as they flow through the pipeline, for example let's insert the value `10` into the middle of a list:
" | print
"```nu" | print
"> [1, 2, 3, 4] | insert 2 10" | nu-highlight | print

[1, 2, 3, 4] | insert 2 10 | table | print; print ''

"# [1, 2, 10, 3, 4]" | nu-highlight | print


"```" | print

"
We can also use [`update`](/commands/docs/update.md) to replace the 2nd element with the value `10`.
" | print
"```nu" | print
"> [1, 2, 3, 4] | update 1 10" | nu-highlight | print

[1, 2, 3, 4] | update 1 10 | table | print; print ''

"# [1, 10, 3, 4]" | nu-highlight | print


"```" | print

"
## Removing or adding items from list

In addition to [`insert`](/commands/docs/insert.md) and [`update`](/commands/docs/update.md), we also have [`prepend`](/commands/docs/prepend.md) and [`append`](/commands/docs/append.md). These let you insert to the beginning of a list or at the end of the list, respectively.

For example:
" | print
"```nu" | print
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

"
In case you want to remove items from list, there are many ways. [`skip`](/commands/docs/skip.md) allows you skip first rows from input, while [`drop`](/commands/docs/drop.md) allows you to skip specific numbered rows from end of list.
" | print
"```nu" | print
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

"
We also have [`last`](/commands/docs/last.md) and [`first`](/commands/docs/first.md) which allow you to [`take`](/commands/docs/take.md) from the end or beginning of the list, respectively.
" | print
"```nu" | print
"let colors = [red yellow green purple black magenta]
let colors = ($colors | last 3)
$colors # [purple black magenta]" | nu-highlight | print

"```\n```output-numd" | print

let colors = [red yellow green purple black magenta]
let colors = ($colors | last 3)
$colors | table | print; print ''

"```" | print

"
And from the beginning of a list,
" | print
"```nu" | print
"let colors = [yellow green purple]
let colors = ($colors | first 2)
$colors # [yellow green]" | nu-highlight | print

"```\n```output-numd" | print

let colors = [yellow green purple]
let colors = ($colors | first 2)
$colors | table | print; print ''

"```" | print

"
## Iterating over lists

To iterate over the items in a list, use the [`each`](/commands/docs/each.md) command with a [block](types_of_data.html#blocks)
of Nu code that specifies what to do to each item. The block parameter (e.g. `|it|` in `{ |it| print $it }`) is the current list
item, but the [`enumerate`](/commands/docs/enumerate.md) filter can be used to provide `index` and `item` values if needed. For example:
" | print
"```nu" | print
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

"
The [`where`](/commands/docs/where.md) command can be used to create a subset of a list, effectively filtering the list based on a condition.

The following example gets all the colors whose names end in \"e\".
" | print
"```nu" | print
"let colors = [red orange yellow green blue purple]
$colors | where ($it | str ends-with 'e')
# The block passed to `where` must evaluate to a boolean.
# This outputs the list [orange blue purple]." | nu-highlight | print

"```\n```output-numd" | print

let colors = [red orange yellow green blue purple]
$colors | where ($it | str ends-with 'e')
# The block passed to `where` must evaluate to a boolean.

"```" | print

"
In this example, we keep only values higher than `7`.
" | print
"```nu" | print
"let scores = [7 10 8 6 7]
$scores | where $it > 7 # [10 8]" | nu-highlight | print

"```\n```output-numd" | print

let scores = [7 10 8 6 7]
$scores | where $it > 7 | table | print; print ''

"```" | print

"
The [`reduce`](/commands/docs/reduce.md) command computes a single value from a list.
It uses a block which takes 2 parameters: the current item (conventionally named `it`) and an accumulator
(conventionally named `acc`). To specify an initial value for the accumulator, use the `--fold` (`-f`) flag.
To change `it` to have `index` and `item` values, use the [`enumerate`](/commands/docs/enumerate.md) filter.
For example:
" | print
"```nu" | print
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

"
## Accessing the list

To access a list item at a given index, use the `$name.index` form where `$name` is a variable that holds a list.

For example, the second element in the list below can be accessed with `$names.1`.
" | print
"```nu" | print
"let names = [Mark Tami Amanda Jeremy]
$names.1 # gives Tami" | nu-highlight | print

"```\n```output-numd" | print

let names = [Mark Tami Amanda Jeremy]
$names.1 | table | print; print ''

"```" | print

"
If the index is in some variable `$index` we can use the `get` command to extract the item from the list.
" | print
"```nu" | print
"let names = [Mark Tami Amanda Jeremy]
let index = 1
$names | get $index # gives Tami" | nu-highlight | print

"```\n```output-numd" | print

let names = [Mark Tami Amanda Jeremy]
let index = 1
$names | get $index | table | print; print ''

"```" | print

"
The [`length`](/commands/docs/length.md) command returns the number of items in a list.
For example, `[red green blue] | length` outputs `3`.

The [`is-empty`](/commands/docs/is-empty.md) command determines whether a string, list, or table is empty.
It can be used with lists as follows:
" | print
"```nu" | print
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

"
The `in` and `not-in` operators are used to test whether a value is in a list. For example:
" | print
"```nu" | print
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

"
The [`any`](/commands/docs/any.md) command determines if any item in a list
matches a given condition.
For example:
" | print
"```nu" | print
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

"
The [`all`](/commands/docs/all.md) command determines if every item in a list
matches a given condition.
For example:
" | print
"```nu" | print
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

"
## Converting the list

The [`flatten`](/commands/docs/flatten.md) command creates a new list from an existing list
by adding items in nested lists to the top-level list.
This can be called multiple times to flatten lists nested at any depth.
For example:
" | print
"```nu" | print
"[1 [2 3] 4 [5 6]] | flatten # [1 2 3 4 5 6]

[[1 2] [3 [4 5 [6 7 8]]]] | flatten | flatten | flatten" | nu-highlight | print

"```\n```output-numd" | print

[1 [2 3] 4 [5 6]] | flatten # [1 2 3 4 5 6]

[[1 2] [3 [4 5 [6 7 8]]]] | flatten | flatten | flatten | table | print; print ''

"```" | print

"
The [`wrap`](/commands/docs/wrap.md) command converts a list to a table. Each list value will
be converted to a separate row with a single column:
" | print
"```nu no-run
> let zones = [UTC CET Europe/Moscow Asia/Yekaterinburg]
# Show world clock for selected time zones
> $zones | wrap 'Zone' | upsert Time {|it| (date now | date to-timezone $it.Zone | format date '%Y.%m.%d %H:%M')}
╭────────Zone────────┬───────Time───────╮
│ UTC                │ 2024.06.17 06:06 │
│ CET                │ 2024.06.17 08:06 │
│ Europe/Moscow      │ 2024.06.17 09:06 │
│ Asia/Yekaterinburg │ 2024.06.17 11:06 │
╰────────Zone────────┴───────Time───────╯
```" | print
