function Select-UniquePath {
    <#
        .SYNOPSIS
            Select-UniquePath normalizes path variables and ensures only folders that actually currently exist are in them.
        .EXAMPLE
            $ENV:PATH = $ENV:PATH | Select-UniquePath
    #>
    [CmdletBinding()]
    param(
        # Paths to folders
        [Parameter(Position = 1, Mandatory = $true, ValueFromRemainingArguments = $true, ValueFromPipeline)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$Path,

        # If set, output the path(s) as an array of paths
        # Otherwise output joined by -Delimiter
        [switch]$AsArray,

        # The Path value is split by the delimiter. Defaults to '[IO.Path]::PathSeparator' so you can use this on $Env:Path
        [Parameter(Mandatory = $False)]
        [AllowNull()]
        [string]$Delimiter = [IO.Path]::PathSeparator
    )
    begin {
        Write-Information "Select-UniquePath $Delimiter $Path" -Tags "Trace", "Enter"
        [string[]]$Output = @()
    }
    process {
        $Output += $(
            # Split and trim trailing slashes to normalize, and drop empty strings
            $oldPaths = $Path -split $Delimiter -replace '[\\\/]$' -gt ""

            # Remove duplicates that are only different by case on FileSystems that are not case-sensitive
            $folders = if ($false -notin (Test-Path $PSScriptRoot.ToLowerInvariant(), $PSScriptRoot.ToUpperInvariant())) {
                # Converting a path with wildcards forces Windows to calculate the ACTUAL case of the path
                # But may actually cause the wrong folder to be added in a case-sensitive FileSystems
                $oldPaths -replace '(?<!:|\\|/|\*)(\\|/|$)', '*$1'
            } else {
                $oldPaths
            }
            # Use Get-Item -Force to ensure we don't loose hidden folders
            # e.g. this won't work: Convert-Path C:\programdata*
            $newPaths = Get-Item $folders -Force | Convert-Path

            # Make sure we didn't add anything that wasn't already there
            $newPaths | Where-Object { $_ -iin $oldPaths }
        )
    }
    end {
        if ((-not $AsArray) -and $Delimiter) {
            # This is just faster than Select-Object -Unique
            [System.Linq.Enumerable]::Distinct($Output) -join $Delimiter
        } else {
            [System.Linq.Enumerable]::Distinct($Output)
        }
        Write-Information "Select-UniquePath $Delimiter $Path" -Tags "Trace", "Exit"
    }
}
