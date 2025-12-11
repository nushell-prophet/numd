# This is a simple markdown example

## Example 1

the block below will be executed as it is, but won't yield any output

```nu
let $var1 = 'foo'
```

## Example 2

```nu
# This block will produce some output in a separate block
$var1 | path join 'baz' 'bar'
# => foo/baz/bar
```

## Example 3

```nu
# This block will output results inline
whoami
# => user

2 + 2
# => 4
```

## Example 4

```
# This block doesn't have a language identifier in the opening fence
```
