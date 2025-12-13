---
status: done
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

ls
| length

echo "hello"
```

Output after execution:
```nushell
ls | length
# => 5

ls
| length
# => 5

echo "hello"
# => hello
```

With `separate-block` fence option, output goes into a separate code fence instead of inline.

## Functions to Modify in `numd/commands.nu`

### Primary Changes

| Function | Lines | Current Role | Change Required |
|----------|-------|--------------|-----------------|
| `execute-block-lines` | 386-409 | Detects `>` prefix, branches to line-by-line vs whole-block | Rewrite: split by blank lines, execute each group, insert `# =>` output |
| `remove-comments-plus` | 611-615 | Strips `>` prefix before execution | Remove `>` stripping logic |
| `clear-outputs` | 79-121 | Preserves `>` lines, removes `# =>` | Remove `>` preservation, keep `# =>` stripping |
| `capture start` | 124-172 | Generates `> command` format | Remove `>` notation generation |
| `create-indented-output` | 688-693 | Generates `# => ` prefix for output | Keep, but adjust calling context |

### Supporting Changes

| Function | Lines | Role | Change |
|----------|-------|------|--------|
| `create-execution-code` | ~360-385 | Wraps code for execution | May need adjustment for group-based execution |
| `decortate-original-code-blocks` | ~320-360 | Calls `execute-block-lines` | Update to pass groups |
| `create-highlight-command` | ~617-625 | Highlights comment lines | Review if still needed |

### New Code Required

- [ ] Function to split block content by blank lines into command groups
- [ ] Logic to execute each group and capture output
- [ ] Insert `# =>` lines after each group in the result

## Implementation Tasks

- [ ] Rewrite `execute-block-lines` for blank-line grouping
- [ ] Remove `>` stripping from `remove-comments-plus`
- [ ] Update `clear-outputs` to not preserve `>` lines
- [ ] Update `capture start` to remove `>` notation generation
- [ ] Add `separate-block` fence option support
- [ ] Update README.md documentation
- [ ] Update example files in `z_examples/`
- [ ] Add/update unit tests in `tests/test_commands.nu`
- [ ] Run integration tests and verify
