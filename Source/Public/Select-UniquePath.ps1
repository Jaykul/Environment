function Select-UniquePath {
    [CmdletBinding()]
    param(
        # If non-full, split path by the delimiter. Defaults to ';' so you can use this on $Env:Path
        [Parameter(Mandatory=$False)]
        [AllowNull()]
        [string]$Delimiter=';',

        # Paths to folders
        [Parameter(Position=1,Mandatory=$true,ValueFromRemainingArguments=$true)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$Path
    )
    begin {
        [string[]]$Output = @()
    }
    process {
        #  Write-Verbose "Input: $($Path | % { @($_).Count })"
        $Output += $(
            $oldPaths = $Path -split "$Delimiter" -replace '[\\\/]$' -gt ""
            # Injecting wildcards causes Resolve-Path to figure out the actual case of the path
            $folders = $oldPaths -replace '(?<!(?::|\\\\))(\\|/)', '*$1' -replace '$','*'
            Resolve-Path $folders | Where { $_.Path -iin $oldPaths }
        )
        #  Write-Verbose "Output: $($Output.Count):`n$($Output -join "`n")"
    }
    end {
        if($Delimiter) {
            [System.Linq.Enumerable]::Distinct($Output) -join $Delimiter
        } else {
            [System.Linq.Enumerable]::Distinct($Output)
        }
    }
}