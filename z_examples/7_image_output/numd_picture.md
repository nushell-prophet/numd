# This is a simple markdown example

## Example 1

the block below will be executed as it is, but won't yield any output

```nu p
ls ~ | first 2
```
╭─#─┬───────name────────┬─type─┬─size──┬──modified───╮
│ 0 │ /Users/user/Music │ dir  │ 288 B │ 2 years ago │
│ 1 │ /Users/user/temp  │ dir  │ 480 B │ 5 hours ago │
╰─#─┴───────name────────┴─type─┴─size──┴──modified───╯

```nu p
ls ~ | last 2
```

```nu p
ls ~ | skip 2 | first 2
```
