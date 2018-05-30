The Environment PowerShell module is a module for dealing with Paths and Environment variables.

* `Set-EnvironmentVariable` allows you to set an Environment variable _permanently_ at the Machine or User level, or temporarily at the process level.
* `Select-UniquePath` allows you to de-dupe an array of path strings
* `Set-AliasToFirst` searches a list of paths to find the first instance of an app and create an alias pointed to it (allowing you to avoid adding folders to the environment Path variable for a single application).
* `Add-Path` uses the first two to add folders to path variables like `$Env:PSModulePath` or `$Env:PATH` without duplication
* `Get-SpecialFolder` helps Windows users find special folders (like the user's desktop)
* `Trace-Message` writes verbose (or debug or warning) messages with timestamps for script timing

```posh
Install-Module Environment
```

