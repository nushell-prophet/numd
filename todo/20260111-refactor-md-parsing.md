---
status: todo
created: 20260111
priority: high
---
# Refactor: Standardize markdown parsing across numd

Based on consistency analysis. `commands.nu` patterns have priority.

## Tasks

### 1. Remove `parse.nu`
- [ ] Remove `numd/parse.nu`
- [ ] Remove export from `numd/mod.nu`
- [ ] Update any usages to use `parse-md.nu` frontmatter parsing instead

### 2. Extract shared utilities to `numd/nu-utils/`
- [ ] `detect-fence.nu` - regex-based fence detection
- [ ] `track-block-state.nu` - scan-based state machine for fence/frontmatter
- [ ] `group-lines-to-blocks.nu` - window + group-by pattern
- [ ] Update `commands.nu` and `parse-md.nu` to use shared utilities

### 3. Use `commands.nu::extract-fence-options` in `parse-md.nu`
- [ ] Import `extract-fence-options` from `commands.nu`
- [ ] Replace inline option parsing in `classify-line`
- [ ] Add short form support (O, N, t, n, s)

### 4. Standardize naming (commands.nu has priority)
- [ ] Rename `element` → `row_type` in `parse-md.nu`
- [ ] Change `content: string` → `line: list<string>` format
- [ ] Update tests accordingly

### 5. Add missing elements to `live.nu`
- [ ] Add `ul` generator
- [ ] Add `ol` generator
- [ ] Add `blockquote` generator
- [ ] Add `frontmatter` generator
- [ ] Skip pseudo-xml (not needed in parse-md.nu)

### 6. Standardize interface pattern
- [ ] Update `commands.nu::parse-file` to accept optional path + pipe input
- [ ] Match `parse-md.nu` pattern: `[file?: path]: [string -> table nothing -> table]`

### 7. Fix meta structure asymmetry
- [ ] For `ul`/`ol`: put text in `content`, keep `items` in `meta` for parsed list
- [ ] Ensure all elements have meaningful `content` field

### 8. Consolidate state machines
- [ ] Create shared `track-block-context` helper
- [ ] Handles both fence and frontmatter state tracking
- [ ] Refactor both parsers to use it

## Notes

- Consider whether two parsers are still needed after standardization
- `commands.nu` parser is execution-focused (action column)
- `parse-md.nu` parser is semantic-focused (element types like h1-h6)
- May be possible to merge into one parser with optional columns
