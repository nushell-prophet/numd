# This is a simple markdown example

## Example 1

the block below will be executed as it is, but won't yeld any output

```nu
let $var1 = 'foo'
```

## Example 2

```nu
# This block will produce some output in a separate block
$var1 | path join 'baz' 'bar'
```

Output:

```
foo/baz/bar
```

## Example 3

```nu
# This block will output results inline
> whoami
user

> 2 + 2
4
```
