# run-once fence option

After numd run, the run-once block below should become no-run with output preserved.

```nu run-once
2 + 2
```

This block uses run-once combined with no-output.

```nu run-once, no-output
3 + 3
```
