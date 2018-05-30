# if you're running "elevated" or sudo, we want to know that:
try {
    if(-not ($IsLinux -or $IsOSX)) {
        $global:PSProcessElevated = [Security.Principal.WindowsIdentity]::GetCurrent().Owner.IsWellKnown("BuiltInAdministratorsSid")
    } else {
        $global:PSProcessElevated = 0 -eq (id -u)
    }
} catch {}
$Script:SpecialFolders = [Ordered]@{}
$OFS = [IO.Path]::PathSeparator
