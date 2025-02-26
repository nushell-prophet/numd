# Nushell Key-Value Store (kv)
# Original version by @clipplerblood
# https://discord.com/channels/601130461678272522/615253963645911060/1149709351821516900

# Alias to avoid conflict with the custom 'get' function
alias core_get = get
alias core_ls = ls

# Display the KV store as a table or list files in the values folder
export def ls [] {
    # Load the KV store and display it as a table with modification dates
    load-kv
    | items {|key, value| { name: $key, filename: $value } }
    | insert modified {|item|
        core_ls $item.filename | core_get 0.modified
    }
    | sort-by modified --reverse
    | update modified { date humanize }
    | select name modified
}

# Return the path to the KV store file or values folder
def kv-path [
    --values_folder  # Return the path to the values folder instead of the KV file
]: nothing -> path {
    $env.kv?.path?
    | if $in != null {} else {
        $nu.home-path
        | path join '.config' 'nushell' 'kv'
    }
    | if $values_folder {
        # Return the path to the 'values' folder
        path join 'values'
    } else {
        # Return the path to the 'kv.nuon' file
        path join 'kv.nuon'
    }
}

export def --env init [
    dir?: path
    --reset
] {
    if $dir != null { $env.kv.path = $dir }

    let $kv_file = kv-path

    if $reset or not ($kv_file | path exists) {
        # Create the values folder and initialize an empty KV store
        mkdir (kv-path --values_folder)
        {} | save --force $kv_file
    }
}

# Load the KV store, creating it and the values folder if they don't exist
def load-kv []: nothing -> record {
    # Open and return the KV store
    kv-path | open
}

# Generate a timestamped filename
def date-now [] {
    date now | format date "%Y%m%d_%H%M%S_%f"
}

# Set a value in the KV store, optionally taking input from the pipeline
export def set [
    key: string = 'last'          # Specify the key to set
    value?: any                   # Provide the value to set (optional if used in a pipeline)
    --return-to-stdout (-p)       # Output the input value back to the pipeline
    --extension (-e): string = '' # Specify the file extension for saving
]: any -> any {
    let $input = $in # we store input here as it might be needed to return at the end of this command
    let $value_to_store = if $value == null { $input } else { $value }
    let $value_type = $value_to_store | describe

    # Determine the file extension based on the value type
    let $file_extension = if $extension != '' {
            $extension
        } else if $value_type =~ 'table|list|record|binary' {
            'msgpackz'
        } else if $value_type == 'string' {
            'txt'  # 'msgpackz' can't store primitives in some versions
        } else {
            'nuon'
        }

    # Generate a unique filename for the value
    let $file_path = kv-path --values_folder
        | path join $"($key)_(date-now).($file_extension)"

    # Save the value to the file
    $value_to_store | save $file_path

    # Update the KV store
    load-kv
    | reject $key -i # Remove existing key to sort chronologically
    | insert $key $file_path
    | save -f (kv-path)

    # Output the input value if -p is specified
    if $return_to_stdout { return $input }
}

# Get a value from the KV store
export def get [
    key: string@'nu-complete-key-names' = 'last'  # Specify the key to retrieve
    --ignore-errors (-i)
] {
    load-kv
    | if $key in $in {
        core_get $key | open
    } else {
        if $ignore_errors { return } else {
            error make {msg: $'ther is no `($key)` key in `(kv-path)`'}
        }
    }
}

# Retrieve a file by its filename from the values folder
export def get-file [
    filename: string@'nu-complete-file-names' = ''  # Specify the filename to retrieve
] {
    if $filename == '' {
        core_ls (kv-path --values_folder)
        | sort-by modified -r
    } else {
        kv-path --values_folder
        | path join $filename
        | open
    }
}

# Delete a key from the KV store
export def del [
    key: string@'nu-complete-key-names' = 'last'  # Specify the key to delete
] {
    # Remove the key and save the KV store
    load-kv | reject $key | save -f (kv-path)
}

# Reset the KV store (leave all files in the 'values' folder)
export def reset [] {
    # Confirm before resetting
    [false true]
    | input list 'confirm'
    | if $in {
        {} | save -f (kv-path)
    }
}

# Push a value to a list in the KV store
export def push [
    key: string                 # Specify the key to push to
    value?: any                 # Provide the value to push (optional if used in a pipeline)
    -p                          # Output the input value back to the pipeline
    -u                          # Ensure uniqueness in the list
]: any -> any {
    let $input = $in
    let $value_to_push = if $value != null {
            $value
        } else if $input != null {
            $input
        } else {
            error make { msg: "No value provided to push" }
        }

    let $kv_store = load-kv

    if not ($key in $kv_store) {
        # Key does not exist; create a new list with the value
        $kv_store
        | upsert $key [$value_to_push]
        | save -f (kv-path)
    } else {
        # Key exists; retrieve and update the list
        let $stored_list = $kv_store | core_get $key
        if not ($stored_list | describe | str starts-with 'list') {
            error make { msg: $"Key '($key)' is not associated with a list" }
        }

        let $updated_list = if $u {
                # Ensure uniqueness
                $stored_list | where {|x| $x != $value_to_push} | append $value_to_push
            } else {
                # Simply append the new value
                $stored_list | append $value_to_push
            }

        # Update the KV store
        $kv_store | upsert $key $updated_list | save -f (kv-path)
    }

    # Output the input value if -p is specified
    if $p { return $value_to_push }
}

# Get the last value of a list in the KV store.
# Not an actual "pop". To remove the element, use the flag -r.
# Example:
# > kv set my-stack ["hello", "world"]
# > kv pop my-stack
# world
#
# > kv pop my-stack
# hello
#
# > kv get my-stack
# ╭────────────╮
# │ empty list │
# ╰────────────╯
export def "pop" [
    key  # Key to get
] {
    let $stored = get $key
    let $value = $stored
        | if ($in | length) == 0 { return } else { last }

    if ($stored | length) > 0 { set $key ($stored | drop) }

    $value
}

# Autocompletion for key names
def nu-complete-key-names [] {
    main
    | rename value description
    | {
        completions : $in,
        options: {
            sort: false
        }
    }
}

# Autocompletion for file names in the values folder
def nu-complete-file-names [] {
    core_ls -s (kv-path --values_folder)
    | sort-by modified --reverse
    | select name modified
    | update modified { date humanize }
    | rename value description
}

def history-last [] {
    open $nu.history-path
    | query db "select * from history order by id desc limit 1"
    | get command_line.0
}
