# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

numd is a Nushell module for creating reproducible Markdown documents. It executes Nushell code blocks within markdown files and writes results back to the document.

## Common Commands

```nushell
# Run numd on a markdown file (updates file with execution results)
use numd; numd run README.md

# Run without saving changes (preview mode)
use numd; numd run README.md --no-save --echo

# Run tests (executes all example files and reports changes)
nu toolkit.nu testing --json

# Clear outputs from a markdown file
use numd; numd clear-outputs path/to/file.md

# Strip markdown to get pure Nushell script
use numd; numd clear-outputs path/to/file.md --strip-markdown --echo
```

## Architecture

### Module Structure (`numd/`)

- **mod.nu**: Entry point exporting public commands (`run`, `clear-outputs`, `list-code-options`, `capture start/stop`, `parse-help`, `parse-frontmatter`, `to md-with-frontmatter`)
- **commands.nu**: Core implementation (~865 lines) containing all main logic
- **nu-utils/**: Helper utilities (`cprint.nu`, `str repeat.nu`)
- **parse.nu**: Frontmatter parsing utilities for YAML frontmatter in markdown

### Core Processing Pipeline (in `commands.nu`)

1. **`find-code-blocks`**: Parses markdown into a table classifying each block by type (`text`, ` ```nushell `, ` ```output-numd `) and action (`execute`, `print-as-it-is`, `delete`)

2. **`decorate-original-code-blocks`** + **`generate-intermediate-script`**: Transforms executable code blocks into a temporary `.nu` script with markers for output capture

3. **`execute-intermediate-script`**: Runs the generated script in a new Nushell instance, capturing stdout

4. **`extract-block-index`** + **`merge-markdown`**: Parses execution results using `#code-block-marker-open-N` markers and merges them back into the original markdown structure

### Code Block Options

Blocks support options in the infostring (e.g., ` ```nushell try, no-output `):
- `no-run` / `N`: Skip execution
- `no-output` / `O`: Execute but hide output
- `try` / `t`: Wrap in try-catch
- `new-instance` / `n`: Execute in separate Nushell instance
- `separate-block` / `s`: Output results in separate code block instead of inline `# =>`

### Output Format Conventions

- Code blocks are split by blank lines (double newlines) into command groups
- Each command group is executed separately via `split-by-blank-lines`
- Lines starting with `# =>` contain output from previous command group
- Plain `#` comments are preserved; `# =>` output lines are regenerated on each run
- Use `separate-block` fence option to output results in a separate code block instead of inline `# =>`

## Testing

```nushell
# Run all tests (unit + integration)
nu toolkit.nu testing

# Run only unit tests (nutest-based, tests internal functions)
nu toolkit.nu testing-unit

# Run only integration tests (executes example markdown files)
nu toolkit.nu testing-integration

# All commands support --json for CI
nu toolkit.nu testing --json
```

### Unit Tests (`tests/`)

Unit tests use [nutest](https://github.com/vyadh/nutest) framework. Tests import internal functions via `use ../numd/commands.nu *` to test parsing and transformation logic directly.

### Integration Tests (`z_examples/`)

The `testing-integration` command:
1. Runs all example files in `z_examples/` through numd
2. Generates stripped `.nu` versions in `z_examples/99_strip_markdown/`
3. Reports Levenshtein distance and diff stats to detect changes

Example files serve as integration tests - use both the Levenshtein stats and `git diff` to verify changes.

### Expected Non-Zero Diffs

Some files legitimately differ on each run due to:
- **Dynamic content**: `git tag` output in README.md (version changes over time)
- **Nushell version changes**: Error message formatting, table rendering differences

A zero `levenshtein_dist` for most files + expected diffs in dynamic content files = passing tests.

## Configuration

numd supports YAML config files (see `numd_config_example1.yaml`):
```yaml
prepend-code: |-
  $env.config.table.mode = 'rounded'
```

Pass via `--config-path` or use `--prepend-code` / `--table-width` flags directly.
