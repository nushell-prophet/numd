# Generate-region example

A hand-written short marker `<!-- numd-gen: <command> -->` expands on the first run into the `numd-gen-start` … `numd-gen-end` pair; the content between the pair is replaced with the command's stdout on every run.

<!-- numd-gen-start: [[name value]; [alpha 1] [beta 2]] | to md -->
| name | value |
| --- | --- |
| alpha | 1 |
| beta | 2 |
<!-- numd-gen-end -->

Fenced blocks inside a region are content, never executed; the marker below is inside a fence, so it stays inert:

```markdown
<!-- numd-gen: this is not executed -->
```
