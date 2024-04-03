# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd
cd /Users/user/git/numd
const init_numd_pwd_const = '/Users/user/git/numd'
print "###code-block-starting-line-in-original-md-11"
print "```nushell"
print ("> 42 | describe" | nu-highlight)
42 | describe | print

print "```"
print "###code-block-starting-line-in-original-md-41"
print "```nushell"
print ("> \"-5\" | into int" | nu-highlight)
"-5" | into int | print

print "```"
print "###code-block-starting-line-in-original-md-51"
print "```nushell"
print ("> \"1.2\" | into float" | nu-highlight)
"1.2" | into float | print

print "```"
print "###code-block-starting-line-in-original-md-77"
print "```nushell"
print ("> let mybool = 2 > 1" | nu-highlight)
let mybool = 2 > 1

print ("> $mybool" | nu-highlight)
$mybool | print

print ("> let mybool = ($nu.home-path | path exists)" | nu-highlight)
let mybool = ($nu.home-path | path exists)

print ("> $mybool" | nu-highlight)
$mybool | print

print "```"
print "###code-block-starting-line-in-original-md-116"
print "```nushell"
print ("> 3.14day" | nu-highlight)
3.14day | print

print "```"
print "###code-block-starting-line-in-original-md-123"
print "```nushell"
print ("> 30day / 1sec  # How many seconds in 30 days?" | nu-highlight)
30day / 1sec | print

print "```"
print "###code-block-starting-line-in-original-md-150"
print "```nushell"
print ("> 1Gb / 1b" | nu-highlight)
1Gb / 1b | print

print ("> 1Gib / 1b" | nu-highlight)
1Gib / 1b | print

print ("> (1Gib / 1b) == 2 ** 30" | nu-highlight)
(1Gib / 1b) == 2 ** 30 | print

print "```"
print "###code-block-starting-line-in-original-md-201"
print "```nushell"
print ("> 0x[1F FF]  # Hexadecimal" | nu-highlight)
0x[1F FF] | print

print ("> 0b[1 1010] # Binary" | nu-highlight)
0b[1 1010] | print

print ("> 0o[377]    # Octal" | nu-highlight)
0o[377] | print

print "```"
print "###code-block-starting-line-in-original-md-225"
print "```nushell"
print ("> {name: sam rank: 10}" | nu-highlight)
{name: sam rank: 10} | print

print "```"
print "###code-block-starting-line-in-original-md-240"
print "```nushell"
print ("> {x:3 y:1} | insert z 0" | nu-highlight)
{x:3 y:1} | insert z 0 | print

print "```"
print "###code-block-starting-line-in-original-md-253"
print "```nushell"
print ("> {name: sam, rank: 10} | transpose key value" | nu-highlight)
{name: sam, rank: 10} | transpose key value | print

print "```"
print "###code-block-starting-line-in-original-md-263"
print "```nushell"
print ("> {x:12 y:4}.x" | nu-highlight)
{x:12 y:4}.x | print

print "```"
print "###code-block-starting-line-in-original-md-270"
print "```nushell"
print ("> {\"1\":true \" \":false}.\" \"" | nu-highlight)
{"1":true " ":false}." " | print

print "```"
print "###code-block-starting-line-in-original-md-277"
print "```nushell"
print ("> let data = { name: alice, age: 50 }" | nu-highlight)
let data = { name: alice, age: 50 }

print ("> { ...$data, hobby: cricket }" | nu-highlight)
{ ...$data, hobby: cricket } | print

print "```"
print "###code-block-starting-line-in-original-md-291"
print "```nushell"
print ("> [sam fred george]" | nu-highlight)
[sam fred george] | print

print "```"
print "###code-block-starting-line-in-original-md-303"
print "```nushell"
print ("> [bell book candle] | where ($it =~ 'b')" | nu-highlight)
[bell book candle] | where ($it =~ 'b') | print

print "```"
print "###code-block-starting-line-in-original-md-315"
print "```nushell"
print ("> [a b c].1" | nu-highlight)
[a b c].1 | print

print "```"
print "###code-block-starting-line-in-original-md-322"
print "```nushell"
print ("> [a b c d e f] | range 1..3" | nu-highlight)
[a b c d e f] | range 1..3 | print

print "```"
print "###code-block-starting-line-in-original-md-334"
print "```nushell"
print ("> let x = [1 2]" | nu-highlight)
let x = [1 2]

print ("> [...$x 3 ...(4..7 | take 2)]" | nu-highlight)
[...$x 3 ...(4..7 | take 2)] | print

print "```"
print "###code-block-starting-line-in-original-md-352"
print "```nushell"
print ("> [[column1, column2]; [Value1, Value2] [Value3, Value4]]" | nu-highlight)
[[column1, column2]; [Value1, Value2] [Value3, Value4]] | print

print "```"
print "###code-block-starting-line-in-original-md-362"
print "```nushell"
print ("> [{name: sam, rank: 10}, {name: bob, rank: 7}]" | nu-highlight)
[{name: sam, rank: 10}, {name: bob, rank: 7}] | print

print "```"
print "###code-block-starting-line-in-original-md-373"
print "```nushell"
print ("> [{x:12, y:5}, {x:3, y:6}] | get 0" | nu-highlight)
[{x:12, y:5}, {x:3, y:6}] | get 0 | print

print "```"
print "###code-block-starting-line-in-original-md-383"
print "```nushell"
print ("> [[x,y];[12,5],[3,6]] | get 0" | nu-highlight)
[[x,y];[12,5],[3,6]] | get 0 | print

print "```"
print "###code-block-starting-line-in-original-md-403"
print "```nushell"
print ("> [{x:12 y:5} {x:4 y:7} {x:2 y:2}].x" | nu-highlight)
[{x:12 y:5} {x:4 y:7} {x:2 y:2}].x | print

print "```"
print "###code-block-starting-line-in-original-md-414"
print "```nushell"
print ("> [{x:0 y:5 z:1} {x:4 y:7 z:3} {x:2 y:2 z:0}] | select y z" | nu-highlight)
[{x:0 y:5 z:1} {x:4 y:7 z:3} {x:2 y:2 z:0}] | select y z | print

print "```"
print "###code-block-starting-line-in-original-md-425"
print "```nushell"
print ("> [{x:0 y:5 z:1} {x:4 y:7 z:3} {x:2 y:2 z:0}] | select 1 2" | nu-highlight)
[{x:0 y:5 z:1} {x:4 y:7 z:3} {x:2 y:2 z:0}] | select 1 2 | print

print "```"
print "###code-block-starting-line-in-original-md-437"
print "```nushell"
print ("> [{foo: 123}, {}].foo?" | nu-highlight)
[{foo: 123}, {}].foo? | print

print "```"
print "###code-block-starting-line-in-original-md-458"
print "```nushell"
print ("# Assign a closure to a variable
let greet = { |name| print $\"Hello ($name)\"}
do $greet \"Julian\"" | nu-highlight)
print '```
```output-numd'
# Assign a closure to a variable
let greet = { |name| print $"Hello ($name)"}
do $greet "Julian" | print

print "```"
print "###code-block-starting-line-in-original-md-477"
print "```nushell"
print ("mut x = 1
if true {
    $x += 1000
}
print $x" | nu-highlight)
print '```
```output-numd'
mut x = 1
if true {
    $x += 1000
}
print $x | print

print "```"
print "###code-block-starting-line-in-original-md-494"
print "```nushell no-run"
print ("git checkout featurebranch | null" | nu-highlight)

print "```"
print "###code-block-starting-line-in-original-md-502"
print "```nushell try,new-instance"
print ("> [{a:1 b:2} {b:1}]" | nu-highlight)
do {nu -c "[{a:1 b:2} {b:1}]"} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print

print ("> [{a:1 b:2} {b:1}].1.a" | nu-highlight)
do {nu -c "[{a:1 b:2} {b:1}].1.a"} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print

print "```"