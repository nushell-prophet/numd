# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd
const init_numd_pwd_const = '/Users/user/git/numd'
"raw strings test
" | print
"```nu" | print
"let $two_single_lines_text = r#'\"High up in the mountains, a Snake crawled and lay in a damp gorge, coiled
    into a knot, staring out at the sea.'#" | nu-highlight | print

"```\n```output-numd" | print

let $two_single_lines_text = r#'"High up in the mountains, a Snake crawled and lay in a damp gorge, coiled
    into a knot, staring out at the sea.'#

"```" | print

"" | print
"```nu" | print
"$two_single_lines_text" | nu-highlight | print

"```\n```output-numd" | print

$two_single_lines_text | print; print ''

"```" | print
