export def main [
    $n: int
]: string -> string {
    let $text = $in
    seq 1 $n | each {$text} | str join
}
