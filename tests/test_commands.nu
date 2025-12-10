use std assert
use std/testing *

# Import all functions from commands.nu (including internals not re-exported via mod.nu)
use ../numd/commands.nu *

# =============================================================================
# Tests for find-code-blocks
# =============================================================================

@test
def "find-code-blocks detects nushell block" [] {
    let result = "```nushell\necho hello\n```" | find-code-blocks

    assert equal ($result | length) 1
    assert equal $result.0.row_type "```nushell"
    assert equal $result.0.action "execute"
}

@test
def "find-code-blocks detects nu block" [] {
    let result = "```nu\nls\n```" | find-code-blocks

    assert equal ($result | length) 1
    assert equal $result.0.row_type "```nu"
    assert equal $result.0.action "execute"
}

@test
def "find-code-blocks handles no-run option" [] {
    let result = "```nushell no-run\necho hello\n```" | find-code-blocks

    assert equal $result.0.action "print-as-it-is"
}

@test
def "find-code-blocks handles text blocks" [] {
    let result = "Some text\nMore text" | find-code-blocks

    assert equal ($result | length) 1
    assert equal $result.0.row_type "text"
    assert equal $result.0.action "print-as-it-is"
}

@test
def "find-code-blocks handles mixed content" [] {
    let md = "# Header

```nushell
ls
```

Some text

```nu no-run
echo skip
```"

    let result = $md | find-code-blocks

    assert equal ($result | length) 4
    assert equal ($result | where action == "execute" | length) 1
    assert equal ($result | where action == "print-as-it-is" | length) 3
}

# =============================================================================
# Tests for match-action
# =============================================================================

@test
def "match-action returns execute for nushell" [] {
    assert equal (match-action "```nushell") "execute"
}

@test
def "match-action returns execute for nu" [] {
    assert equal (match-action "```nu") "execute"
}

@test
def "match-action returns print-as-it-is for no-run" [] {
    assert equal (match-action "```nushell no-run") "print-as-it-is"
}

@test
def "match-action returns delete for output-numd" [] {
    assert equal (match-action "```output-numd") "delete"
}

@test
def "match-action returns print-as-it-is for text" [] {
    assert equal (match-action "text") "print-as-it-is"
}

@test
def "match-action returns print-as-it-is for other languages" [] {
    assert equal (match-action "```python") "print-as-it-is"
    assert equal (match-action "```rust") "print-as-it-is"
}

# =============================================================================
# Tests for extract-fence-options
# =============================================================================

@test
def "extract-fence-options parses single option" [] {
    let result = "```nu no-run" | extract-fence-options

    assert equal $result ["no-run"]
}

@test
def "extract-fence-options parses multiple options" [] {
    let result = "```nushell try, no-output" | extract-fence-options

    assert equal ($result | length) 2
    assert ("try" in $result)
    assert ("no-output" in $result)
}

@test
def "extract-fence-options expands short options" [] {
    let result = "```nu t, O" | extract-fence-options

    assert ("try" in $result)
    assert ("no-output" in $result)
}

@test
def "extract-fence-options handles empty options" [] {
    let result = "```nushell" | extract-fence-options

    assert equal ($result | length) 0
}

# =============================================================================
# Tests for convert-short-options
# =============================================================================

@test
def "convert-short-options expands O" [] {
    assert equal (convert-short-options "O") "no-output"
}

@test
def "convert-short-options expands N" [] {
    assert equal (convert-short-options "N") "no-run"
}

@test
def "convert-short-options expands t" [] {
    assert equal (convert-short-options "t") "try"
}

@test
def "convert-short-options expands n" [] {
    assert equal (convert-short-options "n") "new-instance"
}

@test
def "convert-short-options keeps long options unchanged" [] {
    assert equal (convert-short-options "no-output") "no-output"
    assert equal (convert-short-options "try") "try"
}

# =============================================================================
# Tests for mark-code-block
# =============================================================================

@test
def "mark-code-block generates open marker" [] {
    assert equal (mark-code-block 5) "#code-block-marker-open-5"
}

@test
def "mark-code-block generates close marker" [] {
    assert equal (mark-code-block 3 --end) "#code-block-marker-close-3"
}

# =============================================================================
# Tests for clean-markdown
# =============================================================================

@test
def "clean-markdown removes empty output blocks" [] {
    let input = "text\n```output-numd\n   \n```\nmore"
    let result = $input | clean-markdown

    assert ($result !~ "output-numd")
}

@test
def "clean-markdown collapses multiple newlines" [] {
    let input = "text\n\n\n\nmore"
    let result = $input | clean-markdown

    assert ($result !~ "\n{3,}")
}

@test
def "clean-markdown removes trailing spaces" [] {
    let input = "text   \nmore  \n"
    let result = $input | clean-markdown

    assert ($result !~ " \n")
}

@test
def "clean-markdown ensures single trailing newline" [] {
    let input = "text\n\n\n"
    let result = $input | clean-markdown

    # Result should be "text\n" - single trailing newline
    assert equal $result "text\n"
}

# =============================================================================
# Tests for toggle-output-fences
# =============================================================================

@test
def "toggle-output-fences converts output format" [] {
    let input = "```nu\n123\n```\n\nOutput:\n\n```\n456\n```"
    let result = $input | toggle-output-fences

    assert ($result =~ "output-numd")
    assert ($result !~ "Output:")
}

@test
def "toggle-output-fences converts back" [] {
    let input = "```nu\n123\n```\n```output-numd\n456\n```"
    let result = $input | toggle-output-fences --back

    assert ($result =~ "Output:")
    assert ($result !~ "output-numd")
}

# =============================================================================
# Tests for escape-special-characters-and-quote
# =============================================================================

@test
def "escape-special-characters-and-quote escapes quotes" [] {
    let result = 'hello "world"' | escape-special-characters-and-quote

    assert equal $result '"hello \"world\""'
}

@test
def "escape-special-characters-and-quote escapes backslashes" [] {
    let result = 'path\to\file' | escape-special-characters-and-quote

    assert equal $result '"path\\to\\file"'
}

# =============================================================================
# Tests for check-print-append
# =============================================================================

@test
def "check-print-append returns true for simple commands" [] {
    assert equal (check-print-append "ls") true
    assert equal (check-print-append "echo hello") true
}

@test
def "check-print-append returns false for let statements" [] {
    assert equal (check-print-append "let a = 1") false
    assert equal (check-print-append "let a = ls") false
}

@test
def "check-print-append returns false for mut statements" [] {
    assert equal (check-print-append "mut a = 1") false
}

@test
def "check-print-append returns false for def statements" [] {
    assert equal (check-print-append "def foo [] {}") false
}

@test
def "check-print-append returns false for semicolon ending" [] {
    assert equal (check-print-append "ls;") false
}

@test
def "check-print-append returns false for print ending" [] {
    assert equal (check-print-append "ls | print") false
}

# =============================================================================
# Tests for modify-path
# =============================================================================

@test
def "modify-path adds prefix" [] {
    let result = "file.nu" | modify-path --prefix "test_"

    assert equal $result "test_file.nu"
}

@test
def "modify-path adds suffix" [] {
    let result = "file.nu" | modify-path --suffix "_backup"

    assert equal $result "file_backup.nu"
}

@test
def "modify-path changes extension" [] {
    let result = "file.nu" | modify-path --extension ".md"

    assert equal $result "file.nu.md"
}

@test
def "modify-path combines all options" [] {
    let result = "file.nu" | modify-path --prefix "pre_" --suffix "_suf" --extension ".md"

    assert equal $result "pre_file_suf.nu.md"
}

# =============================================================================
# Tests for generate-timestamp
# =============================================================================

@test
def "generate-timestamp returns correct format" [] {
    let result = generate-timestamp

    # Format should be YYYYMMDD_HHMMSS (15 chars)
    assert equal ($result | str length) 15
    assert ($result =~ '^\d{8}_\d{6}$')
}
