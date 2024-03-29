# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd
cd /Users/user/git/numd
const init_numd_pwd_const = '/Users/user/git/numd'
print "###code-block-starting-line-in-original-md-7"
print "```nu"
print ("let $var1 = 'foo'" | nu-highlight)
print '```
```numd-output'
let $var1 = 'foo'

print "```"
print "###code-block-starting-line-in-original-md-13"
print "```nu"
print ("# This chunk will produce some output in the separate block
ls; # mind that this ls won't print in the markdown as it is used without `echo` or `>`
$var1 | path join 'baz' 'bar'" | nu-highlight)
print '```
```numd-output'
# This chunk will produce some output in the separate block
ls; # mind that this ls won't print in the markdown as it is used without `echo` or `>`
$var1 | path join 'baz' 'bar' | echo $in

print "```"
print "###code-block-starting-line-in-original-md-24"
print "```nu"
print ("# This chunk will output results inline" | nu-highlight)

print ("> whoami" | nu-highlight)
whoami | echo $in

print ("> 2 + 2" | nu-highlight)
2 + 2 | echo $in

print "```"