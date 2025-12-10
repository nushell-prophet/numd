# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

numd is a Nushell module for creating reproducible Markdown documents. It executes Nushell code blocks within markdown files and writes results back to the document.

## Common Commands

```bash
# Install the module via nupm
nupm install --force --path .

# Run numd on a markdown file (updates file with execution results)
use numd; numd run README.md

# Run without saving changes (preview mode)
use numd; numd run README.md --no-save --echo

# Run tests (executes all example files and reports changes)
nu toolkit.nu testing

# Clear outputs from a markdown file
use numd; numd clear-outputs path/to/file.md

# Strip markdown to get pure Nushell script
use numd; numd clear-outputs path/to/file.md --strip-markdown --echo
```

## Architecture

### Module Structure (`numd/`)

- **mod.nu**: Entry point exporting public commands (`run`, `clear-outputs`, `list-code-options`, `capture start/stop`, `parse-help`, `parse-frontmatter`, `to md-with-frontmatter`)
- **commands.nu**: Core implementation (~840 lines) containing all main logic
- **parse.nu**: Frontmatter parsing utilities for YAML frontmatter in markdown

### Core Processing Pipeline (in `commands.nu`)

1. **`find-code-blocks`**: Parses markdown into a table classifying each block by type (`text`, ` ```nushell `, ` ```output-numd `) and action (`execute`, `print-as-it-is`, `delete`)

2. **`decortate-original-code-blocks`** + **`generate-intermediate-script`**: Transforms executable code blocks into a temporary `.nu` script with markers for output capture

3. **`execute-intermediate-script`**: Runs the generated script in a new Nushell instance, capturing stdout

4. **`extract-block-index`** + **`merge-markdown`**: Parses execution results using `#code-block-marker-open-N` markers and merges them back into the original markdown structure

### Code Block Options

Blocks support options in the infostring (e.g., ` ```nushell try, no-output `):
- `no-run` / `N`: Skip execution
- `no-output` / `O`: Execute but hide output
- `try` / `t`: Wrap in try-catch
- `new-instance` / `n`: Execute in separate Nushell instance

### Output Format Conventions

- Lines starting with `>` are treated as REPL-style commands (executed line-by-line)
- Lines starting with `# =>` contain output from previous command
- Blocks without `>` are executed as a single script unit

## Testing

The `toolkit.nu testing` command:
1. Runs all example files in `z_examples/` through numd
2. Generates stripped `.nu` versions in `z_examples/99_strip_markdown/`
3. Reports Levenshtein distance and diff stats to detect changes

Example files serve as integration tests - use both the Levenshtein stats and `git diff` to verify changes.

```bash
# Run tests with JSON output (for external tools/CI)
nu toolkit.nu testing --json

# Check actual file changes after testing
git diff
```

### Expected Non-Zero Diffs

Some files legitimately differ on each run due to:
- **Dynamic content**: `sys host | get boot_time` in README.md, timezone examples in `working_with_lists.md`
- **Nushell version changes**: Error message formatting, table truncation characters (`...` vs `…`)

A zero `levenshtein_dist` for most files + expected diffs in time-dependent files = passing tests.

## Configuration

numd supports YAML config files (see `numd_config_example1.yaml`):
```yaml
prepend-code: |-
  $env.config.table.mode = 'rounded'
```

Pass via `--config-path` or use `--prepend-code` / `--table-width` flags directly.
