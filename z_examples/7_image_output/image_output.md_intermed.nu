# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd

const init_numd_pwd_const = '/Users/user/git/ai-sandbox-dev-container/numd'

# numd config example 1
# This file is prepended to the intermediate script before execution

$env.config.footer_mode = 'always'
$env.config.table = {
    mode: rounded
    index_mode: never
    show_empty: false
    padding: {left: 1, right: 1}
    trim: {methodology: truncating, wrapping_try_keep_words: false, truncating_suffix: '...'}
    header_on_separator: true
    abbreviated_row_count: 1000
}

"#code-block-marker-open-1
```nu image" | print
"[[a b c]; [1 2 3] [4 5 6]]" | nu-highlight | print

do { $env.config.use_ansi_coloring = true; [[a b c]; [1 2 3] [4 5 6]] | table -e --width ($env.numd?.table-width? | default 120) | to png '/Users/user/git/ai-sandbox-dev-container/numd/z_examples/7_image_output/media/image_output.block-1-0.png' | ignore }
print ''
"```" | print
print ''
print "![](media/image_output.block-1-0.png)"

"#code-block-marker-open-3
```nu image" | print
"'first group output'" | nu-highlight | print

do { $env.config.use_ansi_coloring = true; 'first group output' | table -e --width ($env.numd?.table-width? | default 120) | to png '/Users/user/git/ai-sandbox-dev-container/numd/z_examples/7_image_output/media/image_output.block-3-0.png' | ignore }
print ''
"[[x y]; ['hello' 'world']]" | nu-highlight | print

do { $env.config.use_ansi_coloring = true; [[x y]; ['hello' 'world']] | table -e --width ($env.numd?.table-width? | default 120) | to png '/Users/user/git/ai-sandbox-dev-container/numd/z_examples/7_image_output/media/image_output.block-3-1.png' | ignore }
print ''
"```" | print
print ''
print "![](media/image_output.block-3-0.png)"
print "![](media/image_output.block-3-1.png)"

"#code-block-marker-open-5
```nu image, try" | print
"ls /nonexistent-path-for-test" | nu-highlight | print

do { $env.config.use_ansi_coloring = true; try {ls /nonexistent-path-for-test} catch {|error| $error} | table -e --width ($env.numd?.table-width? | default 120) | to png '/Users/user/git/ai-sandbox-dev-container/numd/z_examples/7_image_output/media/image_output.block-5-0.png' | ignore }
print ''
"```" | print
print ''
print "![](media/image_output.block-5-0.png)"

"#code-block-marker-open-9
```nu image, no-output" | print
"'executes but no image'" | nu-highlight | print

'executes but no image'
print ''
"```" | print
