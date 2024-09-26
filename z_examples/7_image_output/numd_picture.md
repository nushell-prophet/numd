# This is a simple markdown example

## Example 1

the block below will be executed as it is, but won't yield any output

```nu p
ls ~ | first 2
```
![](media/numd/7.png) <!-- numd-image -->
![](media/numd/7.png) <!-- numd-image -->
╭─#─┬───────name────────┬─type─┬─size──┬──modified───╮
│ 0 │ /Users/user/Music │ dir  │ 288 B │ 2 years ago │
│ 1 │ /Users/user/temp  │ dir  │ 480 B │ 5 hours ago │
╰─#─┴───────name────────┴─type─┴─size──┴──modified───╯

```nu p
ls ~ | first 2 | print
ls ~ | last 4 | drop 2
```

Output:

```
╭─#─┬───────name────────┬─type─┬─size──┬──modified───╮
│ 0 │ /Users/user/Music │ dir  │ 288 B │ 2 years ago │
│ 1 │ /Users/user/temp  │ dir  │ 480 B │ 2 days ago  │
╰─#─┴───────name────────┴─type─┴─size──┴──modified───╯
```
![](media/numd/16.png) <!-- numd-image -->
![](media/numd/18.png) <!-- numd-image -->

```nu p
> ls ~ | last 2
```
![](media/numd/22.png) <!-- numd-image -->
![](media/numd/32.png) <!-- numd-image -->

```nu p
> ls ~ | skip 2 | first 2
> ls ~ | skip 4 | first 2
```
![](media/numd/27.png) <!-- numd-image -->
![](media/numd/39.png) <!-- numd-image -->
