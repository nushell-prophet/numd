use ../../numd/

let parse = open example.md
| numd parse-frontmatter

$parse | print $in

# => ╭─────────┬──────────────────────╮
# => │ title   │ real example         │
# => │ date    │ 2025-11-01           │
# => │ content │                      │
# => │         │ # Hello, world       │
# => │         │                      │
# => │         │ It's me. I love you. │
# => │         │                      │
# => ╰─────────┴──────────────────────╯

$parse | numd to md-with-frontmatter | print $in

# => ---
# => title: real example
# => date: 2025-11-01
# => ---
# => 
# => # Hello, world
# => 
# => It's me. I love you.
