print `###nudoc-block-1`
print ('> 42 | describe' | nu-highlight)
do {nu -c ' 42 | describe'} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print `###nudoc-block-4`
print ('> "-5" | into int' | nu-highlight)
do {nu -c ' "-5" | into int'} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print `###nudoc-block-7`
print ('> "1.2" | into float' | nu-highlight)
do {nu -c ' "1.2" | into float'} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print `###nudoc-block-10`
print ('> let mybool = 2 > 1' | nu-highlight)
 let mybool = 2 > 1
print ('> $mybool' | nu-highlight)
try { $mybool | $in} catch {|e| $e} | print $in
print ('> let mybool = ($env.HOME | path exists)' | nu-highlight)
 let mybool = ($env.HOME | path exists)
print ('> $mybool' | nu-highlight)
try { $mybool | $in} catch {|e| $e} | print $in
print `###nudoc-block-13`
print ('> 3.14day' | nu-highlight)
do {nu -c ' 3.14day'} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print `###nudoc-block-16`
print ('> 30day / 1sec  # How many seconds in 30 days?' | nu-highlight)
do {nu -c ' 30day / 1sec  '} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print `###nudoc-block-19`
print ('> 1Gb / 1b' | nu-highlight)
do {nu -c ' 1Gb / 1b'} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print ('> 1Gib / 1b' | nu-highlight)
do {nu -c ' 1Gib / 1b'} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print ('> (1Gib / 1b) == 2 ** 30' | nu-highlight)
do {nu -c ' (1Gib / 1b) == 2 ** 30'} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print `###nudoc-block-22`
print ('> 0x[1F FF]  # Hexadecimal' | nu-highlight)
do {nu -c ' 0x[1F FF]  '} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print ('> 0b[1 1010] # Binary' | nu-highlight)
do {nu -c ' 0b[1 1010] '} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print ('> 0o[377]    # Octal' | nu-highlight)
do {nu -c ' 0o[377]    '} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print `###nudoc-block-25`
print ('> {name: sam rank: 10}' | nu-highlight)
do {nu -c ' {name: sam rank: 10}'} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print `###nudoc-block-28`
print ('> {x:3 y:1} | insert z 0' | nu-highlight)
do {nu -c ' {x:3 y:1} | insert z 0'} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print `###nudoc-block-31`
print ('> {name: sam, rank: 10} | transpose key value' | nu-highlight)
do {nu -c ' {name: sam, rank: 10} | transpose key value'} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print `###nudoc-block-34`
print ('> {x:12 y:4}.x' | nu-highlight)
do {nu -c ' {x:12 y:4}.x'} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print `###nudoc-block-37`
print ('> {"1":true " ":false}." "' | nu-highlight)
do {nu -c ' {"1":true " ":false}." "'} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print `###nudoc-block-40`
print ('> let data = { name: alice, age: 50 }' | nu-highlight)
 let data = { name: alice, age: 50 }
print ('> { ...$data, hobby: cricket }' | nu-highlight)
try { { ...$data, hobby: cricket } | $in} catch {|e| $e} | print $in
print `###nudoc-block-43`
print ('> [sam fred george]' | nu-highlight)
do {nu -c ' [sam fred george]'} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print `###nudoc-block-46`
print ('> [bell book candle] | where ($it =~ 'b')' | nu-highlight)
try { [bell book candle] | where ($it =~ 'b') | $in} catch {|e| $e} | print $in
print `###nudoc-block-49`
print ('> [a b c].1' | nu-highlight)
do {nu -c ' [a b c].1'} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print `###nudoc-block-52`
print ('> [a b c d e f] | range 1..3' | nu-highlight)
do {nu -c ' [a b c d e f] | range 1..3'} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print `###nudoc-block-55`
print ('> let x = [1 2]' | nu-highlight)
 let x = [1 2]
print ('> [...$x 3 ...(4..7 | take 2)]' | nu-highlight)
try { [...$x 3 ...(4..7 | take 2)] | $in} catch {|e| $e} | print $in
print `###nudoc-block-58`
print ('> [[column1, column2]; [Value1, Value2] [Value3, Value4]]' | nu-highlight)
do {nu -c ' [[column1, column2]; [Value1, Value2] [Value3, Value4]]'} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print `###nudoc-block-61`
print ('> [{name: sam, rank: 10}, {name: bob, rank: 7}]' | nu-highlight)
do {nu -c ' [{name: sam, rank: 10}, {name: bob, rank: 7}]'} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print `###nudoc-block-64`
print ('> [{x:12, y:5}, {x:3, y:6}] | get 0' | nu-highlight)
do {nu -c ' [{x:12, y:5}, {x:3, y:6}] | get 0'} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print `###nudoc-block-67`
print ('> [[x,y];[12,5],[3,6]] | get 0' | nu-highlight)
do {nu -c ' [[x,y];[12,5],[3,6]] | get 0'} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print `###nudoc-block-70`
print ('> [{x:12 y:5} {x:4 y:7} {x:2 y:2}].x' | nu-highlight)
do {nu -c ' [{x:12 y:5} {x:4 y:7} {x:2 y:2}].x'} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print `###nudoc-block-73`
print ('> [{x:0 y:5 z:1} {x:4 y:7 z:3} {x:2 y:2 z:0}] | select y z' | nu-highlight)
do {nu -c ' [{x:0 y:5 z:1} {x:4 y:7 z:3} {x:2 y:2 z:0}] | select y z'} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print `###nudoc-block-76`
print ('> [{x:0 y:5 z:1} {x:4 y:7 z:3} {x:2 y:2 z:0}] | select 1 2' | nu-highlight)
do {nu -c ' [{x:0 y:5 z:1} {x:4 y:7 z:3} {x:2 y:2 z:0}] | select 1 2'} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print `###nudoc-block-79`
print ('> [{foo: 123}, {}].foo?' | nu-highlight)
do {nu -c ' [{foo: 123}, {}].foo?'} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print `###nudoc-block-82`
print ('# Assign a closure to a variable
let greet = { |name| print $"Hello ($name)"}
do $greet "Julian"' | nu-highlight)
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
print $x' | nu-highlight)
print '```
```nudoc-output'
mut x = 1
if true {
    $x += 1000
}
print $x
print `###nudoc-block-88`
print ('git checkout featurebranch | null' | nu-highlight)
print '```
```nudoc-output'
git checkout featurebranch | null
print `###nudoc-block-91`
print ('> [{a:1 b:2} {b:1}]' | nu-highlight)
do {nu -c ' [{a:1 b:2} {b:1}]'} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in
print ('> [{a:1 b:2} {b:1}].1.a' | nu-highlight)
do {nu -c ' [{a:1 b:2} {b:1}].1.a'} | complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | print $in