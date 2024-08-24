"ls | sort-by modified -r" | nu-highlight | print

"```\n```output-numd" | print

ls | sort-by modified -r | table | lines | each {$'//  ($in)' | str trim --right} | str join (char nl) | table | print; print ''
