use cprint.nu

export def main [
    prompt: string
    --default_not (-n)
    --dont_keep_prompt
]: nothing -> bool {
    if not $dont_keep_prompt {cprint $prompt}

    if $default_not { [no yes] } else { [yes no] }
    | input list (if $dont_keep_prompt {cprint --echo --after 0 $prompt} else {''})
    | if $dont_keep_prompt {} else {print-and-pass}
    | $in in [yes]
}
