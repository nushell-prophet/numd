# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd

const init_numd_pwd_const = '/Users/user/git/numd/z_examples/7_image_output'

"# This is a simple markdown example

## Example 1

the block below will be executed as it is, but won't yield any output
" | print
stor open | query db 'CREATE TABLE IF NOT EXISTS captures (capture text)'
"```nu p" | print
"ls ~ | first 2" | nu-highlight | print

"```\n```output-numd" | print

ls ~ | first 2 | table | do {|i| stor open | query db "insert into 'captures' (capture) values (?)" -p [$i]} $in

"```" | print
stor open | query db 'select capture from captures' | get capture | to text | print
stor delete --table-name captures --where-clause '1' | null

"╭─#─┬───────name────────┬─type─┬─size──┬──modified───╮
│ 0 │ /Users/user/Music │ dir  │ 288 B │ 2 years ago │
│ 1 │ /Users/user/temp  │ dir  │ 480 B │ 5 hours ago │
╰─#─┴───────name────────┴─type─┴─size──┴──modified───╯

╭─#─┬───────name────────┬─type─┬─size──┬──modified───╮
│ 0 │ /Users/user/Music │ dir  │ 288 B │ 2 years ago │
│ 1 │ /Users/user/temp  │ dir  │ 480 B │ 5 hours ago │
╰─#─┴───────name────────┴─type─┴─size──┴──modified───╯
" | print
stor open | query db 'CREATE TABLE IF NOT EXISTS captures (capture text)'
"```nu p" | print
"ls ~ | last 2" | nu-highlight | print

"```\n```output-numd" | print

ls ~ | last 2 | table | do {|i| stor open | query db "insert into 'captures' (capture) values (?)" -p [$i]} $in

"```" | print
stor open | query db 'select capture from captures' | get capture | to text | print
stor delete --table-name captures --where-clause '1' | null

"╭─#─┬──────────name──────────┬─type─┬──size──┬──modified──╮
│ 0 │ /Users/user/git        │ dir  │ 4.9 KB │ a day ago  │
│ 1 │ /Users/user/miniconda3 │ dir  │  736 B │ 3 days ago │
╰─#─┴──────────name──────────┴─type─┴──size──┴──modified──╯
" | print
stor open | query db 'CREATE TABLE IF NOT EXISTS captures (capture text)'
"```nu p" | print
"ls ~ | skip 2 | first 2" | nu-highlight | print

"```\n```output-numd" | print

ls ~ | skip 2 | first 2 | table | do {|i| stor open | query db "insert into 'captures' (capture) values (?)" -p [$i]} $in

"```" | print
stor open | query db 'select capture from captures' | get capture | to text | print
stor delete --table-name captures --where-clause '1' | null

"╭─#─┬──────────────────────name───────────────────────┬─type─┬─size──┬───modified───╮
│ 0 │ /Users/user/perl5                               │ dir  │ 192 B │ 4 months ago │
│ 1 │ /Users/user/frequent-commands-sys-info-yaml.txt │ file │ 319 B │ a year ago   │
╰─#─┴──────────────────────name───────────────────────┴─type─┴─size──┴───modified───╯" | print
