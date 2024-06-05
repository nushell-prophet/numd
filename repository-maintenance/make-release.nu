let $git_info = gh repo view --json description,name | from json
let $git_tag = git tag | lines | sort -n | last | split row '.' | into int | update 2 {$in + 1} | str join '.'
let $desc = $git_info.description

open nupm.nuon
| update description ($desc | str replace 'numd - ' '')
| update version $git_tag
| save -f nupm.nuon

open README.md -r
| lines
| update 0 ('<h1 align="center">' + $desc + '</h1>')
| str join (char nl)
| $in + (char nl)
| save -r README.md -f

# prettier README.md -w

# use nupm
# nupm install --force --path .

git add nupm.nuon
git commit -m $'($git_tag) nupm version'
git tag $git_tag
git push origin $git_tag
