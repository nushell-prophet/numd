# numd

[R Markdown](https://bookdown.org/yihui/rmarkdown/basics.html#basics) and Jupiter Notebooks inspired text-based notebook for Nushell 🤘

## Quickstart

First, run `$env.config.bracketed_paste = false`

second, copy the example below and paste into your terminal

```nushell
# use the module
use numd.nu

# start capturing commands and their output into the `my_first_numd.txt` file
numd start_capture my_first_numd.txt

# execute some commands in your terminal, to record them and their output
ls
date now
print "this is cool"

# stop capturing
numd stop_capture

# run numd
numd run my_first_numd.txt
```
