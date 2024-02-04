# numd

[R Markdown](https://bookdown.org/yihui/rmarkdown/basics.html#basics) inspired, reproducible, text-based notebooks for Nushell:
execute chunks of nushell code within markdown documents, output results to terminal or back to your .md document.

## Quickstart

First, run `$env.config.bracketed_paste = false`

second, copy the example below and paste into your terminal

```nushell
# use the module
use numd.nu

# start capturing commands and their output into the `my_first_numd.md` file
numd start_capture my_first_numd.md

# execute some commands in your terminal, to record them and their output
ls
date now
print "this is cool"

# stop capturing
numd stop_capture

# run numd
numd run my_first_numd.md
```
