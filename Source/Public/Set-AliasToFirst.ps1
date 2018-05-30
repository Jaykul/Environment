function Set-AliasToFirst {
    param(
        [string[]]$Alias,
        [string[]]$Path,
        [string]$Description = "the app in $($Path[0])...",
        [switch]$Force,
        [switch]$Passthru
    )
    Write-Information "Set-AliasToFirst $Alias $Path" -Tags "Trace", "Enter"

    if($App = Resolve-Path $Path -EA Ignore | Sort LastWriteTime -Desc | Select-Object -First 1 -Expand Path) {
        foreach($a in $Alias) {
            # Constant, ReadOnly,
            Set-Alias $a $App -Scope Global -Option AllScope -Description $Description -Force:$Force
        }
        if($Passthru) {
            Split-Path $App
        }
    } else {
        Write-Warning "Could not find $Description"
    }
    Write-Information "Set-AliasToFirst $Alias $Path" -Tags "Trace", "Exit"
}