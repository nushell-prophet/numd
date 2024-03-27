# This is a simple markdown example

## Example 1

the chunk below will be executed as it is, but won't yeld any output

```nu
let $var1 = 'foo'
```

## Example 2

```nu
# This chunk will produce some output in the separate block
ls; # mind that this ls won't print in the markdown as it is used without `echo` or `>`
$var1 | path join 'baz' 'bar'
```
```nudoc-output
foo/baz/bar
```

## Example 3

```nu
# This chunk will write results into itself
> whoami
user
> date now
Wed, 27 Mar 2024 13:59:37 +0000 (now)
```
