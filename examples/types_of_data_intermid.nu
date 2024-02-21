print `###nudoc-block-1`
print ('> 42 | describe' | nu-highlight);
 42 | describe | print $in
print `###nudoc-block-4`
print ('> "-5" | into int' | nu-highlight);
 "-5" | into int | print $in
print `###nudoc-block-7`
print ('> "1.2" | into float' | nu-highlight);
 "1.2" | into float | print $in
print `###nudoc-block-10`
print ('> let mybool = 2 > 1' | nu-highlight);
 let mybool = 2 > 1
print ('> $mybool' | nu-highlight);
 $mybool | print $in
print ('> let mybool = ($env.HOME | path exists)' | nu-highlight);
 let mybool = ($env.HOME | path exists)
print ('> $mybool' | nu-highlight);
 $mybool | print $in
print `###nudoc-block-13`
print ('> 3.14day' | nu-highlight);
 3.14day | print $in
print `###nudoc-block-16`
print ('> 30day / 1sec  # How many seconds in 30 days?' | nu-highlight);
 30day / 1sec   | print $in
print `###nudoc-block-19`
print ('> 1Gb / 1b' | nu-highlight);
 1Gb / 1b | print $in
print ('> 1Gib / 1b' | nu-highlight);
 1Gib / 1b | print $in
print ('> (1Gib / 1b) == 2 ** 30' | nu-highlight);
 (1Gib / 1b) == 2 ** 30 | print $in
print `###nudoc-block-22`
print ('> 0x[1F FF]  # Hexadecimal' | nu-highlight);
 0x[1F FF]   | print $in
print ('> 0b[1 1010] # Binary' | nu-highlight);
 0b[1 1010]  | print $in
print ('> 0o[377]    # Octal' | nu-highlight);
 0o[377]     | print $in
print `###nudoc-block-25`
print ('> {name: sam rank: 10}' | nu-highlight);
 {name: sam rank: 10} | print $in
print `###nudoc-block-28`
print ('> {x:3 y:1} | insert z 0' | nu-highlight);
 {x:3 y:1} | insert z 0 | print $in
print `###nudoc-block-31`
print ('> {name: sam, rank: 10} | transpose key value' | nu-highlight);
 {name: sam, rank: 10} | transpose key value | print $in
print `###nudoc-block-34`
print ('> {x:12 y:4}.x' | nu-highlight);
 {x:12 y:4}.x | print $in
print `###nudoc-block-37`
print ('> {"1":true " ":false}." "' | nu-highlight);
 {"1":true " ":false}." " | print $in
print `###nudoc-block-40`
print ('> let data = { name: alice, age: 50 }' | nu-highlight);
 let data = { name: alice, age: 50 }
print ('> { ...$data, hobby: cricket }' | nu-highlight);
 { ...$data, hobby: cricket } | print $in
print `###nudoc-block-43`
print ('> [sam fred george]' | nu-highlight);
 [sam fred george] | print $in
print `###nudoc-block-46`
print ('> [bell book candle] | where ($it =~ 'b')' | nu-highlight);
 [bell book candle] | where ($it =~ 'b') | print $in
print `###nudoc-block-49`
print ('> [a b c].1' | nu-highlight);
 [a b c].1 | print $in
print `###nudoc-block-52`
print ('> [a b c d e f] | range 1..3' | nu-highlight);
 [a b c d e f] | range 1..3 | print $in
print `###nudoc-block-55`
print ('> let x = [1 2]' | nu-highlight);
 let x = [1 2]
print ('> [...$x 3 ...(4..7 | take 2)]' | nu-highlight);
 [...$x 3 ...(4..7 | take 2)] | print $in
print `###nudoc-block-58`
print ('> [[column1, column2]; [Value1, Value2] [Value3, Value4]]' | nu-highlight);
 [[column1, column2]; [Value1, Value2] [Value3, Value4]] | print $in
print `###nudoc-block-61`
print ('> [{name: sam, rank: 10}, {name: bob, rank: 7}]' | nu-highlight);
 [{name: sam, rank: 10}, {name: bob, rank: 7}] | print $in
print `###nudoc-block-64`
print ('> [{x:12, y:5}, {x:3, y:6}] | get 0' | nu-highlight);
 [{x:12, y:5}, {x:3, y:6}] | get 0 | print $in
print `###nudoc-block-67`
print ('> [[x,y];[12,5],[3,6]] | get 0' | nu-highlight);
 [[x,y];[12,5],[3,6]] | get 0 | print $in
print `###nudoc-block-70`
print ('> [{x:12 y:5} {x:4 y:7} {x:2 y:2}].x' | nu-highlight);
 [{x:12 y:5} {x:4 y:7} {x:2 y:2}].x | print $in
print `###nudoc-block-73`
print ('> [{x:0 y:5 z:1} {x:4 y:7 z:3} {x:2 y:2 z:0}] | select y z' | nu-highlight);
 [{x:0 y:5 z:1} {x:4 y:7 z:3} {x:2 y:2 z:0}] | select y z | print $in
print `###nudoc-block-76`
print ('> [{x:0 y:5 z:1} {x:4 y:7 z:3} {x:2 y:2 z:0}] | select 1 2' | nu-highlight);
 [{x:0 y:5 z:1} {x:4 y:7 z:3} {x:2 y:2 z:0}] | select 1 2 | print $in
print `###nudoc-block-79`
print ('> [{foo: 123}, {}].foo?' | nu-highlight);
 [{foo: 123}, {}].foo? | print $in
print `###nudoc-block-82`
print ('# Assign a closure to a variable
let greet = { |name| print $"Hello ($name)"}
do $greet "Julian"' | nu-highlight);
print '```
```nudoc-output'
# Assign a closure to a variable
let greet = { |name| print $"Hello ($name)"}
do $greet "Julian"
print `###nudoc-block-85`
print ('mut x = 1
if true {
    $x += 1000
}
print $x' | nu-highlight);
print '```
```nudoc-output'
mut x = 1
if true {
    $x += 1000
}
print $x
print `###nudoc-block-88`
print ('git checkout featurebranch | null' | nu-highlight);
print '```
```nudoc-output'
git checkout featurebranch | null
print `###nudoc-block-91`
print ('> [{a:1 b:2} {b:1}]' | nu-highlight);
 [{a:1 b:2} {b:1}] | print $in
print ('> [{a:1 b:2} {b:1}].1.a' | nu-highlight);
 [{a:1 b:2} {b:1}].1.a | print $in