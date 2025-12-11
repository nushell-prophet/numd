---
status: in-progress
created: 20251210-171238
updated: 20251210-171238
---

## Goal: Remove `>` Notation for Command Execution

### Current Behavior (to be removed)
- Code blocks **with** `>` prefix: lines starting with `>` or `#` are filtered, executed one-by-one, results output immediately after each line
- Code blocks **without** `>` prefix: entire block executed as single unit, output appended after block

### New Behavior
1. **Parse entire block** without `>` notation
2. **Group commands by double newlines** (blank lines delimit command groups)
3. **Output results** in `# =>` comment lines immediately after each command group
4. **`separate-block` option** in fence produces separate output blocks instead of inline comments
5. **On re-run**: `# =>` lines are stripped and regenerated; plain `#` comments are preserved

### Example

Input:
```nushell
ls | length

echo "hello"
```

Output after execution:
```nushell
ls | length
# => 5

echo "hello"
# => hello
```

With `separate-block` fence option, output goes into a separate code fence instead of inline.

## Implementation Tasks

- [ ] Remove `>` notation parsing from `commands.nu`
- [ ] Implement command grouping by double newlines
- [ ] Generate `# =>` output lines after each command group
- [ ] Strip existing `# =>` lines before re-execution (preserve plain `#` comments)
- [ ] Add `separate-block` fence option support
- [ ] Update README.md documentation
- [ ] Update/fix affected example files in `z_examples/`
- [ ] Run tests and verify
