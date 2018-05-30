# if you're running "elevated" or sudo, we want to know that:
try {
    if(-not ($IsLinux -or $IsOSX)) {
        # https://msdn.microsoft.com/en-us/library/windows/desktop/aa379602
        # BA -> BUILTIN_ADMINISTRATORS
        $global:PSProcessElevated = [Security.Principal.WindowsIdentity]::GetCurrent().Owner.IsWellKnown("BuiltInAdministratorsSid")
    } else {
        $global:PSProcessElevated = 0 -eq (id -u)
    }
} catch {}
$OFS = ';'
