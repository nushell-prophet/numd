# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd

const init_numd_pwd_const = '/Users/user/git/numd'

"```nushell try" | print
"> lssomething" | nu-highlight | print

try {lssomething} catch {|error| $error} | table | print; print ''

"```" | print

"" | print
"```nushell try, new-instance" | print
"> lssomething" | nu-highlight | print

/Users/user/.cargo/bin/nu -c "lssomething"| complete | if ($in.exit_code != 0) {get stderr} else {get stdout} | table | print; print ''

"```" | print
