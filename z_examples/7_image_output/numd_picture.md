# This is a simple markdown example

## Example 1

the block below will be executed as it is, but won't yield any output

```nu p
ls ~ | first 2
```
![](media/7.png)
╭─#─┬───────name────────┬─type─┬─size──┬──modified───╮
│ 0 │ /Users/user/Music │ dir  │ 288 B │ 2 years ago │
│ 1 │ /Users/user/temp  │ dir  │ 480 B │ 5 hours ago │
╰─#─┴───────name────────┴─type─┴─size──┴──modified───╯

```nu p
> ls ~ | last 2
```
![](media/16.png)

```nu p
> ls ~ | skip 2 | first 2
> ls ~ | skip 4 | first 2
```
![](media/21.png)
