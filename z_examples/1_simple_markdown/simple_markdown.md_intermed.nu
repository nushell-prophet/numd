# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd

const init_numd_pwd_const = '/Users/user/git/numd'

"# This is a simple markdown example

## Example 1

the block below will be executed as it is, but won't yield any output
" | print
"```nu" | print
"let $var1 = 'foo'" | nu-highlight | print

"```\n```output-numd" | print

let $var1 = 'foo'

"```" | print

"
## Example 2
" | print
"```nu" | print
"# This block will produce some output in a separate block
$var1 | path join 'baz' 'bar'" | nu-highlight | print

"```\n```output-numd" | print

# This block will produce some output in a separate block
$var1 | path join 'baz' 'bar' | table | print; print ''

"```" | print

"
## Example 3
" | print
"```nu" | print
"# This block will output results inline" | nu-highlight | print


"> whoami" | nu-highlight | print

whoami | table | print; print ''

"> 2 + 2" | nu-highlight | print

2 + 2 | table | print; print ''

"```" | print
