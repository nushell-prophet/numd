scope modules
| where name == 'dotnu'
| is-empty
| if $in { return }

use ../../numd

path self .
| path join dotnu-test.nu
| open
| numd parse-frontmatter
| print $in
