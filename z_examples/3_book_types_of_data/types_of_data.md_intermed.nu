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
```nushell" | print
"> 42 | describe" | nu-highlight | print

42 | describe | table | print; print ''

"```" | print

"#code-block-marker-open-3
```nushell" | print
"> \"-5\" | into int" | nu-highlight | print

"-5" | into int | table | print; print ''

"```" | print

"#code-block-marker-open-5
```nushell" | print
"> \"1.2\" | into float" | nu-highlight | print

"1.2" | into float | table | print; print ''

"```" | print

"#code-block-marker-open-7
```nushell" | print
"> let mybool = 2 > 1" | nu-highlight | print

let mybool = 2 > 1

"> $mybool" | nu-highlight | print

$mybool | table | print; print ''

"> let mybool = ($nu.home-path | path exists)" | nu-highlight | print

let mybool = ($nu.home-path | path exists)

"> $mybool" | nu-highlight | print

$mybool | table | print; print ''

"```" | print

"#code-block-marker-open-9
```nushell" | print
"> 3.14day" | nu-highlight | print

3.14day | table | print; print ''

"```" | print

"#code-block-marker-open-11
```nushell" | print
"> 30day / 1sec  # How many seconds in 30 days?" | nu-highlight | print

30day / 1sec | table | print; print ''

"```" | print

"#code-block-marker-open-13
```nushell" | print
"> 1Gb / 1b" | nu-highlight | print

1Gb / 1b | table | print; print ''

"> 1Gib / 1b" | nu-highlight | print

1Gib / 1b | table | print; print ''

"> (1Gib / 1b) == 2 ** 30" | nu-highlight | print

(1Gib / 1b) == 2 ** 30 | table | print; print ''

"```" | print

"#code-block-marker-open-15
```nushell" | print
"> 0x[1F FF]  # Hexadecimal" | nu-highlight | print

0x[1F FF] | table | print; print ''

"> 0b[1 1010] # Binary" | nu-highlight | print

0b[1 1010] | table | print; print ''

"> 0o[377]    # Octal" | nu-highlight | print

0o[377] | table | print; print ''

"```" | print

"#code-block-marker-open-17
```nushell" | print
"> {name: sam rank: 10}" | nu-highlight | print

{name: sam rank: 10} | table | print; print ''

"```" | print

"#code-block-marker-open-19
```nushell" | print
"> {x:3 y:1} | insert z 0" | nu-highlight | print

{x:3 y:1} | insert z 0 | table | print; print ''

"```" | print

"#code-block-marker-open-21
```nushell" | print
"> {name: sam, rank: 10} | transpose key value" | nu-highlight | print

{name: sam, rank: 10} | transpose key value | table | print; print ''

"```" | print

"#code-block-marker-open-23
```nushell" | print
"> {x:12 y:4}.x" | nu-highlight | print

{x:12 y:4}.x | table | print; print ''

"```" | print

"#code-block-marker-open-25
```nushell" | print
"> {\"1\":true \" \":false}.\" \"" | nu-highlight | print

{"1":true " ":false}." " | table | print; print ''

"```" | print

"#code-block-marker-open-27
```nushell" | print
"> let data = { name: alice, age: 50 }" | nu-highlight | print

let data = { name: alice, age: 50 }

"> { ...$data, hobby: cricket }" | nu-highlight | print

{ ...$data, hobby: cricket } | table | print; print ''

"```" | print

"#code-block-marker-open-29
```nushell" | print
"> [sam fred george]" | nu-highlight | print

[sam fred george] | table | print; print ''

"```" | print

"#code-block-marker-open-31
```nushell" | print
"> [bell book candle] | where ($it =~ 'b')" | nu-highlight | print

[bell book candle] | where ($it =~ 'b') | table | print; print ''

"```" | print

"#code-block-marker-open-33
```nushell" | print
"> [a b c].1" | nu-highlight | print

[a b c].1 | table | print; print ''

"```" | print

"#code-block-marker-open-35
```nushell" | print
"> [a b c d e f] | range 1..3" | nu-highlight | print

[a b c d e f] | range 1..3 | table | print; print ''

"```" | print

"#code-block-marker-open-37
```nushell" | print
"> let x = [1 2]" | nu-highlight | print

let x = [1 2]

"> [...$x 3 ...(4..7 | take 2)]" | nu-highlight | print

[...$x 3 ...(4..7 | take 2)] | table | print; print ''

"```" | print

"#code-block-marker-open-39
```nushell" | print
"> [[column1, column2]; [Value1, Value2] [Value3, Value4]]" | nu-highlight | print

[[column1, column2]; [Value1, Value2] [Value3, Value4]] | table | print; print ''

"```" | print

"#code-block-marker-open-41
```nushell" | print
"> [{name: sam, rank: 10}, {name: bob, rank: 7}]" | nu-highlight | print

[{name: sam, rank: 10}, {name: bob, rank: 7}] | table | print; print ''

"```" | print

"#code-block-marker-open-43
```nushell" | print
"> [{x:12, y:5}, {x:3, y:6}] | get 0" | nu-highlight | print

[{x:12, y:5}, {x:3, y:6}] | get 0 | table | print; print ''

"```" | print

"#code-block-marker-open-45
```nushell" | print
"> [[x,y];[12,5],[3,6]] | get 0" | nu-highlight | print

[[x,y];[12,5],[3,6]] | get 0 | table | print; print ''

"```" | print

"#code-block-marker-open-47
```nushell" | print
"> [{x:12 y:5} {x:4 y:7} {x:2 y:2}].x" | nu-highlight | print

[{x:12 y:5} {x:4 y:7} {x:2 y:2}].x | table | print; print ''

"```" | print

"#code-block-marker-open-49
```nushell" | print
"> [{x:0 y:5 z:1} {x:4 y:7 z:3} {x:2 y:2 z:0}] | select y z" | nu-highlight | print

[{x:0 y:5 z:1} {x:4 y:7 z:3} {x:2 y:2 z:0}] | select y z | table | print; print ''

"```" | print

"#code-block-marker-open-51
```nushell" | print
"> [{x:0 y:5 z:1} {x:4 y:7 z:3} {x:2 y:2 z:0}] | select 1 2" | nu-highlight | print

[{x:0 y:5 z:1} {x:4 y:7 z:3} {x:2 y:2 z:0}] | select 1 2 | table | print; print ''

"```" | print

"#code-block-marker-open-53
```nushell" | print
"> [{foo: 123}, {}].foo?" | nu-highlight | print

[{foo: 123}, {}].foo? | table | print; print ''

"```" | print

"#code-block-marker-open-55
```nushell" | print
"# Assign a closure to a variable
let greet = { |name| print $\"Hello ($name)\"}
do $greet \"Julian\"" | nu-highlight | print

"```\n```output-numd" | print

# Assign a closure to a variable
let greet = { |name| print $"Hello ($name)"}
do $greet "Julian" | table | print; print ''

"```" | print

"#code-block-marker-open-58
```nushell" | print
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
print $x | table | print; print ''

"```" | print

"#code-block-marker-open-61
```nushell no-run" | print
"git checkout featurebranch | null" | nu-highlight | print

"```\n```output-numd" | print

git checkout featurebranch | null

"```" | print

"#code-block-marker-open-63
```nushell try,new-instance" | print
"> [{a:1 b:2} {b:1}]" | nu-highlight | print

/Users/user/.cargo/bin/nu -c "[{a:1 b:2} {b:1}]" | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | table | print; print ''

"> [{a:1 b:2} {b:1}].1.a" | nu-highlight | print

/Users/user/.cargo/bin/nu -c "[{a:1 b:2} {b:1}].1.a" | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | table | print; print ''

"```" | print
