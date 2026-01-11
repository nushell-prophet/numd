---
status: done
created: 20260111
updated: 20260111
---
# Consistency Analysis: `parse-md.nu` vs numd/ codebase

## Summary

Analysis of architectural inconsistencies, duplicated logic, and interface mismatches between the new `parse-md.nu` and existing numd/ modules.

## 1. Duplicate Frontmatter Parsing

**Two implementations exist:**

| File | Function | Output Format |
|------|----------|---------------|
| `parse.nu` | `parse-frontmatter` | `{content: "body...", title: "...", ...yaml_fields}` |
| `parse-md.nu` | `parse-md` | `{element: "frontmatter", content: "raw_yaml", meta: {title: "...", ...}}` |

**Differences:**
- `parse.nu` flattens yaml into top-level record, body goes to `content`
- `parse-md.nu` keeps yaml in `meta`, raw yaml string in `content`

**Recommendation:** Consider whether `parse-md.nu` should use `parse.nu::parse-frontmatter` internally, or if both are needed for different use cases.

remove parse.nu

## 2. Two Markdown Block Parsers

**Different purposes, similar implementations:**

| Aspect | `commands.nu::parse-markdown-to-blocks` | `parse-md.nu::parse-md-to-blocks` |
|--------|----------------------------------------|-----------------------------------|
| Purpose | Execution pipeline | Semantic analysis |
| Columns | `block_index, row_type, line, action` | `block_index, element, content, meta` |
| `line` type | `list<string>` | `string` (joined) |
| Classification | By fence type + action | By markdown element type |
| Uses | `run`, `clear-outputs` | Standalone parsing |

**Shared patterns (duplicated code):**
- `scan` for state tracking (fence/frontmatter)
- `window --remainder 2` for block boundary detection
- `group-by block_index --to-table` for grouping
- Regex `^```\w*` for fence detection

**Recommendation:** Extract shared patterns into `numd/nu-utils/` helpers.

extract

## 3. Code Fence Option Parsing

**Two implementations:**

```nushell
# commands.nu:652 - extract-fence-options
'```nushell no-run, try' | extract-fence-options
# => [no-run, try]

# parse-md.nu:22-30 - inline in classify-line
'```nushell no-run, try' | classify-line
# => {type: 'fence', lang: 'nushell', options: ['no-run', 'try']}
```

**Differences:**
- `commands.nu` version handles short form expansion (O → no-output)
- `parse-md.nu` version is simpler, no short form support

**Recommendation:** `parse-md.nu` should use `commands.nu::extract-fence-options` or `convert-short-options` for consistency.

use version from commands.nu

## 4. Naming Inconsistencies

| Concept | `commands.nu` | `parse-md.nu` |
|---------|---------------|---------------|
| Block type | `row_type` | `element` |
| Code fence | `'```nushell'` | `'fence'` / `'code'` |
| Plain text | `'text'` | `'text'` / `'p'` |
| Block content | `line: list<string>` | `content: string` |

**Recommendation:** Standardize naming if modules will be used together.

Create a new todo to refactor this. We need to reuse the functionality and standartize logic. commands.nu version has priority

## 5. `live.nu` vs `parse-md.nu` Alignment

`live.nu` generates markdown, `parse-md.nu` parses it. They should be symmetric.

| Element | `live.nu` generates | `parse-md.nu` parses |
|---------|--------------------|-----------------------|
| h1-h6 | ✅ | ✅ |
| paragraph | ✅ (`p`) | ✅ (`p`) |
| code | ✅ (with options) | ✅ (lang, options in meta) |
| ul/ol | ❌ | ✅ |
| blockquote | ❌ | ✅ |
| frontmatter | ❌ | ✅ |
| pseudo-xml | ✅ | ❌ |

**Gaps:**
- `live.nu` missing: `ul`, `ol`, `blockquote`, `frontmatter` generators
- `parse-md.nu` missing: `pseudo-xml` parsing

add missing to live.nu, ignore pseudo-xml

## 6. Interface Pattern Differences

**File input handling:**

```nushell
# parse-md.nu - both pipe and path parameter
export def main [file?: path]: [string -> table nothing -> table]

# parse.nu - same pattern but slightly different
export def 'parse-frontmatter' [file?: path]: [string -> record nothing -> record]

# commands.nu - path only, no pipe
export def parse-file [file: path]: nothing -> table
```

**Recommendation:** Standardize the pattern - the `parse-md.nu` pattern (optional path, can pipe) is most flexible.

Standartize

## 7. Meta Structure Inconsistencies

`parse-md.nu` uses `meta` differently for each element:

| Element | `meta` contents |
|---------|-----------------|
| frontmatter | `{title: ..., date: ...}` - parsed yaml |
| code | `{lang: "nushell", options: [...]}` |
| ul | `{items: [...]}` |
| ol | `{items: [...], start: N}` |
| blockquote | `{type: "note"}` or `{}` |
| h1-h6, p | `{}` |

**Potential issue:** For `ul`/`ol`, content is empty and items are in `meta`. For other elements, content holds the text. This asymmetry may be confusing.

fix

## 8. State Machine Duplication

Both files implement similar state machines:

```nushell
# commands.nu:169-178 - tracks fence state
| scan --noinit 'text' {|curr_fence prev_fence| ... }

# parse-md.nu:137-158 - tracks in_fm, fm_possible, in_code
| scan {in_fm: false, fm_possible: true, in_code: false, code_info: null} {|class state| ... }
```

**Recommendation:** Consider a shared `track-block-context` helper.

create a todo to refactor this
