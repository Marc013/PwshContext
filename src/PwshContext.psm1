function New-Directory {
    <#
        .SYNOPSIS
        Creates a new directory.

        .DESCRIPTION
        Creates a new directory based on the provided path and name.

        .EXAMPLE
        New-Directory -Path 'C:\tmp\pwsh\test'

        Creates directory path C:\tmp\pwsh\test

        .EXAMPLE
        New-Directory -Path '/tmp' -Name 'pwsh/test'

        Creates directory path /tmp/pwsh/test
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Provide the full path.')]
        [string]$Path,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Provide the name of the new directory.')]
        [string]$Name
    )

    [char]$Separator = [System.IO.Path]::DirectorySeparatorChar
    [string]$Path = $Path.TrimEnd($Separator)
    [string]$EnvironmentPath = "$Path$Separator$Name"

    $FullPath = Resolve-Path -Path $EnvironmentPath -ErrorAction SilentlyContinue

    if([string]::IsNullOrEmpty($FullPath)){
        Write-Verbose "Creating path: '$EnvironmentPath'"
        $FullPath = New-Item -Path $EnvironmentPath -ItemType Directory -ErrorAction Stop
    }

    Write-Verbose "New directory full path: '$FullPath'"
    $FullPath
}

function New-VersionNumber {
    <#
        .SYNOPSIS
        Create new version number.

        .DESCRIPTION
        Create new version number using the provided version number or default version '1.0.0.0'.
        The build number is the number of days since January 1 2000.
        The revision number is the number of seconds (divided by two) into the day on which this function is run.

        .EXAMPLE
        New-VersionNumber

        This command will return version 1.0.<build number>.<revision number> (e.g. 1.0.7405.37534).

        .EXAMPLE
        New-VersionNumber -Version 2.1.5247.59601

        This command will return version 2.1.<build number>.<revision number> (e.g. 2.1.64025.13981).
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Version number (e.g. 1.0.7405.37534).')]
        [version]$Version = '1.0.0.0'
    )
    $BaseDate = [datetime]"01/01/2000"
    $CurrentDate = Get-Date
    $Interval = New-TimeSpan -Start $BaseDate -End $CurrentDate
    $BuildNumber = $Interval.Days

    $StartDate=[datetime]::Today
    $EndDate = $CurrentDate
    $RevisionNumber = [math]::Round((New-TimeSpan -Start $StartDate -End $EndDate).TotalSeconds / 2,0)

    [version]"$($Version.Major).$($Version.Minor).$BuildNumber.$RevisionNumber"
}
function Get-PwshModuleData { # NEED TO HANDLE MINIMUMVERSION AND MAXIMUMVERSION, DO I?
    <#
        .SYNOPSIS
        Retrieve PowerShell module information.

        .DESCRIPTION
        Retrieves the information of a PowerShell module from the PowerShell gallery.

        .EXAMPLE
        Get-PwshModuleData -Name Az

        Retrieve information of module Az from the PowerShell gallery.
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'PowerShell module name.')]
        [string]$Name,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'PowerShell module required version.')]
        [version]$RequiredVersion
    )

    if ($RequiredVersion) {
        [string]$RequiredVersionMessage = "with required version '$RequiredVersion'"
        [string]$VersionErrorMessage = "or version '$RequiredVersion' might not be present"
        [hashtable]$FindModuleParameters = @{
            RequiredVersion = $RequiredVersion
        }
    }

    [hashtable]$FindModuleParameters += @{
        Name        = $Name
        Tag         = 'PSEdition_Core'
        Verbose     = $false
        ErrorAction = 'Stop'
    }

    Write-Verbose "Finding PowerShell module '$Name' $RequiredVersionMessage"

    try {
        $Module = Find-Module @FindModuleParameters
    }
    catch {
        throw "Module '$Name' may not be compatible with pwsh core $VersionErrorMessage"
    }

    if ($Module) {
        Write-Verbose "PowerShell module found. Creating PSObject of module data."
        [psobject]$ModuleData = New-Object -Type PSObject -Property @{
            Name         = $Module.Name
            Version      = $Module.Version
            Dependencies = $Module.Dependencies
        }

        foreach ($Item in $Module.Dependencies) {
            [hashtable]$NameVersion = @{ $Item[0] = $Item[1] }
            [array]$Dependencies += $NameVersion
        }

        Write-Verbose "Module name: $($ModuleData.Name)"
        Write-Verbose "Module version: $($ModuleData.Version)"
        Write-Verbose "Module dependencies: $($Dependencies | Out-String)"

        $ModuleData
    }
    else {
        throw "PowerShell module '$Name' not found. `nIt might be the module is not suitable for PowerShell Core."
    }
}

function Build-PwshModuleList {
    <#
        .SYNOPSIS
        Create a list of all modules.

        .DESCRIPTION
        Creates a list of all modules that are required for the function of the specified module when running function Get-PwshModuleData.

        .EXAMPLE
        $ModuleData = Get-PwshModuleData -Name Az
        Build-PwshModuleList -ModuleData $ModuleData

        Creates a list of all required modules.
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Provide the output of function Get-PwshModuleData.')]
        [psobject]$ModuleData
    )

    Write-Verbose "Creating array of module name(s) and version(s)."
    $Dependencies = $ModuleData.Dependencies
    [array]$Modules = @{
        Name    = $ModuleData.Name -as [string]
        Version = $ModuleData.Version.Trim('[').Trim(']') -as [string]
    }

    Write-Verbose "Iterating through module dependencies."
    foreach ($Dependency in $Dependencies) {
        Write-Verbose "Creating hash containing a hashtable per module with its version."
        [array]$DependencyData = $Dependency.CanonicalId.Split('#').Split(':').split('/').Trim('[').Trim(']')
        [string]$ModuleName = $DependencyData[1] #$Dependency.CanonicalId.Split('#').Split(':').split('/')[1]
        [string]$ModuleVersion = $DependencyData[2] #$Dependency.CanonicalId.Split('#').Split(':').split('/').Trim('[').Trim(']')[2]

        [array]$Modules += @{
            Name    = $ModuleName
            Version = $ModuleVersion
        }
        Write-Verbose "Module dependency name: $ModuleName, version: $ModuleVersion"
    }

    Write-Verbose "Returning: $($Modules | Out-String)"
    $Modules
}

function Publish-ExistingModule {
    <#
        .SYNOPSIS
        Copies or moves an existing module.

        .DESCRIPTION
        Copies or moves an existing module to the specified environment path.

        .EXAMPLE
        Publish-ExistingModule -Name Az.Accounts -Version 1.7.4 -EnvironmentPath \tmp\DevEnv01

        This command copies module Az.Accounts version 1.7.4 to directory \tmp\DevEnv01.

        .EXAMPLE
        Publish-ExistingModule -Name Az.Accounts -Version 1.7.4 -EnvironmentPath C:\tmp\DevEnv01 -Move

        This command moves module Az.Accounts version 1.7.4 to directory C:\temp\DevEnv01.
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'PowerShell module name.')]
        [string]$Name,
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'PowerShell module required version.')]
        [version]$Version,
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Environment Path.')]
        [string]$EnvironmentPath,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Specify if the path is to be moved. By default the path is copied')]
        [switch]$Move
    )

    [char]$Separator = [System.IO.Path]::DirectorySeparatorChar
    [string]$EnvironmentPath = $EnvironmentPath.TrimEnd($Separator)
    [string]$GetModuleMessage = "Obtaining module '$Name' for copy when present"

    if($Move){
        [string]$GetModuleMessage = "Locating module '$Name' for move"
        [hashtable]$GetModuleParameters = @{
            Name = $Name
        }
    }

    [hashtable]$GetModuleParameters += @{
        ListAvailable = $true
        Verbose       = $false
        ErrorAction   = 'Stop'
    }

    Write-Verbose $GetModuleMessage
    $ExistingModules = Get-Module @GetModuleParameters

    $ModuleVersionNew = "$Name-$Version"

    foreach ($ExistingModule in $ExistingModules) {
        $ModuleVersionExisting = "$($ExistingModule.Name)-$($ExistingModule.Version)"

        if ($ModuleVersionExisting -eq $ModuleVersionNew) {
            $Path = ([System.IO.DirectoryInfo]$ExistingModule.Path).Parent.FullName
            $ExistingModuleName = $ExistingModule.Name
            $ExistingModuleVersion =$ExistingModule.Version
            $DestinationPath = "$EnvironmentPath$Separator$ExistingModuleName$Separator$ExistingModuleVersion"

            if ($Move){
                Write-Verbose "Creating destination path: '$DestinationPath'"
                New-Directory -Path $DestinationPath -ErrorAction Stop | Out-Null

                Write-Verbose "Moving module: '$ExistingModuleName' - '$ExistingModuleVersion' to '$DestinationPath'."
                Move-Item -LiteralPath $Path -Destination $DestinationPath -ErrorAction Stop #When Parent paths is empty delete that directory
            }
            else{
                Write-Verbose "Copying module: '$ExistingModuleName' - '$ExistingModuleVersion' to '$DestinationPath'."
                Copy-Item -LiteralPath $Path -Destination $DestinationPath -Recurse -ErrorAction Stop
            }
            Write-Verbose "Returning: True"
            return $true
        }
    }
    Write-Verbose "Module '$Name' with version '$Version' not found on the system"
    Write-Verbose "Returning: False"
    $false
}

function Install-PwshModule {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'PowerShell module name.')]
        [string]$Name,
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'PowerShell module version condition.')]
        [ValidateSet('MinimumVersion', 'MaximumVersion', 'RequiredVersion')]
        [string]$Condition,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'PowerShell module version.')]
        [version]$Version,
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Path to install the module.')]
        [string]$Path
    )
    [char]$Separator = [System.IO.Path]::DirectorySeparatorChar
    [string]$Path = "$Path$($Separator)Modules"

    Write-Verbose "Triggering function 'New-Directory' to create path '$Path'."
    $EnvironmentPath = New-Directory -Path $Path -ErrorAction Stop

    Write-Verbose "Triggering function: 'Get-PwshModuleData' and saving results in variable 'ModuleData'."
    $ModuleData = Get-PwshModuleData -Name $Name -RequiredVersion $RequiredVersion -ErrorAction Stop

    Write-Verbose "Triggering function: 'Build-PwshModuleList' with ModuleData and saving results in variable 'ModuleList."
    $ModuleList = Build-PwshModuleList -ModuleData $ModuleData -ErrorAction Stop

    Write-Verbose "Iterating through each module in variable 'ModuleList'."
    foreach ($Module in $ModuleList) {
        $ModuleVersion = $Module.Version
        $ModuleName = $Module.Name
        $ModulePath = "$Path$Separator$ModuleName$Separator$ModuleVersion"
        Write-Verbose "Constructed variable ModulePath: '$ModulePath'."

        Write-Verbose "Validating if module is already present at path '$ModulePath'."
        If (-not $(Test-Path -Path $ModulePath -ErrorAction Stop)) {
            Write-Verbose "Triggering module 'Publish-ExistingModule' for copying module '$ModuleName' with version '$ModuleVersion' when present."
            $CopyResult = Publish-ExistingModule -Name $ModuleName -Version $ModuleVersion -EnvironmentPath $EnvironmentPath -ErrorAction Stop

            switch ($CopyResult) {
                True { continue }
                False {
                    Write-Verbose "Module '$ModuleName' with version '$ModuleVersion' is not present on the system."

                    if($Null -eq $Condition){
                        [string]$Condition = 'RequiredVersion'
                    }

                    Write-Verbose "Installing module '$ModuleName' with version '$ModuleVersion'."
                    $InstallModuleParameters = @{
                        Name               = $ModuleName
                        $Condition         = $ModuleVersion
                        SkipPublisherCheck = $true
                        PassThru           = $true
                        Verbose            = $false
                        ErrorAction        = 'Stop'
                    }
                    Write-Verbose "InstallModuleParameters: $($InstallModuleParameters | Out-String)"
                    $ModuleInstall = Install-Module @InstallModuleParameters

                    Write-Verbose "ModuleInstall: $($ModuleInstall | Out-String)"

                    if ([string]::IsNullOrEmpty($ModuleInstall) -or $ModuleInstall.Version -ne $Version) {
                        $ModuleVersion = (Get-Module -Name $ModuleName -ListAvailable -Verbose:$false)[0].Version
                        Write-Verbose "Module '$ModuleName' with version '$ModuleVersion' is already present and will be copied as you specified condition '$Condition'."

                        Write-Verbose "Triggering function 'Publish-ExistingModule' for copying module $ModuleName with version $ModuleVersion."
                        Publish-ExistingModule -Name $ModuleName -Version $ModuleVersion -EnvironmentPath $EnvironmentPath -ErrorAction Stop | Out-Null
                    }
                    else {
                        Write-Verbose "Triggering function 'Publish-ExistingModule' for moving module $ModuleName with version $ModuleVersion."
                        Publish-ExistingModule -Name $ModuleName -Version $ModuleVersion -EnvironmentPath $EnvironmentPath -Move -ErrorAction Stop | Out-Null
                    }
                }
            }
        }
        else {
            Write-Verbose "Module '$ModuleName' with version '$ModuleVersion' is already present."
        }
    }
}

function Set-PwshContext {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Context path.')]
        [string]$Path
    )

    [char]$Separator = [System.IO.Path]::DirectorySeparatorChar
    [string]$Path = $Path.TrimEnd($Separator)
    [string]$Name = $Path.Split($Separator)[-1]
    [string]$PwshContextJsonPath = "$Path$($Separator)Context$($Separator)PwshContext_$Name.json"
    [string]$ModulesPath = "$Path$($Separator)Modules"

    Write-Host "Preparing PowerShell context '$Name'. `nDepending on the configuration this may take a quick sip or a full coffee." -ForegroundColor Green

    Write-Verbose "Creating module directory: '$ModulesPath'"
    $EnvPath = New-Directory -Path $ModulesPath

    Write-Verbose "When present, reading PowerShell context configuration: '$PwshContextJsonPath'"
    [string]$PwshContextJson = Get-Content -Path $PwshContextJsonPath -Raw -ErrorAction SilentlyContinue
    if ($PwshContextJson) {
        [psobject]$PwshContext =$PwshContextJson | ConvertFrom-Json -Depth 5
        [array]$Modules = $PwshContext.modules
        [string]$Name = $PwshContext.name

        Write-Verbose "Installing PowerShell modules specified in the PowerShell context configuration"
        foreach ($Module in $Modules) {
            Write-Verbose "Installing PowerShell module '$($Module.Name)' with version '$($Module.Version)' and condition '$($Module.condition)'"
            [hashtable]$PwshModuleParameters = @{
                Name        = $Module.Name
                Version     = $Module.Version
                Condition   = $Module.condition
                Path        = "$($PwshContext.path)$Separator$($PwshContext.name)"
                ErrorAction = 'Stop'
            }
            Install-PwshModule @PwshModuleParameters
        }
    }
    else {
        Write-Verbose "Creating PowerShell context configuration file."
        New-PwshContext -Path $Path
    }

    Write-Verbose "Setting default pwsh modules path: '$EnvPath'"
    $env:PSModulePath = "$EnvPath$([System.IO.Path]::PathSeparator)$env:PSModulePath"

    switch ($PSVersionTable.Platform) {
        Win32NT {
            Write-Verbose "Starting new pwsh session and closing this one."
            Start-Process -FilePath pwsh -WorkingDirectory $Path -ArgumentList { -NoExit -command "$Host.UI.RawUI.WindowTitle = 'PwshContext'" } -ErrorAction Stop
            if (-not $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent){
                exit
            }
            else {
                Write-Verbose "Not closing this session as the function is started in verbose mode."
            }
        }
        Unix {
            Write-Verbose "Starting new pwsh session and closing this one."
            pwsh -WorkingDirectory $Path -NoLogo
        }
        Default { throw "Something unexpected happened!" }
    }
}

function New-PwshContext {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Context path.')]
        [string]$Path
    )

    [char]$Separator = [System.IO.Path]::DirectorySeparatorChar
    [string]$Path = $Path.TrimEnd($Separator)
    [string]$ContextName = $Path.split($Separator)[-1]
    [string]$ModulePath = "$Path$($Separator)Modules"
    [string]$PwshContextSettingsPath = "$Path$($Separator)Context"
    [string]$PwshContextSettingsFilePath = "$PwshContextSettingsPath$($Separator)PwshContext_$ContextName.json"

    Write-Verbose "Creating destination path: '$ModulePath'"
    $ModulePath = New-Directory -Path $ModulePath -ErrorAction Stop
    $PwshContextSettingsPath = New-Directory -Path $PwshContextSettingsPath -ErrorAction Stop

    Write-Verbose "Obtaining modules available in path: '$ModulePath'"
    [Object[]]$ExistingModules = (Get-ChildItem -LiteralPath $ModulePath -Depth 1 -Directory -ErrorAction SilentlyContinue).FullName

    Write-Verbose "Obtaining loaded modules"
    $LoadedModules = Get-Module

    Write-Verbose "Creating array of unique modules. When duplicate the highest version is maintained."
    foreach ($LoadedModule in $LoadedModules) {
        Write-Verbose "Excluding module 'PwshContext' and 'posh-git'"
        if (($LoadedModule.ModuleBase -inotmatch '^.*(PowerShell)(\\|\/)\d(-preview)?(.*)?$') -and
            ($LoadedModule.Name -inotmatch 'PwshContext') -and
            ($LoadedModule.Name -inotmatch 'posh-git')) {
            [Object[]]$ExistingModules += $LoadedModule
        }
    }

    [array]$Modules = @()

    foreach ($ExistingModule in $ExistingModules) {
        $PathElements = $ExistingModule.ModuleBase.Split($Separator)

        if($PathElements[-1] -imatch '^(\d+)(\.\d+){2,3}$'){
            [string]$Name = $PathElements[-2]
            [version]$Version = $PathElements[-1]

            if ($Modules.Name -inotcontains $Name) {
                Write-Verbose "Adding to array module '$Name' with version '$Version'"
                $Modules += @{
                    name      = $Name
                    version   = $Version -as [string]
                    condition = 'RequiredVersion'
                }
            }
            else {
                foreach ($Module in $Modules) {
                    [version]$ModuleVersion = $Module.Version
                    [int32]$Index = [array]::IndexOf($Modules, $Module)
                    if (($Module.Name -eq $Name) -and ($ModuleVersion -lt $Version)) { # When allowing preview modules variable $Version is to have '-preview' (and subsequent characters) removed!
                        Write-Verbose "Updating version of module '$Name' from version '$ModuleVersion' to version '$Version'."
                        $Modules[$Index].Version = $Version -as [string]
                    }
                }
            }
        }
    }

    if (Test-Path -LiteralPath $PwshContextSettingsFilePath) {
        $ExistingPwshContextSettings = Get-Content -LiteralPath $PwshContextSettingsFilePath -Raw | ConvertFrom-Json -Depth 5
        [string]$Version = New-VersionNumber -Version $ExistingPwshContextSettings.Version -ErrorAction Stop
    }
    else {
        [string]$Version = New-VersionNumber
    }

    [hashtable]$PwshContextSettings = @{
        version = $Version
        name = $ContextName
        path = $Path.TrimEnd("\$ContextName\")
        modules = $Modules
    }

    $PwshContextSettingsJson = $PwshContextSettings | ConvertTo-Json -Depth 4
    Write-Verbose "Context settings:`n$PwshContextSettingsJson"

    Write-Verbose "Saving PowerShell context settings: '$PwshContextSettingsFilePath'"
    $PwshContextSettingsJson | Out-File -LiteralPath $PwshContextSettingsFilePath -Encoding utf8

    Write-Host "Pwsh context configuration saved at: '$PwshContextSettingsFilePath'" -ForegroundColor Green
}
