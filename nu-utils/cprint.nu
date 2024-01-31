# export def main [] {}

use 'str repeat.nu'

# Print the string colorfully with bells and whistles.
export def main [
    ...text_args
    --color (-c): any = 'default'
    --highlight_color (-h): any = 'green_bold'
    --frame_color (-r): any = 'dark_gray'
    --frame (-f): string = ''   # A symbol (or a string) to frame a text
    --before (-b): int = 0      # A number of new lines before a text
    --after (-a): int = 1       # A number of new lines after a text
    --echo (-e)                 # Echo text string instead of printing
    --keep_single_breaks        # Don't remove single line breaks
    --width (-w): int = 80      # The width of text to format it
    --indent (-i): int = 0
    --err_msg                       # produce a record with an error message
] {
    let $width_safe = (
        term size
        | get columns
        | [$in $width] | math min
        | [$in 40] | math max    # term size gives 0 in tests
    )

    def wrapit [] {
        $in
        | str replace -r -a '(?m)^[\t ]+' ''
        | if $keep_single_breaks { } else {
            str replace -r -a '(\n[\t ]*(\n[\t ]*)+)' '⏎'
            | str replace -r -a '\n' ' '        # remove single line breaks used for code formatting
            | str replace -a '⏎' "\n\n"
        }
        | str replace -r -a '[\t ]+$' ''
        | str replace -r -a $"\(.{1,($width_safe - $indent)}\)\(\\s|$\)|\(.{1,($width_safe - $indent)}\)" "$1$3\n"
        | str replace -r $'(char nl)$' ''       # trailing new line
        | str replace -r -a '(?m)^(.)' $'((char sp) | str repeat $indent)$1'
    }

    def colorit [] {
        str replace -r -a '\*([\s\S]+?)\*' $'(ansi reset)(ansi $highlight_color)$1(ansi reset)(ansi $color)'
        | $'(ansi $color)($in)(ansi reset)'
    }

    def frameit [] {
        let $text = $in;
        let $width_frame = (
            $width_safe
            | ($in // ($frame | str length))
            | [$in 1] | math max
        )

        let $frame_line = (
            ' '
            | fill -a r -w $width_frame -c $frame
            | $'(ansi $frame_color)($in)(ansi reset)'
        )

        (
            $frame_line + "\n" + $text + "\n" + $frame_line
        )
    }

    def newlineit [] {
        $"((char nl) | str repeat $before)($in)((char nl) | str repeat $after)"
    }

    (
        $text_args
        | str join ' '
        | wrapit
        | colorit
        | if $frame != '' {
            frameit
        } else {}
        | newlineit
        | if $err_msg {
            {msg: $in}
        } else if $echo {
        } else {
            print -n $in
        }
    )
}
