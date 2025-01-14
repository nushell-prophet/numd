
overlay use numd/commands.nu --prefix as 'c'

dotnu parse-docstrings numd/commands.nu | to md | print $in

#: ╭─#──┬────────────command_name─────────────┬─────────────────────────────────────────────command_description─────────────────────────────────────────────┬─...─╮
#: │ 0  │ run                                 │ Run Nushell code blocks in a markdown file, output results back to the `.md`, and optionally to terminal    │ ... │
#: │ 1  │ clear-outputs                       │ Remove numd execution outputs from the file                                                                 │ ... │
#: │ 2  │ capture start                       │ start capturing commands and their outputs into a file                                                      │ ... │
#: │ 3  │ capture stop                        │ stop capturing commands and their outputs                                                                   │ ... │
#: │ 4  │ parse-help                          │ Beautify and adapt the standard `--help` for markdown output                                                │ ... │
#: │ 5  │ find-code-blocks                    │ Detect code blocks in a markdown string and return a table with their line numbers and info strings.        │ ... │
#: │ 6  │ match-action                        │                                                                                                             │ ... │
#: │ 7  │ create-execution-code               │ Generate code for execution in the intermediate script within a given code fence.                           │ ... │
#: │ 8  │ decortate-original-code-blocks      │ generates additional service code necessary for execution and capturing results, while preserving the       │ ... │
#: │    │                                     │ original code.                                                                                              │     │
#: │ 9  │ generate-intermediate-script        │ Generate an intermediate script from a table of classified markdown code blocks.                            │ ... │
#: │ 10 │ execute-block-lines                 │                                                                                                             │ ... │
#: │ 11 │ extract-block-index                 │ Parse block indices from Nushell output lines and return a table with the original markdown line numbers.   │ ... │
#: │ 12 │ merge-markdown                      │ Assemble the final markdown by merging the original classified markdown with parsed results of the          │ ... │
#: │    │                                     │ generated script.                                                                                           │     │
#: │ 13 │ clean-markdown                      │ Prettify markdown by removing unnecessary empty lines and trailing spaces.                                  │ ... │
#: │ 14 │ toggle-output-fences                │ Replacement is needed to distinguish the blocks with outputs from blocks with just ```.                     │ ... │
#: │    │                                     │ `find-code-blocks` works only with lines without knowing the previous lines.                                │     │
#: │ 15 │ compute-change-stats                │ Calculate changes between the original and updated markdown files and return a record with the differences. │ ... │
#: │ 16 │ list-code-options                   │ List code block options for execution and output customization.                                             │ ... │
#: │ 17 │ convert-short-options               │ Expand short options for code block execution to their long forms.                                          │ ... │
#: │ 18 │ escape-special-characters-and-quote │ Escape symbols to be printed unchanged inside a `print "something"` statement.                              │ ... │
#: │ 19 │ execute-intermediate-script         │ Run the intermediate script and return its output lines as a list.                                          │ ... │
#: │ 20 │ mark-code-block                     │ Generate a unique identifier for code blocks in markdown to distinguish their output.                       │ ... │
#: │ 21 │ create-highlight-command            │                                                                                                             │ ... │
#: │ 22 │ remove-comments-plus                │ Trim comments and extra whitespaces from code blocks for use in the generated script.                       │ ... │
#: │ 23 │ get-last-span                       │ Extract the last span from a command to determine if `| print` can be appended                              │ ... │
#: │ 24 │ check-print-append                  │ Check if the last span of the input ends with a semicolon or contains certain keywords to determine if      │ ... │
#: │    │                                     │ appending ` | print` is possible.                                                                           │     │
#: │ 25 │ create-indented-output              │ Generate indented output for better visual formatting.                                                      │ ... │
#: │ 26 │ generate-print-statement            │ Generate a print statement for capturing command output.                                                    │ ... │
#: │ 27 │ generate-table-statement            │ Generate a table statement with optional width specification.                                               │ ... │
#: │ 28 │ create-catch-error-current-instance │ Generate a try-catch block to handle errors in the current Nushell instance.                                │ ... │
#: │ 29 │ create-catch-error-outside          │ Execute the command outside to obtain a formatted error message if any.                                     │ ... │
#: │ 30 │ create-fence-output                 │ Generate a fenced code block for output with a specific format.                                             │ ... │
#: │ 31 │ generate-print-lines                │                                                                                                             │ ... │
#: │ 32 │ generate-tags                       │                                                                                                             │ ... │
#: │ 33 │ extract-fence-options               │ Parse options from a code fence and return them as a list.                                                  │ ... │
#: │ 34 │ modify-path                         │ Modify a path by adding a prefix, suffix, extension, or parent directory.                                   │ ... │
#: │ 35 │ create-file-backup                  │ Create a backup of a file by moving it to a specified directory with a timestamp.                           │ ... │
#: │ 36 │ load-config                         │                                                                                                             │ ... │
#: │ 37 │ generate-timestamp                  │ Generate a timestamp string in the format YYYYMMDD_HHMMSS.                                                  │ ... │
#: │ 38 │ scan                                │ Returns a list of intermediate steps performed by `reduce`                                                  │ ... │
#: │    │                                     │ (`fold`). It takes two arguments, an initial value to seed the                                              │     │
#: │    │                                     │ initial state and a closure that takes two arguments, the first                                             │     │
#: │    │                                     │ being the list element in the current iteration and the second                                              │     │
#: │    │                                     │ the internal state.                                                                                         │     │
#: │    │                                     │ The internal state is also provided as pipeline input.                                                      │     │
#: ╰─#──┴────────────command_name─────────────┴─────────────────────────────────────────────command_description─────────────────────────────────────────────┴─...─╯
