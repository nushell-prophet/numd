# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

numd is a Nushell module for creating reproducible Markdown documents. It executes Nushell code blocks within markdown files and writes results back to the document.

## Common Commands

```nushell
# Run numd on a markdown file (updates file with execution results)
use numd; numd run README.md

# Preview mode (output to stdout, don't save)
use numd; numd run README.md --echo

# Run tests (executes all example files and reports changes)
nu toolkit.nu test --json

# Clear outputs from a markdown file
use numd; numd clear-outputs path/to/file.md

# Strip markdown to get pure Nushell script
use numd; numd clear-outputs path/to/file.md --strip-markdown --echo
```

## Architecture

### Module Structure (`numd/`)

- **mod.nu**: Entry point exporting user-friendly commands (`run`, `clear-outputs`, etc.)
- **plumbing.nu**: Low-level pipeline commands for advanced usage/scripting
- **commands.nu**: Core implementation containing all command logic
- **capture.nu**: `capture start/stop` commands for interactive session recording
- **parse-help.nu**: `parse-help` command for formatting --help output
- **parse.nu**: Frontmatter parsing utilities (`parse-frontmatter`, `to md-with-frontmatter`)
- **nu-utils/**: Helper utilities (`cprint.nu`, `str repeat.nu`)

### Plumbing Commands

Low-level composable commands (import via `use numd/plumbing.nu`):

```nushell
use numd/plumbing.nu

# Parse markdown file into blocks table
plumbing parse-file file.md

# Strip output lines (# =>) from blocks
plumbing parse-file file.md | plumbing strip-outputs

# Execute code blocks and update with results
plumbing parse-file file.md | plumbing execute-blocks --save-intermed-script temp.nu

# Render blocks table back to markdown
plumbing parse-file file.md | plumbing strip-outputs | plumbing to-markdown

# Extract pure Nushell script (no markdown)
plumbing parse-file file.md | plumbing strip-outputs | plumbing to-numd-script
```

The high-level commands use these internally:
- `run` = `parse-file | execute-blocks | to-markdown`
- `clear-outputs` = `parse-file | strip-outputs | to-markdown`

### Core Processing Pipeline (in `commands.nu`)

1. **`parse-markdown-to-blocks`**: Parses markdown into a table classifying each block by type (`text`, ` ```nushell `, ` ```output-numd `) and action (`execute`, `print-as-it-is`, `delete`)

2. **`decorate-original-code-blocks`** + **`generate-intermediate-script`**: Transforms executable code blocks into a temporary `.nu` script with markers for output capture

3. **`execute-intermediate-script`**: Runs the generated script in a new Nushell instance, capturing stdout

4. **`extract-block-index`** + **`merge-markdown`**: Parses execution results using `#code-block-marker-open-N` markers and merges them back into the original markdown structure

### Fence Options

Blocks support fence options (e.g., ` ```nushell try, no-output `):
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
nu toolkit.nu test

# Run only unit tests (nutest-based, tests internal functions)
nu toolkit.nu test-unit

# Run only integration tests (executes example markdown files)
nu toolkit.nu test-integration

# All commands support --json for CI
nu toolkit.nu test --json
```

### Unit Tests (`tests/`)

Unit tests use [nutest](https://github.com/vyadh/nutest) framework. Tests import internal functions via `use ../numd/commands.nu *` to test parsing and transformation logic directly.

### Integration Tests (`z_examples/`)

The `test-integration` command:
1. Runs all example files in `z_examples/` through numd
2. Generates stripped `.nu` versions in `z_examples/99_strip_markdown/`
3. Runs `numd run README.md` to update README with latest outputs
4. Reports Levenshtein distance and diff stats to detect changes

Example files serve as integration tests - use both the Levenshtein stats and `git diff` to verify changes.

### Expected Non-Zero Diffs

Some files legitimately differ on each run due to:
- **Dynamic content**: `git tag` output in README.md (version changes over time)
- **Nushell version changes**: Error message formatting, table rendering differences

A zero `levenshtein_dist` for most files + expected diffs in dynamic content files = passing tests.

## Configuration

numd supports `.nu` config files (see `numd_config_example1.nu`). The config file is a Nushell script that gets prepended to the intermediate script:
```nushell
# numd_config_example1.nu
$env.config.table.mode = 'rounded'
$env.numd.table-width = 100  # optional: set custom table width
```

Pass via `--config-path` or use `--prepend-code` / `--table-width` flags directly. Flags override config file settings.

## Git Workflow

- Do not squash commits when merging PRs - preserve individual commit history
