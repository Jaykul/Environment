@{
    RootModule = 'Environment.psm1'
    ModuleVersion = '1.1.0'
    GUID = 'fa42d62c-3f2a-426e-bb36-e1c6be2ff2e1'
    Author = 'Joel Bennett'
    CompanyName = 'HuddledMasses.org'
    Copyright = '(c) 2016,2018 Joel Bennett. All rights reserved.'
    Description = 'Provides Trace-Message, and functions for working with Environment and Path variables'
    # For best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = '*'
    FileList = @()
    PrivateData = @{
        # PowerShellGet module
        PSData = @{
            # Tags for PowerShellGallery
            Tags = @('Environment','Path','Trace','Message')
            ReleaseNotes = 'Fixed Select-UniquePath to avoid problems with paths in hidden folders'

            # URIs for PowerShellGallery
            LicenseUri = 'https://github.com/Jaykul/Environment/blob/master/LICENSE.md'
            ProjectUri = 'https://github.com/Jaykul/Environment'
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}

