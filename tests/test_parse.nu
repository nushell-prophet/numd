use std/assert
use std/testing *

use ../numd/parse.nu *

# =============================================================================
# Tests for parse-frontmatter
# =============================================================================

@test
def "parse-frontmatter parses valid frontmatter" [] {
    let result = "---\ntitle: Hello\n---\nBody text" | parse-frontmatter

    assert equal $result.title "Hello"
    assert equal $result.content "Body text"
}

@test
def "parse-frontmatter returns content when no frontmatter" [] {
    let result = "Just plain text" | parse-frontmatter

    assert equal $result {content: "Just plain text"}
}

@test
def "parse-frontmatter handles unclosed delimiter" [] {
    let result = "---\ntitle: Hello\nBody text" | parse-frontmatter

    assert equal ($result | columns) ["content"]
    assert ($result.content | str starts-with "---")
}

@test
def "parse-frontmatter handles multiple fields" [] {
    let result = "---\ntitle: Hello\nauthor: Someone\n---\nBody" | parse-frontmatter

    assert equal $result.title "Hello"
    assert equal $result.author "Someone"
    assert equal $result.content "Body"
}

# =============================================================================
# Tests for to md-with-frontmatter
# =============================================================================

@test
def "to md-with-frontmatter renders content-only record" [] {
    let result = {content: "Just body"} | to md-with-frontmatter

    assert equal $result "Just body"
}

@test
def "to md-with-frontmatter renders frontmatter and body" [] {
    let result = {title: "Hello" content: "Body"} | to md-with-frontmatter

    assert ($result =~ '---')
    assert ($result =~ 'title: Hello')
    assert ($result =~ 'Body')
}
