---
status: todo
created: 20260702-161750
session: 57fe0a5e-bcf9-4490-b540-3da28693b5a5
priority: high
---
# Reliability and code-reduction analysis of numd

Full read of `numd/` (module, toolkit, tests, examples) on nu 0.113.1. Items 1–3 were reproduced live, not just read from code. Parser consolidation (`md-parser.nu` vs `commands.nu`) is already covered by `20260111-refactor-md-parsing.md` — not repeated here; this analysis reinforces its priority.

## A. Verified bugs (reproduced)

### 1. `--no-fail-on-error` silently deletes previous outputs (data loss)

Repro: a file with one `separate-block` block that has saved output, plus one block that errors. `numd run file.md --no-fail-on-error` returns the original blocks table (`commands.nu:102`), then `to-markdown` drops all `action == 'delete'` blocks — the old `Output:` sections are gone, and the file is saved. The flag doc says "markdown is never saved on error" — the opposite happens. Inline `# =>` outputs survive (they live inside the execute block's lines), which makes the loss asymmetric and easy to miss.

Fix at source: `execute-blocks` must distinguish "script failed" from "script printed nothing". On failure, `run` should abort without saving. The `return $original` branch is the wrong contract — remove it rather than guard around it.

### 2. Child stderr is never captured; on failure the user sees an empty error

`execute-intermediate-script` (`commands.nu:491-493`) pipes the external through `| if $print_block_results {...} else { } | complete`. The `if` stage between the external command and `complete` breaks stream capture: stderr leaks straight to the terminal and `complete` gets no `stderr` column. So on failure `error make` raises with `msg: ''` — reproduced: the user sees a blank `x ` error. The `default '' # to refactor later` on line 500 is masking exactly this.

Fix: call `complete` directly on the external command, then branch on the captured record (print stdout when `--print-block-results`). This deletes the "refactor later" hack instead of patching it.

### 3. Temp intermediate script leaks on failure

`run` removes the temp script (`commands.nu:27`) only after `execute-blocks` returns. When execution throws, `<file>-numd-temp-<ts>.nu` stays next to the user's document. Reproduced. Wrap execution in `try`, remove the file in both paths, rethrow.

## B. Bugs found by reading (not run)

### 4. `check-git-clean` checks the wrong repo

`commands.nu:688-696` runs `git rev-parse` / `git ls-files` in the *current* directory. Running `numd run ~/other-repo/doc.md` from elsewhere makes the file look untracked, so the only safety check before overwrite is skipped silently. Fix: `git -C ($file | path expand | path dirname) ...` for all three calls.

### 5. `clear-outputs --strip-markdown` without `--echo` destroys the document

`commands.nu:66-68` saves whatever was produced back to `$file` — with `--strip-markdown` that overwrites the `.md` with the extracted `.nu` script. The "no git check needed, clearing is reversible" comment above the command is false for this flag combination. Fix: with `--strip-markdown`, either require `--echo` or save to the sibling `.nu` path.

### 6. `capture start`/`stop` are not re-entrant

Double `capture start` overwrites `$env.backup.hooks.display_output` with numd's own hook, so `stop` restores the capture hook and capture never ends. `capture stop` without a prior start dies on a missing env key with a confusing message. `$env.numd.status` is written (`'running'`/`'stopped'`) but never read anywhere — it is the guard, unused. Use it in both commands; that also justifies its existence (see D).

## C. Logic and consistency

### 7. Three mechanisms decide fence options — should be one

- `classify-block-action` (`commands.nu:212`) matches `no-run` as a regex *substring* of the whole infostring;
- `extract-fence-options` (`commands.nu:653`) properly parses the comma list and expands short forms;
- the `run-once` rewrite (`commands.nu:259`) is a plain `str replace` on the fence line.

Substring matching misfires on any fence that merely contains the text. Parse options once per block, derive action and rewrites from the parsed list.

### 8. Unknown fence option: warn-and-continue on stdout

`convert-short-options` (`commands.nu:444`) prints a red message and proceeds. A typo in a fence option is a user error in the source document — fail-fast with `error make` naming the block, or at minimum print to stderr (`print -e`) so outer redirections stay clean.

### 9. Regex-over-AST hacks: one structured replacement exists

`get-last-span` (`commands.nu:548-553`) does `ast --json | get block | from json | to yaml | parse -r 'span:...'` — regex over YAML to recover spans; its own comment calls it brute force. `trim-trailing-comments` (`commands.nu:533`) strips `\s+#.*$` and its comment admits it can cut code containing `#` inside strings. Verified on 0.113: `ast $code --flatten` returns a clean `content/shape/span` table. It can replace both: last-span detection and real-comment detection, with less code and no regex fragility.

### 10. CRLF normalization only on Windows

`parse-file` (`commands.nu:130`) strips `\r` only when the *host* is Windows. A CRLF file processed on Linux keeps `\r` in every line. Drop the OS check and always normalize — one branch less, strictly more robust.

### 11. `$env.numd.prepend-code` as a hidden channel

`load-config` exists only to pass `--eval` into `generate-intermediate-script` via the environment (`commands.nu:707-717`, read at `:268`). A plain parameter removes `load-config` (12 lines) and the hidden coupling. Keep the env route only if "set once per session" is a wanted feature — today it is undocumented.

### 12. Unclosed-fence check covers only ```nu fences

`parse-markdown-to-blocks:190` errors on an unclosed nushell fence, but an unclosed ` ```output-numd ` or any other fence passes silently and mis-groups the rest of the file. Check for any open fence at EOF.

### 13. The `# => ` contract lives in four places

Producer `generate-inline-output-pipeline` (`commands.nu:592`), strippers `'^# => ?'` (`:141`) vs `'^# =>'` (`:286`) — note the two regexes already disagree about the trailing space — plus independent copies in `capture.nu:44` and `parse-help.nu:65`. One shared const + prefix/strip helpers keeps the format from drifting.

### 14. capture hook filters on output text, not the command

`capture.nu:48` skips saving when the rendered block contains the string `numd capture` — so any user output containing that phrase is silently dropped from the recording. Test `$command` instead. Also the default `table`/`table -e` closure is duplicated twice in the file (`:24-26`, `:35`).

## D. Dead code — delete (~155 lines, ~245 with cprint)

| What | Where | Evidence |
|---|---|---|
| `merge-markdown` | `commands.nu:340-351` | no callers; `execute-blocks` inlined this merge. `CLAUDE.md:75` still documents it — update the doc |
| `nu-utils/parse.nu` | whole file (10 lines) | never imported anywhere |
| `live.nu` | whole file (131 lines) | not exported in `mod.nu`, no callers, marked draft in `todo/20260110-233256-parsing.md`. Its `--indent-output` generates a fence option numd does not recognize. Half-connected is the worst state: delete until the design settles (git keeps it), or wire it in and align its options with `fence_options` |
| `alias core_to_md` | `parse.nu:20` | unused |
| `$env.numd.status` writes | `capture.nu:16,71` | write-only — either becomes the re-entry guard (item 6) or goes |

`parse.nu` removal itself is already planned in `20260111-refactor-md-parsing.md`.

## E. Further reduction

- `md-parser.nu` `extract-content` (`:64-83`): 4 of 6 match arms are the identical `str join` — collapse to h/blockquote special cases plus a default (~10 lines).
- `cprint.nu` (85) + `str repeat.nu` (6) exist for two static messages in `capture.nu`. Two plain `print $"..."` calls drop the entire `nu-utils/` directory (combined with the dead `nu-utils/parse.nu`).
- `parse-help.nu:7` workaround for nushell#13470: verified `help` on 0.113 no longer emits `======` separators. Harmless but removable once the supported nu range is ≥ the fix.
- `live.nu` h1–h6 are six 5-line wrappers over `h` — only relevant if the file survives (D).

## F. Terminal-UX polish

- `--echo` always emits ANSI; every pipe in README/toolkit adds a manual `| ansi strip`. `if (is-terminal --stdout) { } else { ansi strip }` inside the echo branch matches what a terminal user expects from any well-behaved CLI.
- Diagnostics (item 8 warning, `cprint` notices) belong on stderr, keeping stdout clean for the document.
- `toolkit.nu:186` `run-integration-test` catches errors and discards the message — a failed test prints only `✗ name`. Put `$err.msg` into the result record so failures are debuggable without re-running by hand.
- `run` on a file with no code blocks returns a `{filename, comment}` record (`commands.nu:31-35`) — a third return shape besides stats-record and echo-string. A stderr note plus `null` is more predictable in scripts. Minor.

## Suggested order

1. A1–A3 as one "execution error path" change: capture streams correctly, fail fast, clean up temp, never save on failure — they are the same few lines in `execute-intermediate-script`/`execute-blocks`/`run`.
2. B4, B5 — small isolated safety fixes.
3. D — pure deletion, zero risk, immediate size win.
4. C7+C8 (single fence-option mechanism), then C9 (`ast --flatten`).
5. B6+C14 (capture hardening), C10–C13, E, F as small independent commits.
