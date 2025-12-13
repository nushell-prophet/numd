
    # ```nu
let $var1 = 'foo'


    # ```nu separate-block
# This block will produce some output in a separate block
$var1 | path join 'baz' 'bar'


    # ```nu
# This block will output results inline
whoami

2 + 2
