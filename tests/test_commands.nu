use std assert
use std/testing *

# Import all functions from commands.nu (including internals not re-exported via mod.nu)
use ../numd/commands.nu *

# =============================================================================
# Tests for parse-markdown-to-blocks
# =============================================================================

@test
def "parse-markdown-to-blocks detects nushell block" [] {
    let result = "```nushell\necho hello\n```" | parse-markdown-to-blocks

    assert equal ($result | length) 1
    assert equal $result.0.row_type "```nushell"
    assert equal $result.0.action "execute"
}

@test
def "parse-markdown-to-blocks detects nu block" [] {
    let result = "```nu\nls\n```" | parse-markdown-to-blocks

    assert equal ($result | length) 1
    assert equal $result.0.row_type "```nu"
    assert equal $result.0.action "execute"
}

@test
def "parse-markdown-to-blocks handles no-run option" [] {
    let result = "```nushell no-run\necho hello\n```" | parse-markdown-to-blocks

    assert equal $result.0.action "print-as-it-is"
}

@test
def "parse-markdown-to-blocks handles text blocks" [] {
    let result = "Some text\nMore text" | parse-markdown-to-blocks

    assert equal ($result | length) 1
    assert equal $result.0.row_type "text"
    assert equal $result.0.action "print-as-it-is"
}

@test
def "parse-markdown-to-blocks handles mixed content" [] {
    let md = "# Header

```nushell
ls
```

Some text

```nu no-run
echo skip
```"

    let result = $md | parse-markdown-to-blocks

    assert equal ($result | length) 4
    assert equal ($result | where action == "execute" | length) 1
    assert equal ($result | where action == "print-as-it-is" | length) 3
}

# =============================================================================
# Tests for classify-block-action
# =============================================================================

@test
def "classify-block-action returns execute for nushell" [] {
    assert equal (classify-block-action "```nushell") "execute"
}

@test
def "classify-block-action returns execute for nu" [] {
    assert equal (classify-block-action "```nu") "execute"
}

@test
def "classify-block-action returns print-as-it-is for no-run" [] {
    assert equal (classify-block-action "```nushell no-run") "print-as-it-is"
}

@test
def "classify-block-action returns delete for output-numd" [] {
    assert equal (classify-block-action "```output-numd") "delete"
}

@test
def "classify-block-action returns print-as-it-is for text" [] {
    assert equal (classify-block-action "text") "print-as-it-is"
}

@test
def "classify-block-action returns print-as-it-is for other languages" [] {
    assert equal (classify-block-action "```python") "print-as-it-is"
    assert equal (classify-block-action "```rust") "print-as-it-is"
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
# Tests for code-block-marker
# =============================================================================

@test
def "code-block-marker generates open marker" [] {
    assert equal (code-block-marker 5) "#code-block-marker-open-5"
}

@test
def "code-block-marker generates close marker" [] {
    assert equal (code-block-marker 3 --end) "#code-block-marker-close-3"
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
# Tests for convert-output-fences
# =============================================================================

@test
def "convert-output-fences converts output format" [] {
    let input = "```nu\n123\n```\n\nOutput:\n\n```\n456\n```"
    let result = $input | convert-output-fences

    assert ($result =~ "output-numd")
    assert ($result !~ "Output:")
}

@test
def "convert-output-fences restores expanded format" [] {
    let input = "```nu\n123\n```\n```output-numd\n456\n```"
    let result = $input | convert-output-fences --restore

    assert ($result =~ "Output:")
    assert ($result !~ "output-numd")
}

# =============================================================================
# Tests for quote-for-print
# =============================================================================

@test
def "quote-for-print escapes quotes" [] {
    let result = 'hello "world"' | quote-for-print

    assert equal $result '"hello \"world\""'
}

@test
def "quote-for-print escapes backslashes" [] {
    let result = 'path\to\file' | quote-for-print

    assert equal $result '"path\\to\\file"'
}

# =============================================================================
# Tests for can-append-print
# =============================================================================

@test
def "can-append-print returns true for simple commands" [] {
    assert equal (can-append-print "ls") true
    assert equal (can-append-print "echo hello") true
}

@test
def "can-append-print returns false for let statements" [] {
    assert equal (can-append-print "let a = 1") false
    assert equal (can-append-print "let a = ls") false
}

@test
def "can-append-print returns false for mut statements" [] {
    assert equal (can-append-print "mut a = 1") false
}

@test
def "can-append-print returns false for def statements" [] {
    assert equal (can-append-print "def foo [] {}") false
}

@test
def "can-append-print returns false for semicolon ending" [] {
    assert equal (can-append-print "ls;") false
}

@test
def "can-append-print returns false for print ending" [] {
    assert equal (can-append-print "ls | print") false
}

@test
def "can-append-print returns false for source statements" [] {
    assert equal (can-append-print "source a.nu") false
    assert equal (can-append-print "overlay use foo") false
    assert equal (can-append-print "alias ll = ls -la") false
}

@test
def "can-append-print handles multi-statement commands" [] {
    # Last span is echo - should be true
    assert equal (can-append-print "source a.nu; echo abc") true
    # Last span is source - should be false
    assert equal (can-append-print "echo abc; source a.nu") false
    # Multi-line: last is echo
    assert equal (can-append-print "source a.nu\necho hello") true
    # Last span is use - should be false
    assert equal (can-append-print "ls; use std") false
}

# =============================================================================
# Tests for get-last-span
# =============================================================================

@test
def "get-last-span returns whole command for simple commands" [] {
    assert equal (get-last-span "ls") "ls"
    assert equal (get-last-span "echo hello") "echo hello"
}

@test
def "get-last-span returns last statement after semicolon" [] {
    assert equal (get-last-span "source a.nu; echo abc") "echo abc"
    assert equal (get-last-span "echo abc; source a.nu") "source a.nu"
}

@test
def "get-last-span handles multi-line commands" [] {
    assert equal (get-last-span "source a.nu\necho hello") "echo hello"
}

# =============================================================================
# Tests for build-modified-path
# =============================================================================

@test
def "build-modified-path adds prefix" [] {
    let result = "file.nu" | build-modified-path --prefix "test_"

    assert equal $result "test_file.nu"
}

@test
def "build-modified-path adds suffix" [] {
    let result = "file.nu" | build-modified-path --suffix "_backup"

    assert equal $result "file_backup.nu"
}

@test
def "build-modified-path changes extension" [] {
    let result = "file.nu" | build-modified-path --extension ".md"

    assert equal $result "file.nu.md"
}

@test
def "build-modified-path combines all options" [] {
    let result = "file.nu" | build-modified-path --prefix "pre_" --suffix "_suf" --extension ".md"

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
