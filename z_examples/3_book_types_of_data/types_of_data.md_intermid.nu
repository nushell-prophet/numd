# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd
const init_numd_pwd_const = '/Users/user/git/numd'
"# Types of Data

Traditionally, Unix shell commands have communicated with each other using strings of text: one command would write text to standard output (often abbreviated 'stdout') and the other would read text from standard input (or 'stdin'), allowing the two commands to communicate.

Nu embraces this approach, and expands it to include other types of data, in addition to strings.

Like many programming languages, Nu models data using a set of simple, and structured data types. Simple data types include integers, floats, strings, booleans, dates. There are also special types for filesizes and time durations.

The [`describe`](/commands/docs/describe.md) command returns the type of a data value:
" | print
"```nushell" | print
"> 42 | describe" | nu-highlight | print

42 | describe | print; print ''

"```" | print

"
## Types at a glance

| Type              | Example                                                               |
| ----------------- | --------------------------------------------------------------------- |
| Integers          | `-65535`                                                              |
| Decimals (floats) | `9.9999`, `Infinity`                                                  |
| Strings           | <code>\"hole 18\", 'hole 18', \\`hole 18\\`, hole18</code>                |
| Booleans          | `true`                                                                |
| Dates             | `2000-01-01`                                                          |
| Durations         | `2min + 12sec`                                                        |
| File sizes        | `64mb`                                                                |
| Ranges            | `0..4`, `0..<5`, `0..`, `..4`                                         |
| Binary            | `0x[FE FF]`                                                           |
| Lists             | `[0 1 'two' 3]`                                                       |
| Records           | `{name:\"Nushell\", lang: \"Rust\"}`                                      |
| Tables            | `[{x:12, y:15}, {x:8, y:9}]`, `[[x, y]; [12, 15], [8, 9]]`            |
| Closures          | `{\\|e\\| $e + 1 \\| into string }`, `{ $in.name.0 \\| path exists }`     |
| Blocks            | `if true { print \"hello!\" }`, `loop { print \"press ctrl-c to exit\" }` |
| Null              | `null`                                                                |

## Integers

Examples of integers (i.e. \"round numbers\") include 1, 0, -5, and 100.
You can parse a string into an integer with the [`into int`](/commands/docs/into_int.md) command
" | print
"```nushell" | print
"> \"-5\" | into int" | nu-highlight | print

"-5" | into int | print; print ''

"```" | print

"
## Decimals (floats)

Decimal numbers are numbers with some fractional component. Examples include 1.5, 2.0, and 15.333.
You can cast a string into a Float with the [`into float`](/commands/docs/into_float.md) command
" | print
"```nushell" | print
"> \"1.2\" | into float" | nu-highlight | print

"1.2" | into float | print; print ''

"```" | print

"
## Strings

A string of characters that represents text. There are a few ways these can be constructed:

- Double quotes
  - `\"Line1\\nLine2\\n\"`
- Single quotes
  `'She said \"Nushell is the future\".'`
- Dynamic string interpolation
  - `$\"6 x 7 = (6 * 7)\"`
  - `ls | each { |it| $\"($it.name) is ($it.size)\" }`
- Bare strings
  - `print hello`
  - `[foo bar baz]`

See [Working with strings](working_with_strings.md) and [Handling Strings](https://www.nushell.sh/book/loading_data.html#handling-strings) for details.

## Booleans

There are just two boolean values: `true` and `false`. Rather than writing the values directly, they often result from a comparison:
" | print
"```nushell" | print
"> let mybool = 2 > 1" | nu-highlight | print

let mybool = 2 > 1

"> $mybool" | nu-highlight | print

$mybool | print; print ''

"> let mybool = ($nu.home-path | path exists)" | nu-highlight | print

let mybool = ($nu.home-path | path exists)

"> $mybool" | nu-highlight | print

$mybool | print; print ''

"```" | print

"
## Dates

Dates and times are held together in the Date value type. Date values used by the system are timezone-aware, and by default use the UTC timezone.

Dates are in three forms, based on the RFC 3339 standard:

- A date:
  - `2022-02-02`
- A date and time (in GMT):
  - `2022-02-02T14:30:00`
- A date and time with timezone:
  - `2022-02-02T14:30:00+05:00`

## Durations

Durations represent a length of time. This chart shows all durations currently supported:

| Duration | Length          |
| -------- | --------------- |
| `1ns`    | one nanosecond  |
| `1us`    | one microsecond |
| `1ms`    | one millisecond |
| `1sec`   | one second      |
| `1min`   | one minute      |
| `1hr`    | one hour        |
| `1day`   | one day         |
| `1wk`    | one week        |

You can make fractional durations:
" | print
"```nushell" | print
"> 3.14day" | nu-highlight | print

3.14day | print; print ''

"```" | print

"
And you can do calculations with durations:
" | print
"```nushell" | print
"> 30day / 1sec  # How many seconds in 30 days?" | nu-highlight | print

30day / 1sec | print; print ''

"```" | print

"
## File sizes

Nushell also has a special type for file sizes. Examples include `100b`, `15kb`, and `100mb`.

The full list of filesize units are:

- `b`: bytes
- `kb`: kilobytes (aka 1000 bytes)
- `mb`: megabytes
- `gb`: gigabytes
- `tb`: terabytes
- `pb`: petabytes
- `eb`: exabytes
- `kib`: kibibytes (aka 1024 bytes)
- `mib`: mebibytes
- `gib`: gibibytes
- `tib`: tebibytes
- `pib`: pebibytes
- `eib`: exbibytes

As with durations, you can make fractional file sizes, and do calculations:
" | print
"```nushell" | print
"> 1Gb / 1b" | nu-highlight | print

1Gb / 1b | print; print ''

"> 1Gib / 1b" | nu-highlight | print

1Gib / 1b | print; print ''

"> (1Gib / 1b) == 2 ** 30" | nu-highlight | print

(1Gib / 1b) == 2 ** 30 | print; print ''

"```" | print

"
## Ranges

A range is a way of expressing a sequence of integer or float values from start to finish. They take the form \\<start\\>..\\<end\\>. For example, the range `1..3` means the numbers 1, 2, and 3.

::: tip

You can also easily create lists of characters with a form similar to ranges with the command [`seq char`](/commands/docs/seq_char.html) as well as with dates using the [`seq date`](/commands/docs/seq_date.html) command.

:::

### Specifying the step

You can specify the step of a range with the form \\<start\\>..\\<second\\>..\\<end\\>, where the step between values in the range is the distance between the \\<start\\> and \\<second\\> values, which numerically is \\<second\\> - \\<start\\>. For example, the range `2..5..11` means the numbers 2, 5, 8, and 11 because the step is \\<second\\> - \\<first\\> = 5 - 2 = 3. The third value is 5 + 3 = 8 and the fourth value is 8 + 3 = 11.

[`seq`](/commands/docs/seq.md) can also create sequences of numbers, and provides an alternate way of specifying the step with three parameters. It's called with `seq $start $step $end` where the step amount is the second parameter rather than being the second parameter minus the first parameter. So `2..5..9` would be equivalent to `seq 2 3 9`.

### Inclusive and non-inclusive ranges

Ranges are inclusive by default, meaning that the ending value is counted as part of the range. The range `1..3` includes the number `3` as the last value in the range.

Sometimes, you may want a range that is limited by a number but doesn't use that number in the output. For this, you can use `..<` instead of `..`. For example, `1..<5` is the numbers 1, 2, 3, and 4.

### Open-ended ranges

Ranges can also be open-ended. You can remove the start or the end of the range to make it open-ended.

Let's say you wanted to start counting at 3, but you didn't have a specific end in mind. You could use the range `3..` to represent this. When you use a range that's open-ended on the right side, remember that this will continue counting for as long as possible, which could be a very long time! You'll often want to use open-ended ranges with commands like [`take`](/commands/docs/take.md), so you can take the number of elements you want from the range.

You can also make the start of the range open. In this case, Nushell will start counting with `0`. For example, the range `..2` is the numbers 0, 1, and 2.

::: warning

Watch out for displaying open-ended ranges like just entering `3..` into the command line. It will keep printing out numbers very quickly until you stop it with something like Ctr + c.

:::

## Binary data

Binary data, like the data from an image file, is a group of raw bytes.

You can write binary as a literal using any of the `0x[...]`, `0b[...]`, or `0o[...]` forms:
" | print
"```nushell" | print
"> 0x[1F FF]  # Hexadecimal" | nu-highlight | print

0x[1F FF] | print; print ''

"> 0b[1 1010] # Binary" | nu-highlight | print

0b[1 1010] | print; print ''

"> 0o[377]    # Octal" | nu-highlight | print

0o[377] | print; print ''

"```" | print

"
Incomplete bytes will be left-padded with zeros.

## Structured data

Structured data builds from the simple data. For example, instead of a single integer, structured data gives us a way to represent multiple integers in the same value. Here's a list of the currently supported structured data types: records, lists and tables.

## Records

Records hold key-value pairs, which associate string keys with various data values. Record syntax is very similar to objects in JSON. However, commas are _not_ required to separate values if Nushell can easily distinguish them!
" | print
"```nushell" | print
"> {name: sam rank: 10}" | nu-highlight | print

{name: sam rank: 10} | print; print ''

"```" | print

"
As these can sometimes have many fields, a record is printed up-down rather than left-right.

:::tip
A record is identical to a single row of a table (see below). You can think of a record as essentially being a \"one-row table\", with each of its keys as a column (although a true one-row table is something distinct from a record).

This means that any command that operates on a table's rows _also_ operates on records. For instance, [`insert`](/commands/docs/insert.md), which adds data to each of a table's rows, can be used with records:
" | print
"```nushell" | print
"> {x:3 y:1} | insert z 0" | nu-highlight | print

{x:3 y:1} | insert z 0 | print; print ''

"```" | print

"
:::

You can iterate over records by first transposing it into a table:
" | print
"```nushell" | print
"> {name: sam, rank: 10} | transpose key value" | nu-highlight | print

{name: sam, rank: 10} | transpose key value | print; print ''

"```" | print

"
Accessing records' data is done by placing a `.` before a string, which is usually a bare string:
" | print
"```nushell" | print
"> {x:12 y:4}.x" | nu-highlight | print

{x:12 y:4}.x | print; print ''

"```" | print

"
However, if a record has a key name that can't be expressed as a bare string, or resembles an integer (see lists, below), you'll need to use more explicit string syntax, like so:
" | print
"```nushell" | print
"> {\"1\":true \" \":false}.\" \"" | nu-highlight | print

{"1":true " ":false}." " | print; print ''

"```" | print

"
To make a copy of a record with new fields, you can use the [spread operator](/book/operators#spread-operator) (`...`):
" | print
"```nushell" | print
"> let data = { name: alice, age: 50 }" | nu-highlight | print

let data = { name: alice, age: 50 }

"> { ...$data, hobby: cricket }" | nu-highlight | print

{ ...$data, hobby: cricket } | print; print ''

"```" | print

"
## Lists

Lists are ordered sequences of data values. List syntax is very similar to arrays in JSON. However, commas are _not_ required to separate values if Nushell can easily distinguish them!
" | print
"```nushell" | print
"> [sam fred george]" | nu-highlight | print

[sam fred george] | print; print ''

"```" | print

"
:::tip
Lists are equivalent to the individual columns of tables. You can think of a list as essentially being a \"one-column table\" (with no column name). Thus, any command which operates on a column _also_ operates on a list. For instance, [`where`](/commands/docs/where.md) can be used with lists:
" | print
"```nushell" | print
"> [bell book candle] | where ($it =~ 'b')" | nu-highlight | print

[bell book candle] | where ($it =~ 'b') | print; print ''

"```" | print

"
:::

Accessing lists' data is done by placing a `.` before a bare integer:
" | print
"```nushell" | print
"> [a b c].1" | nu-highlight | print

[a b c].1 | print; print ''

"```" | print

"
To get a sub-list from a list, you can use the [`range`](/commands/docs/range.md) command:
" | print
"```nushell" | print
"> [a b c d e f] | range 1..3" | nu-highlight | print

[a b c d e f] | range 1..3 | print; print ''

"```" | print

"
To append one or more lists together, optionally with values interspersed in between, you can use the
[spread operator](/book/operators#spread-operator) (`...`):
" | print
"```nushell" | print
"> let x = [1 2]" | nu-highlight | print

let x = [1 2]

"> [...$x 3 ...(4..7 | take 2)]" | nu-highlight | print

[...$x 3 ...(4..7 | take 2)] | print; print ''

"```" | print

"
## Tables

The table is a core data structure in Nushell. As you run commands, you'll see that many of them return tables as output. A table has both rows and columns.

We can create our own tables similarly to how we create a list. Because tables also contain columns and not just values, we pass in the name of the column values:
" | print
"```nushell" | print
"> [[column1, column2]; [Value1, Value2] [Value3, Value4]]" | nu-highlight | print

[[column1, column2]; [Value1, Value2] [Value3, Value4]] | print; print ''

"```" | print

"
You can also create a table as a list of records, JSON-style:
" | print
"```nushell" | print
"> [{name: sam, rank: 10}, {name: bob, rank: 7}]" | nu-highlight | print

[{name: sam, rank: 10}, {name: bob, rank: 7}] | print; print ''

"```" | print

"
:::tip
Internally, tables are simply **lists of records**. This means that any command which extracts or isolates a specific row of a table will produce a record. For example, `get 0`, when used on a list, extracts the first value. But when used on a table (a list of records), it extracts a record:
" | print
"```nushell" | print
"> [{x:12, y:5}, {x:3, y:6}] | get 0" | nu-highlight | print

[{x:12, y:5}, {x:3, y:6}] | get 0 | print; print ''

"```" | print

"
This is true regardless of which table syntax you use:
" | print
"```nushell" | print
"> [[x,y];[12,5],[3,6]] | get 0" | nu-highlight | print

[[x,y];[12,5],[3,6]] | get 0 | print; print ''

"```" | print

"
:::

### Cell Paths

You can combine list and record data access syntax to navigate tables. When used on tables, these access chains are called \"cell paths\".

You can access individual rows by number to obtain records:

@[code](@snippets/types_of_data/cell-paths.sh)

Moreover, you can also access entire columns of a table by name, to obtain lists:
" | print
"```nushell" | print
"> [{x:12 y:5} {x:4 y:7} {x:2 y:2}].x" | nu-highlight | print

[{x:12 y:5} {x:4 y:7} {x:2 y:2}].x | print; print ''

"```" | print

"
Of course, these resulting lists don't have the column names of the table. To remove columns from a table while leaving it as a table, you'll commonly use the [`select`](/commands/docs/select.md) command with column names:
" | print
"```nushell" | print
"> [{x:0 y:5 z:1} {x:4 y:7 z:3} {x:2 y:2 z:0}] | select y z" | nu-highlight | print

[{x:0 y:5 z:1} {x:4 y:7 z:3} {x:2 y:2 z:0}] | select y z | print; print ''

"```" | print

"
To remove rows from a table, you'll commonly use the [`select`](/commands/docs/select.md) command with row numbers, as you would with a list:
" | print
"```nushell" | print
"> [{x:0 y:5 z:1} {x:4 y:7 z:3} {x:2 y:2 z:0}] | select 1 2" | nu-highlight | print

[{x:0 y:5 z:1} {x:4 y:7 z:3} {x:2 y:2 z:0}] | select 1 2 | print; print ''

"```" | print

"
#### Optional cell paths

By default, cell path access will fail if it can't access the requested row or column. To suppress these errors, you can add `?` to a cell path member to mark it as _optional_:
" | print
"```nushell" | print
"> [{foo: 123}, {}].foo?" | nu-highlight | print

[{foo: 123}, {}].foo? | print; print ''

"```" | print

"
When using optional cell path members, missing data is replaced with `null`.

## Closures

Closures are anonymous functions that can be passed a value through parameters and _close over_ (i.e. use) a variable outside their scope.

For example, in the command `each { |it| print $it }` the closure is the portion contained in curly braces, `{ |it| print $it }`.
Closure parameters are specified between a pair of pipe symbols (for example, `|it|`) if necessary.
You can also use a pipeline input as `$in` in most closures instead of providing an explicit parameter: `each { print $in }`

Closures itself can be bound to a named variable and passed as a parameter.
To call a closure directly in your code use the [`do`](/commands/docs/do.md) command.
" | print
"```nushell" | print
"# Assign a closure to a variable
let greet = { |name| print $\"Hello ($name)\"}
do $greet \"Julian\"" | nu-highlight | print

"```\n```output-numd" | print

# Assign a closure to a variable
let greet = { |name| print $"Hello ($name)"}
do $greet "Julian" | print; print ''

"```" | print

"
Closures are a useful way to represent code that can be executed on each row of data.
It is idiomatic to use `$it` as a parameter name in [`each`](/commands/docs/each.md) blocks, but not required;
`each { |x| print $x }` works the same way as `each { |it| print $it }`.

## Blocks

Blocks don't close over variables, don't have parameters, and can't be passed as a value.
However, unlike closures, blocks can access mutable variable in the parent closure.
For example, mutating a variable inside the block used in an [`if`](/commands/docs/if.md) call is valid:
" | print
"```nushell" | print
"mut x = 1
if true {
    $x += 1000
}
print $x" | nu-highlight | print

"```\n```output-numd" | print

mut x = 1
if true {
    $x += 1000
}
print $x | print; print ''

"```" | print

"
## Null

Finally, there is `null` which is the language's \"nothing\" value, similar to JSON's \"null\". Whenever Nushell would print the `null` value (outside of a string or data structure), it prints nothing instead. Hence, most of Nushell's file system commands (like [`save`](/commands/docs/save.md) or [`cd`](/commands/docs/cd.md)) produce `null`.

You can place `null` at the end of a pipeline to replace the pipeline's output with it, and thus print nothing:
" | print
"```nushell no-run
git checkout featurebranch | null
```" | print
"
:::warning

`null` is not the same as the absence of a value! It is possible for a table to be produced that has holes in some of its rows. Attempting to access this value will not produce `null`, but instead cause an error:
" | print
"```nushell try,new-instance" | print
"> [{a:1 b:2} {b:1}]" | nu-highlight | print

/Users/user/.cargo/bin/nu -c "[{a:1 b:2} {b:1}]"| complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print; print ''

"> [{a:1 b:2} {b:1}].1.a" | nu-highlight | print

/Users/user/.cargo/bin/nu -c "[{a:1 b:2} {b:1}].1.a"| complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print; print ''

"```" | print

"
If you would prefer this to return `null`, mark the cell path member as _optional_ like `.1.a?`.

The absence of a value is (as of Nushell 0.71) printed as the ❎ emoji in interactive output.
:::" | print
