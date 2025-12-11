
    # ```nushell
42 | describe


    # ```nushell
"-5" | into int


    # ```nushell
"1.2" | into float


    # ```nushell
let mybool = 2 > 1
$mybool

let mybool = ($nu.home-path | path exists)
$mybool


    # ```nushell
3.14day


    # ```nushell
30day / 1sec  # How many seconds in 30 days?


    # ```nushell
1Gb / 1b

1Gib / 1b

(1Gib / 1b) == 2 ** 30


    # ```nushell
0x[1F FF]  # Hexadecimal

0b[1 1010] # Binary

0o[377]    # Octal


    # ```nushell
{name: sam rank: 10}


    # ```nushell
{x:3 y:1} | insert z 0


    # ```nushell
{name: sam, rank: 10} | transpose key value


    # ```nushell
{x:12 y:4}.x


    # ```nushell
{"1":true " ":false}." "


    # ```nushell
let data = { name: alice, age: 50 }
{ ...$data, hobby: cricket }


    # ```nushell
[sam fred george]


    # ```nushell
[bell book candle] | where ($it =~ 'b')


    # ```nushell
[a b c].1


    # ```nushell
[a b c d e f] | slice 1..3


    # ```nushell
let x = [1 2]
[...$x 3 ...(4..7 | take 2)]


    # ```nushell
[[column1, column2]; [Value1, Value2] [Value3, Value4]]


    # ```nushell
[{name: sam, rank: 10}, {name: bob, rank: 7}]


    # ```nushell
[{x:12, y:5}, {x:3, y:6}] | get 0


    # ```nushell
[[x,y];[12,5],[3,6]] | get 0


    # ```nushell
[{x:12 y:5} {x:4 y:7} {x:2 y:2}].x


    # ```nushell
[{x:0 y:5 z:1} {x:4 y:7 z:3} {x:2 y:2 z:0}] | select y z


    # ```nushell
[{x:0 y:5 z:1} {x:4 y:7 z:3} {x:2 y:2 z:0}] | select 1 2


    # ```nushell
[{foo: 123}, {}].foo?


    # ```nushell
# Assign a closure to a variable
let greet = { |name| print $"Hello ($name)"}

do $greet "Julian"


    # ```nushell
mut x = 1
if true {
    $x += 1000
}

print $x
1001
1001
1001


    # ```nushell try,new-instance
[{a:1 b:2} {b:1}]

[{a:1 b:2} {b:1}].1.a
