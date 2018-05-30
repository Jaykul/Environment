function Get-SpecialFolder {
    #.Synopsis
    #   Gets the current value for a well known special folder
    [CmdletBinding()]
    param(
        # The name of the Path you want to fetch (supports wildcards).
        #  From the list: AdminTools, ApplicationData, CDBurning, CommonAdminTools, CommonApplicationData, CommonDesktopDirectory, CommonDocuments, CommonMusic, CommonOemLinks, CommonPictures, CommonProgramFiles, CommonProgramFilesX86, CommonPrograms, CommonStartMenu, CommonStartup, CommonTemplates, CommonVideos, Cookies, Desktop, DesktopDirectory, Favorites, Fonts, History, InternetCache, LocalApplicationData, LocalizedResources, MyComputer, MyDocuments, MyMusic, MyPictures, MyVideos, NetworkShortcuts, Personal, PrinterShortcuts, ProgramFiles, ProgramFilesX86, Programs, PSHome, Recent, Resources, SendTo, StartMenu, Startup, System, SystemX86, Templates, UserProfile, Windows
        [ValidateScript({
                $Name = $_
                if(!$Script:SpecialFolders.Count -gt 0) {
                    LoadSpecialFolders
                }
                if($Script:SpecialFolders.Keys -like $Name){
                    return $true
                } else {
                    throw "Cannot convert Path, with value: `"$Name`", to type `"System.Environment+SpecialFolder`": Error: `"The identifier name $Name is not one of $($Script:SpecialFolders.Keys -join ', ')"
                }
            })]
        [String]$Path = "*",

        # If not set, returns a hashtable of folder names to paths
        [Switch]$Value
    )
    Write-Information "Get-SpecialFolder $Path" -Tags "Trace", "Enter"

    $Names = $Script:SpecialFolders.Keys -like $Path
    if(!$Value) {
        $return = @{}
    }

    foreach($name in $Names) {
        $result = $(
            $id = $Script:SpecialFolders.$name
            if($Id -is [string]) {
                $Id
            } else {
                ($Script:SpecialFolders.$name = [Environment]::GetFolderPath([int]$Id))
            }
        )

        if($result) {
            if($Value) {
                Write-Output $result
            } else {
                $return.$name = $result
            }
        }
    }
    if(!$Value) {
        Write-Output $return
    }
    Write-Information "Get-SpecialFolder $Path" -Tags "Trace", "Exit"
}

