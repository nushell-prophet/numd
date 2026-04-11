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
def "classify-block-action returns execute for run-once" [] {
    assert equal (classify-block-action "```nushell run-once") "execute"
}

@test
def "classify-block-action returns execute for run-once combined with try" [] {
    assert equal (classify-block-action "```nushell run-once, try") "execute"
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
def "extract-fence-options parses run-once" [] {
    let result = "```nu run-once" | extract-fence-options

    assert equal $result ["run-once"]
}

@test
def "extract-fence-options parses run-once combined with try" [] {
    let result = "```nu run-once, try" | extract-fence-options

    assert equal ($result | length) 2
    assert ("run-once" in $result)
    assert ("try" in $result)
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

# =============================================================================
# Tests for decorate-original-code-blocks (run-once rewriting)
# =============================================================================

@test
def "decorate-original-code-blocks rewrites run-once to no-run" [] {
    let blocks = "```nu run-once\necho hello\n```" | parse-markdown-to-blocks
    let result = decorate-original-code-blocks $blocks

    assert ($result.0.code =~ '```nu no-run')
    assert ($result.0.code !~ 'run-once')
}

@test
def "decorate-original-code-blocks rewrites run-once preserving other options" [] {
    let blocks = "```nu run-once, try\necho hello\n```" | parse-markdown-to-blocks
    let result = decorate-original-code-blocks $blocks

    assert ($result.0.code =~ '```nu no-run, try')
    assert ($result.0.code !~ 'run-once')
}

@test
def "decorate-original-code-blocks leaves plain blocks unchanged" [] {
    let blocks = "```nu\necho hello\n```" | parse-markdown-to-blocks
    let result = decorate-original-code-blocks $blocks

    assert ($result.0.code =~ '```nu')
    assert ($result.0.code !~ 'no-run')
}

# =============================================================================
# Tests for strip-outputs
# =============================================================================

@test
def "strip-outputs removes output lines from blocks" [] {
    let blocks = "```nu\necho hello\n# => hello\n```" | parse-markdown-to-blocks

    let result = $blocks | strip-outputs

    # The line list should not contain '# => hello'
    let code_block = $result | where action == "execute" | first
    assert (($code_block.line | str join "\n") !~ '# =>')
}

@test
def "strip-outputs preserves plain comments" [] {
    let blocks = "```nu\n# this is a comment\necho hello\n# => hello\n```" | parse-markdown-to-blocks

    let result = $blocks | strip-outputs

    let code_block = $result | where action == "execute" | first
    let code = $code_block.line | str join "\n"
    # Plain comment should be preserved
    assert ($code =~ '# this is a comment')
    # Output line should be removed
    assert ($code !~ '# => hello')
}

@test
def "strip-outputs handles multiple output lines" [] {
    let blocks = "```nu\nls\n# => file1\n# => file2\n# => file3\n```" | parse-markdown-to-blocks

    let result = $blocks | strip-outputs

    let code_block = $result | where action == "execute" | first
    let code = $code_block.line | str join "\n"
    assert ($code !~ '# =>')
    assert ($code =~ 'ls')
}

@test
def "strip-outputs preserves text blocks unchanged" [] {
    let blocks = "# Header\n\nSome text" | parse-markdown-to-blocks

    let result = $blocks | strip-outputs

    assert equal ($result | length) 1
    assert equal $result.0.action "print-as-it-is"
}

# =============================================================================
# Tests for to-markdown
# =============================================================================

@test
def "to-markdown renders text blocks" [] {
    let blocks = "# Header\n\nSome text" | parse-markdown-to-blocks

    let result = $blocks | to-markdown

    assert ($result =~ '# Header')
    assert ($result =~ 'Some text')
}

@test
def "to-markdown renders code blocks with fences" [] {
    let blocks = "```nu\necho hello\n```" | parse-markdown-to-blocks

    let result = $blocks | to-markdown

    assert ($result =~ '```nu')
    assert ($result =~ 'echo hello')
    assert ($result =~ '```')
}

@test
def "to-markdown skips delete blocks" [] {
    let blocks = "```nu\necho hello\n```\n```output-numd\nold output\n```" | parse-markdown-to-blocks

    let result = $blocks | to-markdown

    # output-numd block should be deleted
    assert ($result !~ 'output-numd')
    assert ($result !~ 'old output')
}

@test
def "to-markdown preserves block order" [] {
    let md = "# Title\n\n```nu\nls\n```\n\nMiddle text\n\n```nu\necho hi\n```"
    let blocks = $md | parse-markdown-to-blocks

    let result = $blocks | to-markdown

    # Check order is preserved
    let title_pos = $result | str index-of '# Title'
    let ls_pos = $result | str index-of 'ls'
    let middle_pos = $result | str index-of 'Middle text'
    let echo_pos = $result | str index-of 'echo hi'

    assert ($title_pos < $ls_pos)
    assert ($ls_pos < $middle_pos)
    assert ($middle_pos < $echo_pos)
}

# =============================================================================
# Tests for to-numd-script
# =============================================================================

@test
def "to-numd-script extracts code from blocks" [] {
    let blocks = "```nu\necho hello\n```" | parse-markdown-to-blocks

    let result = $blocks | to-numd-script

    assert ($result =~ 'echo hello')
}

@test
def "to-numd-script removes markdown fences" [] {
    let blocks = "```nu\necho hello\n```" | parse-markdown-to-blocks

    let result = $blocks | to-numd-script

    # Should not contain raw fence markers
    assert ($result !~ '^```')
}

@test
def "to-numd-script includes infostring as comment" [] {
    let blocks = "```nu separate-block\necho hello\n```" | parse-markdown-to-blocks

    let result = $blocks | to-numd-script

    # Infostring should be preserved as comment
    assert ($result =~ '# ```nu separate-block')
}

@test
def "to-numd-script only includes executable blocks" [] {
    let blocks = "# Header\n\n```nu\necho hello\n```\n\n```python\nprint('hi')\n```" | parse-markdown-to-blocks

    let result = $blocks | to-numd-script

    assert ($result =~ 'echo hello')
    assert ($result !~ 'Header')
    assert ($result !~ 'print')
}

@test
def "to-numd-script handles multiple code blocks" [] {
    let blocks = "```nu\nlet a = 1\n```\n\n```nu\necho $a\n```" | parse-markdown-to-blocks

    let result = $blocks | to-numd-script

    assert ($result =~ 'let a = 1')
    assert ($result =~ 'echo \$a')
}

# =============================================================================
# Tests for image fence option
# =============================================================================

@test
def "convert-short-options expands i to image" [] {
    assert equal (convert-short-options "i") "image"
}

@test
def "extract-fence-options recognizes image long form" [] {
    let result = "```nu image" | extract-fence-options

    assert equal $result ["image"]
}

@test
def "extract-fence-options recognizes i short form" [] {
    let result = "```nu i" | extract-fence-options

    assert equal $result ["image"]
}

@test
def "extract-fence-options parses image combined with try" [] {
    let result = "```nu image, try" | extract-fence-options

    assert equal ($result | length) 2
    assert ("image" in $result)
    assert ("try" in $result)
}

@test
def "list-fence-options includes image row" [] {
    let rows = list-fence-options | where long == 'image'

    assert equal ($rows | length) 1
    assert equal $rows.0.short 'i'
}

# =============================================================================
# Tests for generate-image-output-pipeline
# =============================================================================

@test
def "generate-image-output-pipeline produces expected pipeline" [] {
    let result = 'ls' | generate-image-output-pipeline '/tmp/out.png'

    # `table -e` for expanded rendering, path embedded in single quotes,
    # `| ignore` to drop the returned path string from captured stdout.
    assert equal $result "ls | table -e --width ($env.numd?.table-width? | default 120) | to png '/tmp/out.png' | ignore"
}

@test
def "generate-image-output-pipeline uses table -e not plain table" [] {
    let result = 'something' | generate-image-output-pipeline '/a/b.png'

    # Why: `table -e` expands nested structures before rasterization so
    # the rendered PNG matches what a user would see in an interactive
    # terminal, not the truncated default representation.
    assert ($result =~ 'table -e')
}

@test
def "generate-image-output-pipeline ends with ignore" [] {
    let result = 'ls' | generate-image-output-pipeline '/tmp/x.png'

    # Why: `to png` returns the path string, which would otherwise
    # contaminate captured stdout and appear as a stray line in the
    # rendered markdown.
    assert ($result | str ends-with '| ignore')
}

# =============================================================================
# Tests for image path construction in decorate-original-code-blocks
# =============================================================================

@test
def "decorate-original-code-blocks emits image ref for image block" [] {
    let blocks = "```nu image\n'hello'\n```" | parse-markdown-to-blocks
    let result = decorate-original-code-blocks $blocks --file /tmp/mydoc.md
    let block_index = $result.0.block_index

    # The generated code should contain a print statement with the
    # deterministic filename pattern: <stem>.block-<block>-<group>.png
    assert ($result.0.code =~ $'mydoc\.block-($block_index)-0\.png')
    assert ($result.0.code =~ 'to png')
    assert ($result.0.code =~ 'table -e')
}

@test
def "decorate-original-code-blocks respects no-output over image" [] {
    let blocks = "```nu image, no-output\n'hello'\n```" | parse-markdown-to-blocks
    let result = decorate-original-code-blocks $blocks --file /tmp/mydoc.md

    # Per spec interaction matrix: no-output wins, so no PNG is written
    # and no image ref is emitted.
    assert ($result.0.code !~ 'to png')
    assert ($result.0.code !~ 'mydoc\.block')
}

@test
def "decorate-original-code-blocks uses doc-stem in path" [] {
    let blocks = "```nu image\n'hi'\n```" | parse-markdown-to-blocks
    let result = decorate-original-code-blocks $blocks --file /some/path/guide.v2.md
    let block_index = $result.0.block_index

    # File name without extension becomes the stem; multi-dot names keep
    # everything before the final extension.
    assert ($result.0.code =~ $'guide\.v2\.block-($block_index)-0\.png')
}

@test
def "decorate-original-code-blocks handles multi-group block" [] {
    let blocks = "```nu image\n'first'\n\n'second'\n```" | parse-markdown-to-blocks
    let result = decorate-original-code-blocks $blocks --file /tmp/multi.md
    let block_index = $result.0.block_index

    # Each executable group gets its own PNG with 0-based group_index.
    assert ($result.0.code =~ $'multi\.block-($block_index)-0\.png')
    assert ($result.0.code =~ $'multi\.block-($block_index)-1\.png')
}

@test
def "decorate-original-code-blocks without --file leaves image blocks inert" [] {
    let blocks = "```nu image\n'hello'\n```" | parse-markdown-to-blocks
    let result = decorate-original-code-blocks $blocks

    # Without --file we don't know where to place PNGs, so no image
    # pipeline is injected. The block is otherwise processed normally.
    assert ($result.0.code !~ 'to png')
}

# =============================================================================
# Tests for strip-numd-image-refs
# =============================================================================

@test
def "strip-numd-image-refs removes deterministic ref lines" [] {
    let input = "# Title\n\n```nu image\n'x'\n```\n\n![](media/doc.block-1-0.png)\n\nmore text"
    let result = $input | strip-numd-image-refs

    assert ($result !~ 'block-1-0\.png')
    assert ($result =~ '# Title')
    assert ($result =~ 'more text')
}

@test
def "strip-numd-image-refs preserves hand-written image links" [] {
    let input = "# Docs\n\n![logo](assets/logo.png)\n\n![](photo.jpg)"
    let result = $input | strip-numd-image-refs

    # Hand-written image links don't match `.block-N-N.png` pattern so
    # they are left alone.
    assert ($result =~ 'logo\.png')
    assert ($result =~ 'photo\.jpg')
}

@test
def "strip-numd-image-refs removes multiple refs" [] {
    let input = "```nu image\n'x'\n```\n\n![](media/a.block-3-0.png)\n![](media/a.block-3-1.png)\n![](media/a.block-3-2.png)\n"
    let result = $input | strip-numd-image-refs

    assert ($result !~ 'block-3-')
}

# =============================================================================
# Tests for clear-outputs with image refs
# =============================================================================

@test
def "clear-outputs strips image reference from image-tagged block" [] {
    let tmp_dir = $nu.temp-dir | path join $'numd-image-test-(random chars --length 8)'
    mkdir $tmp_dir
    let md_path = $tmp_dir | path join 'test.md'
    "# Test\n\n```nu image\n'hello'\n```\n\n![](media/test.block-1-0.png)\n" | save -f $md_path

    # Use --echo to avoid git check and to get the string directly.
    let result = clear-outputs $md_path --echo

    assert ($result !~ 'block-1-0\.png')
    assert ($result =~ 'image')
    # The code block itself is preserved, only the ref line is stripped.
    assert ($result =~ "'hello'")

    rm -rf $tmp_dir
}
