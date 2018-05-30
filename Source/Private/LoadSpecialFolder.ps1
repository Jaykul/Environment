$Script:SpecialFolders = [Ordered]@{}
$OFS = ';'

function LoadSpecialFolders {
    [CmdletBinding()]param()
    Write-Information "LoadSpecialFolders" -Tags "Trace", "Enter"

    $Script:SpecialFolders = [Ordered]@{}

    if("System.Environment+SpecialFolder" -as [type]) {
        foreach($name in [System.Environment+SpecialFolder].GetFields("Public,Static") | Sort-Object Name) {
            $Script:SpecialFolders.($name.Name) = [int][System.Environment+SpecialFolder]$name.Name

            if($Name.Name.StartsWith("My")) {
                $Script:SpecialFolders.($name.Name.Substring(2)) = [int][System.Environment+SpecialFolder]$name.Name
            }
        }
    } else {
        Write-Warning "SpecialFolder Enumeration not found, you're on your own."
    }
    $Script:SpecialFolders.CommonModules = Join-Path $Env:ProgramFiles "WindowsPowerShell\Modules"
    $Script:SpecialFolders.CommonProfile = (Split-Path $Profile.AllUsersAllHosts)
    $Script:SpecialFolders.Modules = Join-Path (Split-Path $Profile.CurrentUserAllHosts) "Modules"
    $Script:SpecialFolders.Profile = (Split-Path $Profile.CurrentUserAllHosts)
    $Script:SpecialFolders.PSHome = $PSHome
    $Script:SpecialFolders.SystemModules = Join-Path (Split-Path $Profile.AllUsersAllHosts) "Modules"

    Write-Information "LoadSpecialFolders" -Tags "Trace", "Exit"
}

if($MyInvocation.MyCommand.Source.EndsWith("ps1")) {
  LoadSpecialFolders

  $SpecialFolders.Modules
}