function Update-ProcessEnvironment {
    <#
        .SYNOPSIS
            Updates the process environment variables
        .DESCRIPTION
            Updates the process environment variables from User and Machine scope defaults.
            By default, only imports new variables, or new values added to path variables.

            With -Overwrite, updates changed values other than paths, throwing out existing changes. See parameter documentation for more details.
        .EXAMPLE
            Update-ProcessEnvironment

            Updates environment variables, adding new values to the environment and path variables
        .EXAMPLE
            Update-ProcessEnvironment -Overwrite

            Updates environment variables, offering to overwrite local process values that have changed from defaults

        .EXAMPLE
            Update-ProcessEnvironment -Overwrite "ChocolateyPath"

            Updates environment variables, explicitly overwriting or removing the "ChocolateyPath" value

        .NOTES
            Under most circumstances it would be a mistake to do this, but if you want to read a PATH value from the defaults (ignoring current values),
            you can use -Overwrite Path to do that.

            Also, it would *definitely* be a mistake to just use "*" as the name, but the OverwriteName does accept wildcards,
            so you could easily (for instance) wipe all of the Octopus environment by specifying -Overwrite Octo*
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidShouldContinueWithoutForce", "", Justification = "We only ShouldContinue when you -Overwrite without a list")]
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = "NewOrPaths")]
    param(
        # If set, prompts to overwrite existing values for variables
        [parameter(Mandatory, ParameterSetName = "Overwrite")]
        [switch]$Overwrite,

        # A list of variable names which are allowed to be overwritten or removed (supports wildcards).
        [Parameter(Position = 0, ParameterSetName = "Overwrite")]
        [string[]]$OverwriteName
    )

    # Get all environment variables for the current Process, as well as System and User environment variable values
    $ProcessValues = [Environment]::GetEnvironmentVariables('Process')
    $MachineValues = [Environment]::GetEnvironmentVariables('Machine')
    $UserValues    = [Environment]::GetEnvironmentVariables('User')

    $PathValues = @( "PSModulePath", "Path"  # These are the core PATH environment variables
        $ProcessValues.GetEnumerator().Where({$_.Key -match "PATH$" -and $_.Value.Contains([IO.Path]::PathSeparator)}).Name
        # It's probably redundant to check for new path values
        # There would need to be a new one in BOTH User and Machine scopes for it to matter
        $UserValues.GetEnumerator().Where({$_.Key -match "PATH$" -and $_.Value.Contains([IO.Path]::PathSeparator)}).Name
        $MachineValues.GetEnumerator().Where({$_.Key -match "PATH$" -and $_.Value.Contains([IO.Path]::PathSeparator)}).Name
    ) | Select-Object -Unique

    # Sort all environment variable names so we update in alphabetical order, and use Get-Unique since they're sorted
    $EnvironmentVariableNames = ($MachineValues.Keys + $UserValues.Keys + $ProcessValues.Keys) | Sort-Object | Get-Unique

    [bool]$ShouldOverwriteAll = $false
    [bool]$ShouldSkipAll = $false

    foreach ($name in $EnvironmentVariableNames) {
        if ($name -in $PathValues) {
            # Path values should concatenate, rather than overwriting
            $CurrentValue = @()
            $paths = @()
            # If this one is in $OverwriteName, ignore the current value
            if (!$OverwriteName.Where({ $Name -like $_ })) {
                # Otherwise, try not to change the current order:
                if ($ProcessValues.ContainsKey($name)) {
                    $CurrentValue = @($ProcessValues[$name] -split [IO.Path]::PathSeparator)
                    $paths = $CurrentValue
                }
            }

            # First the machine values
            if ($MachineValues.ContainsKey($name)) {
                $machinePaths = $MachineValues[$name] -split [IO.Path]::PathSeparator
                # if new values were prefixed to machine paths, they should be prefixed to the path
                if($CurrentValue.Length -and $machinePaths[0] -notin $CurrentValue) {
                    $paths = $machinePaths.Where({ $_ -notin $CurrentValue }) + $paths
                } else {
                    $paths = $paths + $machinePaths.Where({ $_ -notin $CurrentValue })
                }
            }

            # Then the user values
            if ($UserValues.ContainsKey($name)) {
                $userPaths = $UserValues[$name] -split [IO.Path]::PathSeparator
                # if new values were prefixed to user paths, should they be prefixed to the path?
                if($CurrentValue.Length -and $userPaths[0] -notin $CurrentValue) {
                    $paths = $userPaths.Where({ $_ -notin $CurrentValue }) + $paths
                } else {
                    $paths = $paths + $userPaths.Where({ $_ -notin $CurrentValue })
                }
            }

            # Don't try to use Get-Unique here, it requires sorted values
            $paths = $paths.Where{ $_ } | Select-Object -Unique
            $NewValue = $paths -join [IO.Path]::PathSeparator

            # For PATH environment variables, we always update them
            if ($ProcessValues[$name] -ne $NewValue) {
                Write-Verbose "Overwriting Environment Variable $($name) with $($NewValue) (was: $($ProcessValues[$name]))"
            }
            [Environment]::SetEnvironmentVariable($name, $NewValue, 'Process')

        } else {
            $NewValue = if ($UserValues.ContainsKey($name)) {
                $UserValues[$name]
            } elseif ($MachineValues.ContainsKey($name)) {
                $MachineValues[$name]
            }

            if("$NewValue") {
                if ($PSCmdlet.ShouldProcess("Env:$name", "Set to: $($NewValue)")) {
                    $query = "New Value: $($NewValue) `nOld Value: $($ProcessValues[$name])"
                    if (-not $ProcessValues.ContainsKey($name) -or (
                            # We overwrite existing values only if -Overwrite is set and either
                            $ProcessValues[$name] -ne $NewValue -and $Overwrite -and (
                                # They specified it by name
                                $OverwriteName.Where( { $Name -like $_ }) -or
                                # Or they didn't specify any by name, and they say yes to the prompt -- note that this only prompts if you do not specify a list at all
                                ($OverwriteName.Count -eq 0 -and $PSCmdlet.ShouldContinue($query, "Overwrite Env:$name", [ref]$ShouldOverwriteAll, [ref]$ShouldSkipAll))))) {

                        Write-Verbose "Overwriting Environment Variable $($name) with $($NewValue) (was: $($ProcessValues[$name]))"
                        [Environment]::SetEnvironmentVariable($name, $NewValue, 'Process')
                    }
                }
            } else {
                # We remove variables only when they are listed by name in Reset.
                # Otherwise computed environment variables would be removed ...
                # E.g. AppData, ProgramFiles, ComputerName ... so many things that should not be removed
                if ($Overwrite -and $OverwriteName.Where( { $Name -like $_ }) -and $PSCmdlet.ShouldProcess("Env:$name", "Remove Environment Variable")) {
                    Write-Verbose "Removing Environment Variable $($name) (was: $($ProcessValues[$name])) "
                    [Environment]::SetEnvironmentVariable($name, "", 'Process')
                }
            }
        }
    }
}