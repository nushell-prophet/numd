# Nushell Code Design Guide

This document captures Maxim Uvarov's Nushell coding style, extracted from the numd repository history (September 2024 onwards). Use it as a reference for maintaining consistency in AI-assisted development.

## Table of Contents

- [Pipeline Composition](#pipeline-composition)
- [Command Choices](#command-choices)
- [Code Structure](#code-structure)
- [Formatting Conventions](#formatting-conventions)
- [Maxim vs Claude: Style Contrasts](#maxim-vs-claude-style-contrasts)

---

## Pipeline Composition

### Leading Pipe Operator

Place `|` at the start of continuation lines, left-aligned with `let`:

```nushell
# Preferred
let row_type = $file_lines
| each {
    str trim --right
    | if $in =~ '^```' { } else { 'text' }
}
| scan --noinit 'text' {|curr prev| ... }

# Avoid
let row_type = $file_lines | each {
    str trim --right | if $in =~ '^```' { } else { 'text' }
} | scan --noinit 'text' {|curr prev| ... }
```

### Conditional Pass-Through with Empty `{ }`

Use empty `{ }` for the branch that passes through unchanged:

```nushell
# Pass through on false condition
| if $nu.os-info.family == windows {
    str replace --all (char crlf) "\n"
} else { }

# Pass through on true condition
| if $echo { } else {
    save -f $file
}

# Multiple chained conditions
| if 'no-output' in $fence_options { return $in } else { }
| if 'separate-block' in $fence_options { generate-separate-block-fence } else { }
| if (can-append-print $in) {
    generate-inline-output-pipeline
    | generate-print-statement
} else { }
```

### `scan` for Stateful Transformations

Use `scan --noinit` to process sequences with state:

```nushell
# State machine for tracking fence context
| scan --noinit 'text' {|curr_fence prev_fence|
    match $curr_fence {
        'text' => { if $prev_fence == 'closing-fence' { 'text' } else { $prev_fence } }
        '```' => { if $prev_fence == 'text' { '```' } else { 'closing-fence' } }
        _ => { $curr_fence }
    }
}
```

### `window` for Adjacent Elements

Use `window --remainder` to look at pairs/adjacent items:

```nushell
| window --remainder 2
| scan 0 {|window index|
    if $window.0 == $window.1? { $index } else { $index + 1 }
}
```

### Data-First Filtering

Define all data upfront, then filter. Prefer `where` over `each {if} | compact`:

```nushell
# Preferred: data-first, filter with where
[
    [--env-config $nu.env-path]
    [--config $nu.config-path]
    [--plugin-config $nu.plugin-path]
]
| where {|i| $i.1 | path exists }
| flatten

# Avoid: spread operator with conditionals
[
    ...(if ($nu.env-path | path exists) { [--env-config $nu.env-path] } else { [] })
    ...(if ($nu.config-path | path exists) { [--config $nu.config-path] } else { [] })
]

# Avoid: each + if + compact (use where instead)
| each {|i| if ($i.1 | path exists) { $i } }
| compact
```

### Pipeline Append vs Spread

For conditional list building, prefer pipeline with `append` or data-first approach:

```nushell
# Preferred: start empty, append conditionally
[]
| if $cond1 { append [a b] } else { }
| if $cond2 { append [c d] } else { }

# Or: data-first with filtering (often cleaner)
[[a b] [c d]]
| where { some-condition $in }
| flatten
```

### Building Tables with `wrap` and `merge`

Construct tables column-by-column:

```nushell
$file_lines | wrap line
| merge ($row_type | wrap row_type)
| merge ($block_index | wrap block_index)
| group-by block_index --to-table
| insert row_type { $in.items.row_type.0 }
| update items { get line }
| rename block_index line row_type
```

---

## Command Choices

### Preferred Commands

| Task | Preferred | Avoid |
|------|-----------|-------|
| Filtering | `where` | `filter` |
| Parallel with order | `par-each --keep-order` | `par-each` (when order matters) |
| Pattern dispatch | `match` expression | Long `if/else if` chains |
| Record iteration | `items {\|k v\| ...}` | Manual key extraction |
| Table grouping | `group-by ... --to-table` | Manual grouping |
| Line joining | `str join (char nl)` | `to text` (context dependent) |

### `match` for Type/Pattern Dispatch

```nushell
export def classify-block-action [
    $row_type: string
]: nothing -> string {
    match $row_type {
        'text' => { 'print-as-it-is' }
        '```output-numd' => { 'delete' }

        $i if ($i =~ '^```nu(shell)?(\s|$)') => {
            if $i =~ 'no-run' { 'print-as-it-is' } else { 'execute' }
        }

        _ => { 'print-as-it-is' }
    }
}
```

### `items` for Record Iteration

```nushell
$record
| items {|k v|
    $v
    | str replace -r '^\s*(\S)' '  $1'
    | str join (char nl)
    | $"($k):\n($in)"
}
```

### Safe Navigation with `?`

Use optional access for potentially missing fields:

```nushell
$env.numd?.table-width? | default 120
$env.numd?.prepend-code?
```

---

## Code Structure

### Type Signatures

Always include input/output type signatures:

```nushell
export def clean-markdown []: string -> string {
    ...
}

export def parse-markdown-to-blocks []: string -> table<block_index: int, row_type: string, line: list<string>, action: string> {
    ...
}

# Multiple return types (no commas)
export def run [
    file: path
]: [nothing -> string nothing -> nothing nothing -> record] {
    ...
}
```

### @example Annotations

Document functions with executable examples:

```nushell
@example "generate marker for block 3" {
    code-block-marker 3
} --result "#code-block-marker-open-3"
export def code-block-marker [
    index?: int
    --end
]: nothing -> string {
    ...
}
```

### Semantic Action Labels

Use meaningful labels instead of pattern matching throughout:

```nushell
# Preferred: semantic labels
| where action == 'execute'
| where action != 'delete'

# Avoid: repeated regex matching
| where row_type =~ '^```nu(shell)?(\s|$)'
```

### Const for Static Data

Use `const` for lookup tables and static data:

```nushell
const fence_options = [
    [short long description];

    [O no-output "execute code without outputting results"]
    [N no-run "do not execute code in block"]
    [t try "execute block inside `try {}` for error handling"]
    [n new-instance "execute block in new Nushell instance"]
    [s separate-block "output results in separate code block"]
]

export def list-fence-options []: nothing -> table {
    $fence_options | select long short description
}
```

### Minimal Comments

Code should be self-documenting. Use comments for "why", not "what":

```nushell
# Preferred: explain non-obvious decisions
# I set variables here to prevent collecting $in var
let expanded_format = "\n```\n\nOutput:\n\n```\n"

# Avoid: obvious comments
# This function cleans markdown
export def clean-markdown [] { ... }
```

---

## Formatting Conventions

These follow Topiary formatter conventions.

### Empty Blocks with Space

```nushell
# Preferred
} else { }
| if $in == null { } else { str join (char nl) }

# Avoid
} else {}
| if $in == null {} else { str join (char nl) }
```

### Closure Spacing

Single-expression closures have spaces inside braces:

```nushell
# Preferred
| update line { str join (char nl) }
| each { $in.items.row_type.0 }
| update metric { $'diff_($in)' }

# Avoid
| update line {str join (char nl)}
| each {$in.items.row_type.0}
```

### Flag Spacing

Space between long and short form:

```nushell
# Preferred
--noinit (-n)
--restore (-r)

# Avoid
--noinit(-n)
```

### Multi-line Records

```nushell
# Preferred
return {
    filename: $file
    comment: "the script didn't produce any output"
}

# Avoid
return { filename: $file,
    comment: "the script didn't produce any output" }
```

### External Command Parentheses

Avoid unnecessary parentheses around external commands:

```nushell
# Preferred
^$nu.current-exe ...$args $script
| complete

# Avoid
(^$nu.current-exe ...$args $script)
| complete
```

For multi-line external commands, use parentheses with proper formatting:

```nushell
# Preferred
(
    ^$nu.current-exe --env-config $nu.env-path --config $nu.config-path
    --plugin-config $nu.plugin-path $intermed_script_path
)

# Avoid
(^$nu.current-exe --env-config $nu.env-path --config $nu.config-path
    --plugin-config $nu.plugin-path $intermed_script_path)
```

### Variable Declarations

No `$` prefix on left-hand side of declarations:

```nushell
# Preferred
let original_md = open -r $file
let row_type = $file_lines | each { ... }

# Avoid (older style)
let $original_md = open -r $file
```

---

## Maxim vs Claude: Style Contrasts

Understanding these differences helps maintain consistency.

### Closure Parameters

Prefer `$in`: `{ $in.line }`

Name when helpful: `{|block| $block.line}`

```nushell
| each {|block|
    if $block.block_index in $result_indices {
        let result = $results | where block_index == $block.block_index
        $block | update line { $result.line | lines }
    }
}
```

**Guideline**: Use named parameters when the closure body is complex or references the parameter multiple times.

### Variable Naming

| Maxim | Claude |
|-------|--------|
| Concise when scope is small | Always descriptive |

```nushell
# Maxim's style - context makes meaning clear
| rename s f
| into int s f
let len = $longest_last_span_start - $last_span_end

# Claude's style - self-documenting
| rename start end
| into int start end
let offset = $longest_last_span_start - $last_span_end
```

**Guideline**: Use concise names for local variables with small scope; be more descriptive for parameters and exports.

### Helper Function Extraction

| Maxim | Claude |
|-------|--------|
| Logic inline in main function | Extract named helpers |

```nushell
# Maxim's style - inline logic
| if (check-print-append $in) {
    create-indented-output
    | generate-print-statement
} else { }

# Claude's style - extracted helper
def apply-output-formatting [fence_options: list<string>]: string -> string {
    if 'no-output' in $fence_options { return $in } else { }
    | if 'separate-block' in $fence_options { generate-separate-block-fence } else { }
    | if (can-append-print $in) {
        generate-inline-output-pipeline
        | generate-print-statement
    } else { }
}
```

**Guideline**: Keep logic inline unless it's reused or the function becomes too long.

### Negation Syntax

Prefer `$x !~ ...` over `not ($x =~ ...)` 

```nushell
| where $it !~ '^# =>'    # Preferred
```

### Commit Messages

Use Conventional commit format 

```
refactor: simplify closures using $in instead of named parameters
feat: add --ignore-git-check flag and error on uncommitted changes
fix: preserve existing $env.numd fields in load-config
```

---

## Quick Reference

### Do

- Start continuation lines with `|`
- Use empty `else { }` for pass-through
- Use `match` for type dispatch
- Use `scan` for stateful transforms
- Use `where` for filtering (not `each {if} | compact`)
- Define data first, then filter
- Include type signatures
- Use `@example` annotations
- Use `const` for static data
- Keep functions focused

### Don't

- Use spread operator `...` with conditionals (use data-first + `where`)
- Wrap external commands in unnecessary parentheses
- Over-extract helpers for one-time use
- Add excessive documentation for internal functions
- Use verbose names for local variables
- Break the pipeline flow unnecessarily
- Add comments for obvious code
