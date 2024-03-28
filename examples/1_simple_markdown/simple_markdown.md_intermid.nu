# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd
cd /Users/user/git/nudoc
const init_numd_pwd_const = '/Users/user/git/nudoc'
print "###numd-block-1"
print "```nu"
print ("let $var1 = 'foo'" | nu-highlight)
print '```
```numd-output'
let $var1 = 'foo'

print "```"
print "###numd-block-4"
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
print "###numd-block-9"
print "```nu"
print ("# This chunk will output results inline" | nu-highlight)

print ("> whoami" | nu-highlight)
whoami | echo $in

print ("> date now" | nu-highlight)
date now | echo $in

print "```"