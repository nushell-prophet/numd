# this script was generated automatically using nudoc
# https://github.com/nushell-prophet/nudoc
print "###nudoc-block-1"
print "```nu"
print ("let $var1 = 'foo'" | nu-highlight)
print '```
```nudoc-output'
let $var1 = 'foo'

print "###nudoc-block-4"
print "```nu"
print ("# This chunk will produce some output in the separate block
ls; # mind that this ls won't print in the markdown as it is used without `echo` or `>`
$var1 | path join 'baz' 'bar'" | nu-highlight)
print '```
```nudoc-output'
# This chunk will produce some output in the separate block
ls; # mind that this ls won't print in the markdown as it is used without `echo` or `>`
$var1 | path join 'baz' 'bar' | echo $in

print "###nudoc-block-9"
print "```nu"
print ("# This chunk will output results inline" | nu-highlight)

print ("> whoami" | nu-highlight)
whoami | echo $in

print ("> date now" | nu-highlight)
date now | echo $in
