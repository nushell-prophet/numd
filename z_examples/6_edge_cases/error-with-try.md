```nushell try
> lssomething
╭───────┬────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ msg   │ External command failed                                                                                                                                                                    │
│ debug │ ExternalCommand { label: "Command `lssomething` not found", help: "`lssomething` is neither a Nushell built-in or a known external command", span: Span { start: 1967919, end: 1967930 } } │
│ raw   │ ExternalCommand { label: "Command `lssomething` not found", help: "`lssomething` is neither a Nushell built-in or a known external command", span: Span { start: 1967919, end: 1967930 } } │
╰───────┴────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
```

```nushell try, new-instance
> lssomething
Error: nu::shell::external_command

  × External command failed
   ╭─[source:1:1]
 1 │ lssomething
   · ─────┬─────
   ·      ╰── Command `lssomething` not found
   ╰────
  help: `lssomething` is neither a Nushell built-in or a known external command
```
