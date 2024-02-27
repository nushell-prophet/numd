let $98 = (gh repo view nushell101/nudoc --json description | from json | get description);
let $git_tag = (git tag | lines | sort -n | last | inc -p)

open nupm.nuon
| update description ($98
| str replace 'nudoc - ' '')
| update version $git_tag
| save -f nupm.nuon

open README.md -r
| lines
| update 0 ('<h1 align="center">' + $98 + '</h1>')
| str join (char nl)
| $in + (char nl)
| save -r README.md -f

prettier README.md -w

use nupm
nupm install --force --path .

git add nupm.nuon
git commit -m $'($git_tag) nupm version'
git tag $git_tag
