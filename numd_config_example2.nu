# numd config example 2
# This file is prepended to the intermediate script before execution

$env.config.footer_mode = 'never'
$env.config.table.header_on_separator = true
$env.config.table.mode = 'rounded'
$env.config.table.abbreviated_row_count = 10000

# Set custom table width (overrides default 120)
$env.numd.table-width = 120
