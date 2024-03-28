# this script was generated automatically using nudoc
# https://github.com/nushell-prophet/nudoc
print "###nudoc-block-1"
print "```nushell"
print ("> 42 | describe" | nu-highlight)
42 | describe | echo $in

print "###nudoc-block-4"
print "```nushell"
print ("> \"-5\" | into int" | nu-highlight)
"-5" | into int | echo $in

print "###nudoc-block-7"
print "```nushell"
print ("> \"1.2\" | into float" | nu-highlight)
"1.2" | into float | echo $in

print "###nudoc-block-10"
print "```nushell"
print ("> let mybool = 2 > 1" | nu-highlight)
let mybool = 2 > 1

print ("> $mybool" | nu-highlight)
$mybool | echo $in

print ("> let mybool = ($env.HOME | path exists)" | nu-highlight)
let mybool = ($env.HOME | path exists)

print ("> $mybool" | nu-highlight)
$mybool | echo $in

print "###nudoc-block-13"
print "```nushell"
print ("> 3.14day" | nu-highlight)
3.14day | echo $in

print "###nudoc-block-16"
print "```nushell"
print ("> 30day / 1sec  # How many seconds in 30 days?" | nu-highlight)
30day / 1sec | echo $in

print "###nudoc-block-19"
print "```nushell"
print ("> 1Gb / 1b" | nu-highlight)
1Gb / 1b | echo $in

print ("> 1Gib / 1b" | nu-highlight)
1Gib / 1b | echo $in

print ("> (1Gib / 1b) == 2 ** 30" | nu-highlight)
(1Gib / 1b) == 2 ** 30 | echo $in

print "###nudoc-block-22"
print "```nushell"
print ("> 0x[1F FF]  # Hexadecimal" | nu-highlight)
0x[1F FF] | echo $in

print ("> 0b[1 1010] # Binary" | nu-highlight)
0b[1 1010] | echo $in

print ("> 0o[377]    # Octal" | nu-highlight)
0o[377] | echo $in

print "###nudoc-block-25"
print "```nushell"
print ("> {name: sam rank: 10}" | nu-highlight)
{name: sam rank: 10} | echo $in

print "###nudoc-block-28"
print "```nushell"
print ("> {x:3 y:1} | insert z 0" | nu-highlight)
{x:3 y:1} | insert z 0 | echo $in

print "###nudoc-block-31"
print "```nushell"
print ("> {name: sam, rank: 10} | transpose key value" | nu-highlight)
{name: sam, rank: 10} | transpose key value | echo $in

print "###nudoc-block-34"
print "```nushell"
print ("> {x:12 y:4}.x" | nu-highlight)
{x:12 y:4}.x | echo $in

print "###nudoc-block-37"
print "```nushell"
print ("> {\"1\":true \" \":false}.\" \"" | nu-highlight)
{"1":true " ":false}." " | echo $in

print "###nudoc-block-40"
print "```nushell"
print ("> let data = { name: alice, age: 50 }" | nu-highlight)
let data = { name: alice, age: 50 }

print ("> { ...$data, hobby: cricket }" | nu-highlight)
{ ...$data, hobby: cricket } | echo $in

print "###nudoc-block-43"
print "```nushell"
print ("> [sam fred george]" | nu-highlight)
[sam fred george] | echo $in

print "###nudoc-block-46"
print "```nushell"
print ("> [bell book candle] | where ($it =~ 'b')" | nu-highlight)
[bell book candle] | where ($it =~ 'b') | echo $in

print "###nudoc-block-49"
print "```nushell"
print ("> [a b c].1" | nu-highlight)
[a b c].1 | echo $in

print "###nudoc-block-52"
print "```nushell"
print ("> [a b c d e f] | range 1..3" | nu-highlight)
[a b c d e f] | range 1..3 | echo $in

print "###nudoc-block-55"
print "```nushell"
print ("> let x = [1 2]" | nu-highlight)
let x = [1 2]

print ("> [...$x 3 ...(4..7 | take 2)]" | nu-highlight)
[...$x 3 ...(4..7 | take 2)] | echo $in

print "###nudoc-block-58"
print "```nushell"
print ("> [[column1, column2]; [Value1, Value2] [Value3, Value4]]" | nu-highlight)
[[column1, column2]; [Value1, Value2] [Value3, Value4]] | echo $in

print "###nudoc-block-61"
print "```nushell"
print ("> [{name: sam, rank: 10}, {name: bob, rank: 7}]" | nu-highlight)
[{name: sam, rank: 10}, {name: bob, rank: 7}] | echo $in

print "###nudoc-block-64"
print "```nushell"
print ("> [{x:12, y:5}, {x:3, y:6}] | get 0" | nu-highlight)
[{x:12, y:5}, {x:3, y:6}] | get 0 | echo $in

print "###nudoc-block-67"
print "```nushell"
print ("> [[x,y];[12,5],[3,6]] | get 0" | nu-highlight)
[[x,y];[12,5],[3,6]] | get 0 | echo $in

print "###nudoc-block-70"
print "```nushell"
print ("> [{x:12 y:5} {x:4 y:7} {x:2 y:2}].x" | nu-highlight)
[{x:12 y:5} {x:4 y:7} {x:2 y:2}].x | echo $in

print "###nudoc-block-73"
print "```nushell"
print ("> [{x:0 y:5 z:1} {x:4 y:7 z:3} {x:2 y:2 z:0}] | select y z" | nu-highlight)
[{x:0 y:5 z:1} {x:4 y:7 z:3} {x:2 y:2 z:0}] | select y z | echo $in

print "###nudoc-block-76"
print "```nushell"
print ("> [{x:0 y:5 z:1} {x:4 y:7 z:3} {x:2 y:2 z:0}] | select 1 2" | nu-highlight)
[{x:0 y:5 z:1} {x:4 y:7 z:3} {x:2 y:2 z:0}] | select 1 2 | echo $in

print "###nudoc-block-79"
print "```nushell"
print ("> [{foo: 123}, {}].foo?" | nu-highlight)
[{foo: 123}, {}].foo? | echo $in

print "###nudoc-block-82"
print "```nushell"
print ("# Assign a closure to a variable
let greet = { |name| print $\"Hello ($name)\"}
do $greet \"Julian\"" | nu-highlight)
print '```
```nudoc-output'
# Assign a closure to a variable
let greet = { |name| print $"Hello ($name)"}
do $greet "Julian" | echo $in

print "###nudoc-block-87"
print "```nushell"
print ("mut x = 1
if true {
    $x += 1000
}
print $x" | nu-highlight)
print '```
```nudoc-output'
mut x = 1
if true {
    $x += 1000
}
print $x | echo $in

print "###nudoc-block-92"
print "```nushell"
print ("git checkout featurebranch | null" | nu-highlight)
print '```
```nudoc-output'
git checkout featurebranch | null

print "###nudoc-block-95"
print "```nushell try,new-instance"
print ("> [{a:1 b:2} {b:1}]" | nu-highlight)
do {nu -c "[{a:1 b:2} {b:1}]"} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | echo $in

print ("> [{a:1 b:2} {b:1}].1.a" | nu-highlight)
do {nu -c "[{a:1 b:2} {b:1}].1.a"} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | echo $in
