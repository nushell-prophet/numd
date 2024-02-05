# numd - reproducible Nushell Markdown Notebooks

Execute chunks of nushell code within markdown documents, output results to the terminal or back to your `.md` document.
[R Markdown](https://bookdown.org/yihui/rmarkdown/basics.html#basics) inspired.

## Quickstart


`> git clone https://github.com/maxim-uvarov/numd; cd numd`
`> use numd`
`> numd run --quiet README.md`

## How it works

```nushell
# the 'numd run' commands opens a specified file (the path to the file is provided as a first argument)
# it looks for nushell code chunks
# it splits text to lines
# the lines with comments it just prints as it is
# the lines that start with `>` symbol it prints out as it is and executes, to recive the output
> ls
> date now
```
