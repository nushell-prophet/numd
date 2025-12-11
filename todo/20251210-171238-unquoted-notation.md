---
status: draft
created: 20251210-171238
updated: 20251210-171238
---
Now we have notation,

<selected-text file="/Users/user/git/numd/README.md" lines="24-26">2. In code blocks that do not contain any lines starting with the `>` symbol, `numd` executes the entire code block as is. If the code produces any output, the output is added next to the code block after an empty line, a line with the word `Output:`, and another empty line. The output is enclosed in code fences without a language identifier.
3. In code blocks that contain one or more lines starting with the `>` symbol, `numd` filters only lines that start with the `>` or `#` symbol. It executes or prints those lines one by one, and outputs the results immediately after the executed line.
</selected-text>

So I would like to get rid of `>` notation for distinguishing commands to execute.

Numd now should parse the block totaly, execute commands delimited by blocks of double new lines, to put their output (if there are any them into `# =>`-starting lines just after those blocks).

And produce separte blocks if there is `separate-block` option in the fence.

First, rewrite todo for clarity and ask user for confirmation.
