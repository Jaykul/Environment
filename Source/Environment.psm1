foreach($private in Join-Path $PSScriptRoot Private\*.ps1 -Resolve -ErrorAction SilentlyContinue) {
    . $private
}
foreach($public in Join-Path $PSScriptRoot Private\*.ps1 -Resolve -ErrorAction SilentlyContinue) {
    . $public
}
