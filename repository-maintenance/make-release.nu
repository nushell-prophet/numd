let $98 = (gh repo view nushell101/nudoc --json description | from json | get description);

open nupm.nuon | update description ($98 | str replace 'nudoc - ' '') | update version (git tag | lines | sort -n | last) | save -f nupm.nuon

open README.md -r | lines | update 0 ('# ' + $98) | str join (char nl) | $in + (char nl) | save -r README.md -f

use nupm
nupm install --force --path .
