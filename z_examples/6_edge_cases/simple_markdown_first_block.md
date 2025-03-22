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
# => foo/baz/bar
```

## Example 3

```nu
# This block will output results inline
> whoami
# => user

> 2 + 2
# => 4
```
