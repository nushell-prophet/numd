# nubook
Jupiter Notebooks inspired text-based notebook for Nushell 🤘

## Quickstart

First, run `$env.config.bracketed_paste = false`

second, copy the example below and paste into your terminal

```nushell
# use the module
use nubook.nu

# start capturing commands and their output into the `my_first_nubook.txt` file
nubook start_capture my_first_nubook.txt

# execute some commands
ls
date now
print "this is cool"

# stop capturing
nubook stop_capture

# run nubook
nubook run my_first_nubook.txt
```
