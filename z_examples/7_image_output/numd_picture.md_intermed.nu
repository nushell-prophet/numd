# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd

const init_numd_pwd_const = '/Users/user/git/numd/z_examples/7_image_output'

"# This is a simple markdown example

## Example 1

the block below will be executed as it is, but won't yield any output
" | print
$env.numd.capture_lines = []
"```nu p" | print
"ls ~ | first 2" | nu-highlight | table | do --env {|i| $env.numd.capture_lines ++= $i; $i} $in | print

"```\n```output-numd" | print

ls ~ | first 2 | table | do --env {|i| $env.numd.capture_lines ++= $i; $i} $in

"```" | print
$env.numd.capture_lines | to text | freeze -o media/7.png --language ansi | complete | null

"╭─#─┬───────name────────┬─type─┬─size──┬──modified───╮
│ 0 │ /Users/user/Music │ dir  │ 288 B │ 2 years ago │
│ 1 │ /Users/user/temp  │ dir  │ 480 B │ 5 hours ago │
╰─#─┴───────name────────┴─type─┴─size──┴──modified───╯
" | print
$env.numd.capture_lines = []
"```nu p" | print
"> ls ~ | last 2" | nu-highlight | table | do --env {|i| $env.numd.capture_lines ++= $i; $i} $in | print

ls ~ | last 2 | table | do --env {|i| $env.numd.capture_lines ++= $i; $i} $in

"```" | print
$env.numd.capture_lines | to text | freeze -o media/15.png --language ansi | complete | null

"" | print
$env.numd.capture_lines = []
"```nu p" | print
"> ls ~ | skip 2 | first 2" | nu-highlight | table | do --env {|i| $env.numd.capture_lines ++= $i; $i} $in | print

ls ~ | skip 2 | first 2 | table | do --env {|i| $env.numd.capture_lines ++= $i; $i} $in

"```" | print
$env.numd.capture_lines | to text | freeze -o media/19.png --language ansi | complete | null
