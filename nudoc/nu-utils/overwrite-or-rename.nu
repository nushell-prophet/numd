use confirm.nu

export def main [
    $file
    --overwrite (-o) = false
] {
    let $res = $in
    mut $path = $file
    mut $keep_asking = true

    while $keep_asking {
        if ($path | path exists) {
            if $overwrite or (confirm $'would you like to overwrite *($path)*') {
                $keep_asking = false
            } else {
                $path = (input 'Enter the new nudoc filename: ')
            }
        } else {
            $keep_asking = false
        }
    }

    $res
    | save -f $path
}
