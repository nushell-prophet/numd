# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd

stor create --table-name 'captures' --columns {capture: str}
const init_numd_pwd_const = '/Users/user/git/numd/z_examples/7_image_output'

"# This is a simple markdown example

## Example 1

the block below will be executed as it is, but won't yield any output
" | print
"```nu p" | print
"ls ~ | first 2" | nu-highlight | print

"```\n```output-numd" | print

ls ~ | first 2 | table | {capture: $in} | stor insert --table-name captures

"```" | print

print (stor open | query db 'select * from captures')
