use std/iter scan

# Parse markdown into semantic blocks
export def main [
    file?: path # optional path to markdown file (can also pipe content)
]: [string -> table nothing -> table] {
    let input = if $file == null { $in } else { open -r $file }
    $input | parse-md-to-blocks
}

# Classify a single line by markdown element type
export def classify-line []: string -> record {
    let line = $in

    # Frontmatter delimiter (---)
    if $line == '---' {
        return {type: 'fm-delimiter'}
    }

    # Code fence (opening or closing)
    if ($line =~ '^```') {
        let parsed = $line | parse -r '^```(?<lang>\w+)?(?<options>.*)?$'
        let lang = $parsed | get -o lang.0 | default ''
        let options = $parsed
        | get -o options.0
        | default ''
        | str trim
        | if $in == '' { [] } else { split row ',' | each { str trim } }

        return {type: 'fence' lang: $lang options: $options}
    }

    # Headers h1-h6
    if ($line =~ '^#{1,6}\s') {
        let level = $line | parse -r '^(?<hashes>#+)\s' | get hashes.0 | str length
        return {type: $'h($level)'}
    }

    # Unordered list item
    if ($line =~ '^\s*[-*+]\s') {
        return {type: 'ul-item'}
    }

    # Ordered list item
    if ($line =~ '^\s*\d+\.\s') {
        return {type: 'ol-item'}
    }

    # Blockquote
    if ($line =~ '^>\s?') {
        return {type: 'blockquote'}
    }

    # Empty line
    if ($line | str trim | is-empty) {
        return {type: 'empty'}
    }

    # Default: paragraph text
    {type: 'text'}
}

# Extract clean content from a block
def extract-content [element: string lines: list<string>]: nothing -> string {
    match $element {
        'frontmatter' => {
            $lines | str join (char nl)
        }
        'h1' | 'h2' | 'h3' | 'h4' | 'h5' | 'h6' => {
            $lines | first | str replace -r '^#+\s+' ''
        }
        'blockquote' => {
            $lines | each { str replace -r '^>\s?' '' } | str join (char nl)
        }
        'code' => {
            $lines | str join (char nl)
        }
        'p' => {
            $lines | str join (char nl)
        }
        _ => { $lines | str join (char nl) }
    }
}

# Extract metadata for a block
def extract-meta [
    element: string
    lines: list<string>
    class_info: record
]: nothing -> record {
    match $element {
        'frontmatter' => {
            # Parse YAML content into record
            $lines | str join (char nl) | from yaml
        }
        'code' => {
            {
                lang: ($class_info.lang? | default '')
                options: ($class_info.options? | default [])
            }
        }
        'ul' => {
            {items: ($lines | each { str replace -r '^\s*[-*+]\s+' '' })}
        }
        'ol' => {
            let items = $lines | each { str replace -r '^\s*\d+\.\s+' '' }
            let start = $lines | first | parse -r '^\s*(?<n>\d+)\.' | get -o n.0 | default '1' | into int

            {items: $items start: $start}
        }
        'blockquote' => {
            # Detect GitHub-style admonitions like [!NOTE], [!TIP], [!WARNING]
            let first_content = $lines | first | str replace -r '^>\s?' ''
            let admonition = $first_content
            | parse -r '^\[!(?<type>\w+)\]'
            | get -o type.0
            | if $in != null { str downcase } else { null }

            {type: $admonition}
        }
        _ => { {} }
    }
}

# Main parsing function: convert markdown string to semantic block table
def parse-md-to-blocks []: string -> table {
    let file_lines = $in | lines

    # Step 1: Classify each line
    let classified = $file_lines
    | each {|line| {line: $line class: ($line | classify-line)} }

    # Step 2: Track frontmatter and code block state
    # Frontmatter is only valid at document start: first line must be ---
    let with_state = $classified
    | each { $in.class }
    | scan {in_fm: false fm_possible: true in_code: false code_info: null} {|class state|
        if $class.type == 'fm-delimiter' and $state.fm_possible and not $state.in_code {
            if $state.in_fm {
                # Closing frontmatter delimiter
                {in_fm: false fm_possible: false in_code: false code_info: null}
            } else {
                # Opening frontmatter delimiter (only if first line)
                {in_fm: true fm_possible: true in_code: false code_info: null}
            }
        } else if $class.type == 'fence' and not $state.in_fm {
            if $state.in_code {
                {in_fm: false fm_possible: false in_code: false code_info: null}
            } else {
                {in_fm: false fm_possible: false in_code: true code_info: $class}
            }
        } else if $state.in_fm or $state.in_code {
            $state
        } else {
            # Any non-frontmatter content disables frontmatter possibility
            $state | update fm_possible false
        }
    }

    # Step 3: Override classification for lines inside frontmatter/code blocks
    let classified_with_context = $classified
    | zip $with_state
    | each {|pair|
        let item = $pair.0
        let state = $pair.1
        if $state.in_fm and $item.class.type != 'fm-delimiter' {
            $item | update class {type: 'fm-content'}
        } else if $item.class.type == 'fm-delimiter' and $state.in_fm {
            $item | update class {type: 'fm-close'}
        } else if $item.class.type == 'fm-delimiter' and not $state.in_fm and $state.fm_possible {
            $item | update class {type: 'fm-open'}
        } else if $state.in_code and $item.class.type != 'fence' {
            $item | update class {type: 'code-content' code_info: $state.code_info}
        } else if $item.class.type == 'fence' and not $state.in_code {
            # This is an opening fence
            $item | update class {type: 'fence-open' lang: $item.class.lang options: $item.class.options}
        } else if $item.class.type == 'fence' and $state.in_code {
            # This is a closing fence (state was just toggled to false)
            $item | update class {type: 'fence-close'}
        } else {
            $item
        }
    }

    # Step 4: Compute block indices
    let types = $classified_with_context | each { $in.class.type }
    let block_indices = $types
    | window --remainder 2
    | scan 0 {|window index|
        let curr = $window.0
        let next = $window.1?

        # Increment block index on element transitions
        if $curr in ['h1' 'h2' 'h3' 'h4' 'h5' 'h6'] {
            $index + 1
        } else if $curr in ['fence-open' 'fm-open'] {
            # Code block or frontmatter starts
            $index + 1
        } else if $curr == 'empty' {
            # Empty lines separate blocks but aren't blocks themselves
            $index
        } else if $curr != $next and $next != null and $next != 'empty' {
            # Transition between different element types
            $index + 1
        } else if $next == 'empty' and $curr not-in ['empty' 'fence-close' 'code-content' 'fm-content' 'fm-close'] {
            # After empty line, new block starts (except for code content)
            $index + 1
        } else {
            $index
        }
    }

    # Step 5: Merge block indices with classified lines
    let indexed = $classified_with_context
    | zip $block_indices
    | each {|pair| $pair.0 | insert block_index $pair.1 }

    # Step 6: Group by block index and build output
    $indexed
    | where { $in.class.type not-in ['empty' 'fence-open' 'fence-close' 'fm-open' 'fm-close'] }
    | group-by block_index --to-table
    | each {|group|
        let block_idx = $group.block_index | into int
        let items = $group.items
        let first_class = $items | first | get class
        let lines = $items | get line

        # Determine element type
        let element = match $first_class.type {
            'fm-content' => { 'frontmatter' }
            'h1' | 'h2' | 'h3' | 'h4' | 'h5' | 'h6' => { $first_class.type }
            'code-content' => { 'code' }
            'ul-item' => { 'ul' }
            'ol-item' => { 'ol' }
            'blockquote' => { 'blockquote' }
            'text' => { 'p' }
            _ => { 'p' }
        }

        # Get code info for code blocks
        let code_info = if $element == 'code' {
            $first_class.code_info? | default {lang: '' options: []}
        } else {
            {}
        }

        {
            block_index: $block_idx
            element: $element
            content: (extract-content $element $lines)
            meta: (extract-meta $element $lines $code_info)
        }
    }
    | sort-by block_index
    | enumerate
    | each {|row| $row.item | update block_index $row.index }
}
