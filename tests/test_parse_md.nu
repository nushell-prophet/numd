use std assert
use std/testing *

# Import all functions from parse-md.nu (including internals)
use ../numd/parse-md.nu *

# =============================================================================
# Tests for classify-line
# =============================================================================

@test
def "classify-line detects h1" [] {
    let result = "# Hello" | classify-line
    assert equal $result.type "h1"
}

@test
def "classify-line detects h2" [] {
    let result = "## Section" | classify-line
    assert equal $result.type "h2"
}

@test
def "classify-line detects h6" [] {
    let result = "###### Deep header" | classify-line
    assert equal $result.type "h6"
}

@test
def "classify-line detects code fence with language" [] {
    let result = "```nushell" | classify-line
    assert equal $result.type "fence"
    assert equal $result.lang "nushell"
}

@test
def "classify-line detects code fence with options" [] {
    let result = "```nushell no-run, try" | classify-line
    assert equal $result.type "fence"
    assert equal $result.lang "nushell"
    assert ("no-run" in $result.options)
    assert ("try" in $result.options)
}

@test
def "classify-line detects closing fence" [] {
    let result = "```" | classify-line
    assert equal $result.type "fence"
    assert equal $result.lang ""
}

@test
def "classify-line detects unordered list with dash" [] {
    let result = "- item" | classify-line
    assert equal $result.type "ul-item"
}

@test
def "classify-line detects unordered list with asterisk" [] {
    let result = "* item" | classify-line
    assert equal $result.type "ul-item"
}

@test
def "classify-line detects ordered list" [] {
    let result = "1. first" | classify-line
    assert equal $result.type "ol-item"
}

@test
def "classify-line detects blockquote" [] {
    let result = "> quote" | classify-line
    assert equal $result.type "blockquote"
}

@test
def "classify-line detects empty line" [] {
    let result = "" | classify-line
    assert equal $result.type "empty"
}

@test
def "classify-line detects whitespace-only as empty" [] {
    let result = "   " | classify-line
    assert equal $result.type "empty"
}

@test
def "classify-line detects text" [] {
    let result = "Some paragraph text" | classify-line
    assert equal $result.type "text"
}

# =============================================================================
# Tests for parse-md
# =============================================================================

@test
def "parse-md parses h1 header" [] {
    let result = "# Title" | parse-md
    assert equal ($result | length) 1
    assert equal $result.0.element "h1"
    assert equal $result.0.content "Title"
}

@test
def "parse-md parses h3 header" [] {
    let result = "### Section" | parse-md
    assert equal ($result | length) 1
    assert equal $result.0.element "h3"
    assert equal $result.0.content "Section"
}

@test
def "parse-md parses code block" [] {
    let result = "```nushell\necho hello\n```" | parse-md
    assert equal ($result | length) 1
    assert equal $result.0.element "code"
    assert equal $result.0.meta.lang "nushell"
    assert equal $result.0.content "echo hello"
}

@test
def "parse-md preserves code block options" [] {
    let result = "```nushell no-run, try\necho hello\n```" | parse-md
    assert equal $result.0.element "code"
    assert ("no-run" in $result.0.meta.options)
    assert ("try" in $result.0.meta.options)
}

@test
def "parse-md parses paragraph" [] {
    let result = "First line\nSecond line" | parse-md
    assert equal ($result | length) 1
    assert equal $result.0.element "p"
    assert ($result.0.content =~ "First line")
    assert ($result.0.content =~ "Second line")
}

@test
def "parse-md separates paragraphs by empty line" [] {
    let result = "Para 1\n\nPara 2" | parse-md
    assert equal ($result | length) 2
    assert equal $result.0.element "p"
    assert equal $result.1.element "p"
    assert equal $result.0.content "Para 1"
    assert equal $result.1.content "Para 2"
}

@test
def "parse-md parses unordered list" [] {
    let result = "- item 1\n- item 2\n- item 3" | parse-md
    assert equal ($result | length) 1
    assert equal $result.0.element "ul"
    assert equal ($result.0.meta.items | length) 3
    assert equal $result.0.meta.items.0 "item 1"
}

@test
def "parse-md parses ordered list" [] {
    let result = "1. first\n2. second" | parse-md
    assert equal ($result | length) 1
    assert equal $result.0.element "ol"
    assert equal ($result.0.meta.items | length) 2
    assert equal $result.0.meta.items.0 "first"
}

@test
def "parse-md detects ordered list start number" [] {
    let result = "5. fifth\n6. sixth" | parse-md
    assert equal $result.0.meta.start 5
}

@test
def "parse-md parses blockquote" [] {
    let result = "> This is a quote\n> continued" | parse-md
    assert equal ($result | length) 1
    assert equal $result.0.element "blockquote"
    assert ($result.0.content =~ "This is a quote")
}

@test
def "parse-md detects github admonition note" [] {
    let result = "> [!NOTE]\n> This is a note" | parse-md
    assert equal $result.0.element "blockquote"
    assert equal $result.0.meta.type "note"
}

@test
def "parse-md detects github admonition warning" [] {
    let result = "> [!WARNING]\n> Be careful" | parse-md
    assert equal $result.0.meta.type "warning"
}

@test
def "parse-md handles mixed content" [] {
    let md = "# Header

Paragraph text

```nushell
ls
```

- item 1
- item 2"

    let result = $md | parse-md

    assert equal ($result | length) 4
    assert equal $result.0.element "h1"
    assert equal $result.1.element "p"
    assert equal $result.2.element "code"
    assert equal $result.3.element "ul"
}

@test
def "parse-md block indices are sequential" [] {
    let result = "# H1\n\n## H2\n\nText" | parse-md
    assert equal $result.0.block_index 0
    assert equal $result.1.block_index 1
    assert equal $result.2.block_index 2
}

@test
def "parse-md handles multiline code block" [] {
    let result = "```rust
fn main() {
    println!(\"Hello\");
}
```" | parse-md

    assert equal $result.0.element "code"
    assert equal $result.0.meta.lang "rust"
    assert ($result.0.content =~ "fn main")
}
