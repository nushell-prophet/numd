export def main [
    $n
] {
    let $text = $in
    seq 1 $n | each {$text} | str join
}