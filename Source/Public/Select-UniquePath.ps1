function Select-UniquePath {
    [CmdletBinding()]
    param(
        # If non-full, split path by the delimiter. Defaults to '[IO.Path]::PathSeparator' so you can use this on $Env:Path
        [Parameter(Mandatory=$False)]
        [AllowNull()]
        [string]$Delimiter = [IO.Path]::PathSeparator,

        # Paths to folders
        [Parameter(Position=1,Mandatory=$true,ValueFromRemainingArguments=$true)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$Path
    )
    begin {
        Write-Information "Select-UniquePath $Delimiter $Path" -Tags "Trace", "Enter"
        [string[]]$Output = @()
    }
    process {
        $Output += $(
            # Split and trim trailing slashes to normalize
            $oldPaths = $Path -split $Delimiter -replace '[\\\/]$' -gt ""
            # Injecting wildcards causes Windows to figure out the actual case of the path
            $folders = $oldPaths -replace '(?<!(?::|\\\\))(\\|/)', '*$1' -replace '$', '*'
            $newPaths = Get-Item $folders -Force | Convert-Path
            # Make sure we didn't add anything that wasn't already there
            $newPaths | Where-Object { $_ -iin $oldPaths }
        )
    }
    end {
        if($Delimiter) {
            [System.Linq.Enumerable]::Distinct($Output) -join $Delimiter
        } else {
            [System.Linq.Enumerable]::Distinct($Output)
        }
        Write-Information "Select-UniquePath $Delimiter $Path" -Tags "Trace", "Exit"
    }
}