<#
.SYNOPSIS
Offline Servicing for Windows 10, Windows Server 2016 and Windows Server 2019

.DESCRIPTION
OSBuilder is used to Update and Configure Windows 10, Windows Server 2016, and Windows Server 2019 using Offline Servicing

.PARAMETER CreatePaths
Creates empty directories used by OSBuilder

.PARAMETER HideDetails
Hides Write-Host output.  Used when called from other functions

.PARAMETER SetPath
Changes the path from the default of C:\OSBuilder to the path specified

.EXAMPLE
Get-OSBuilder -SetPath D:\OSBuilder
Sets the OSBuilder home directory to D:\OSBuilder

.EXAMPLE
Get-OSBuilder -CreatePaths
Creates empty directories used by OSBuilder
#>

function Get-OSBuilder {
    [CmdletBinding()]
    Param (
        [switch]$CreatePaths,
        [switch]$HideDetails,
        [string]$SetPath
    )
    #======================================================================================
    #   Check if OSMedia is installed and prompt for removal 18.10.2
    #======================================================================================
    Get-OSMediaModule
    #======================================================================================
    #   OSBuilder Version 18.10.2
    #======================================================================================
    $global:OSBuilderVersion = $(Get-Module -Name OSBuilder).Version
    if ($HideDetails -eq $false) {
        Write-Host "OSBuilder $OSBuilderVersion" -ForegroundColor Cyan
        Write-Host ""
    }
    #======================================================================================
    #   Create Empty Registry Key and Values 18.10.1
    #======================================================================================
    if (!(Test-Path HKCU:\Software\OSDeploy\OSBuilder)) {New-Item HKCU:\Software\OSDeploy -Name OSBuilder -Force | Out-Null}
    #======================================================================================
    #   Set Global OSBuilder Path 18.10.1
    #======================================================================================
    if (!(Get-ItemProperty -Path 'HKCU:\Software\OSDeploy' -Name OSBuilderPath -ErrorAction SilentlyContinue)) {New-ItemProperty -Path "HKCU:\Software\OSDeploy" -Name OSBuilderPath -Force | Out-Null}
    if ($SetPath) {Set-ItemProperty -Path "HKCU:\Software\OSDeploy" -Name "OSBuilderPath" -Value "$SetPath" -Force}
    $global:OSBuilderPath = $(Get-ItemProperty "HKCU:\Software\OSDeploy").OSBuilderPath
    if (!($OSBuilderPath)) {$global:OSBuilderPath = "$Env:SystemDrive\OSBuilder"}
    #======================================================================================
    #   Set Primary Paths 18.10.1
    #======================================================================================
    $global:OSBuilderContent = "$OSBuilderPath\Content"
    $global:OSBuilderOSBuilds = "$OSBuilderPath\OSBuilds"
    $global:OSBuilderOSMedia = "$OSBuilderPath\OSMedia"
    $global:OSBuilderPEBuilds = "$OSBuilderPath\PEBuilds"
    $global:OSBuilderTasks = "$OSBuilderPath\Tasks"
    #======================================================================================
    #   Set Local Catalog 18.10.1
    #======================================================================================
    $Script:CatalogLocal = "$OSBuilderContent\Updates\Cat.json"
    if (Test-Path "$CatalogLocal") {$OSBuilderCatalogVersion = $(Get-Content $CatalogLocal | ConvertFrom-Json).Version}
    #======================================================================================
    #   OSBuilder URLs 18.10.2
    #======================================================================================
    $global:OSBuilderURL = "https://raw.githubusercontent.com/OSDeploy/OSBuilder.Public/master/OSBuilder.json"
    $global:OSBuilderCatalogURL = "https://raw.githubusercontent.com/OSDeploy/OSBuilder.Public/master/Content/Updates/Cat.json"
    #======================================================================================
    #   Create Paths 18.10.1
    #======================================================================================
    if ($CreatePaths.IsPresent) {
        if (!(Test-Path "$OSBuilderPath"))                                  {New-Item "$OSBuilderPath" -ItemType Directory -Force | Out-Null}
        if (!(Test-Path "$OSBuilderOSBuilds"))                              {New-Item "$OSBuilderOSBuilds" -ItemType Directory -Force | Out-Null}
        if (!(Test-Path "$OSBuilderOSMedia"))                               {New-Item "$OSBuilderOSMedia" -ItemType Directory -Force | Out-Null}
        if (!(Test-Path "$OSBuilderPEBuilds"))                              {New-Item "$OSBuilderPEBuilds" -ItemType Directory -Force | Out-Null}
        if (!(Test-Path "$OSBuilderTasks"))                                 {New-Item "$OSBuilderTasks" -ItemType Directory -Force | Out-Null}

        if (!(Test-Path "$OSBuilderContent"))                               {New-Item "$OSBuilderContent" -ItemType Directory -Force | Out-Null}
        if (!(Test-Path "$OSBuilderContent\Drivers"))                       {New-Item "$OSBuilderContent\Drivers" -ItemType Directory -Force | Out-Null}
        if (!(Test-Path "$OSBuilderContent\ExtraFiles"))                    {New-Item "$OSBuilderContent\ExtraFiles" -ItemType Directory -Force | Out-Null}
        if (!(Test-Path "$OSBuilderContent\ExtraFiles\Win10 x64 1809"))     {New-Item "$OSBuilderContent\ExtraFiles\Win10 x64 1809" -ItemType Directory -Force | Out-Null}
        if (!(Test-Path "$OSBuilderContent\Mount"))                         {New-Item "$OSBuilderContent\Mount" -ItemType Directory -Force | Out-Null}
        if (!(Test-Path "$OSBuilderContent\IsoExtract"))                    {New-Item "$OSBuilderContent\IsoExtract" -ItemType Directory -Force | Out-Null}
		if (!(Test-Path "$OSBuilderContent\LanguagePacks"))                 {New-Item "$OSBuilderContent\LanguagePacks" -ItemType Directory -Force | Out-Null}
        if (!(Test-Path "$OSBuilderContent\Packages"))                      {New-Item "$OSBuilderContent\Packages" -ItemType Directory -Force | Out-Null}
        if (!(Test-Path "$OSBuilderContent\Packages\Win10 x64 1809"))       {New-Item "$OSBuilderContent\Packages\Win10 x64 1809" -ItemType Directory -Force | Out-Null}
        if (!(Test-Path "$OSBuilderContent\Provisioning"))                  {New-Item "$OSBuilderContent\Provisioning" -ItemType Directory -Force | Out-Null}
        if (!(Test-Path "$OSBuilderContent\Scripts"))                       {New-Item "$OSBuilderContent\Scripts" -ItemType Directory -Force | Out-Null}
        if (!(Test-Path "$OSBuilderContent\StartLayout"))                   {New-Item "$OSBuilderContent\StartLayout" -ItemType Directory -Force | Out-Null}
        if (!(Test-Path "$OSBuilderContent\Unattend"))                      {New-Item "$OSBuilderContent\Unattend" -ItemType Directory -Force | Out-Null}
        if (!(Test-Path "$OSBuilderContent\Updates"))                       {New-Item "$OSBuilderContent\Updates" -ItemType Directory -Force | Out-Null}
        if (!(Test-Path "$OSBuilderContent\Updates\Custom"))                {New-Item "$OSBuilderContent\Updates\Custom" -ItemType Directory -Force | Out-Null}
        if (!(Test-Path "$OSBuilderContent\WinPE"))                         {New-Item "$OSBuilderContent\WinPE" -ItemType Directory -Force | Out-Null}
        if (!(Test-Path "$OSBuilderContent\WinPE\ADK\Win10 x64 1809"))      {New-Item "$OSBuilderContent\WinPE\ADK\Win10 x64 1809" -ItemType Directory -Force | Out-Null}
        if (!(Test-Path "$OSBuilderContent\WinPE\DaRT\DaRT 10"))            {New-Item "$OSBuilderContent\WinPE\DaRT\DaRT 10" -ItemType Directory -Force | Out-Null}
        if (!(Test-Path "$OSBuilderContent\WinPE\Drivers\WinPE 10 x64"))    {New-Item "$OSBuilderContent\WinPE\Drivers\WinPE 10 x64" -ItemType Directory -Force | Out-Null}
        if (!(Test-Path "$OSBuilderContent\WinPE\Drivers\WinPE 10 x86"))    {New-Item "$OSBuilderContent\WinPE\Drivers\WinPE 10 x86" -ItemType Directory -Force | Out-Null}
        if (!(Test-Path "$OSBuilderContent\WinPE\ExtraFiles"))              {New-Item "$OSBuilderContent\WinPE\ExtraFiles" -ItemType Directory -Force | Out-Null}
        if (!(Test-Path "$OSBuilderContent\WinPE\Scripts"))                 {New-Item "$OSBuilderContent\WinPE\Scripts" -ItemType Directory -Force | Out-Null}
    }
    #======================================================================================
    #   Remove Old Updates 18.10.1
    #======================================================================================
    if (Test-Path "$OSBuilderContent\UpdateStacks")     {Write-Warning "Directory '$OSBuilderContent\UpdateStacks' is no longer required and can be removed"}
    if (Test-Path "$OSBuilderContent\UpdateWindows")    {Write-Warning "Directory '$OSBuilderContent\UpdateWindows' is no longer required and can be removed"}
    #======================================================================================
    #   Write Map 18.10.1
    #======================================================================================
    if ($HideDetails -eq $false) {
        if (Test-Path $OSBuilderPath)                   {Write-Host "OSBuilder:       $OSBuilderPath" -ForegroundColor Yellow}
            else                                        {Write-Host "OSBuilder:       $OSBuilderPath (does not exist)" -ForegroundColor Yellow}
        if (Test-Path $OSBuilderOSBuilds)               {Write-Host "-OSBuilds:       $OSBuilderOSBuilds" -ForegroundColor Cyan}
            else                                        {Write-Host "-OSBuilds:       $OSBuilderOSBuilds (does not exist)" -ForegroundColor Cyan}
        if (Test-Path $OSBuilderOSMedia)                {Write-Host "-OSMedia:        $OSBuilderOSMedia" -ForegroundColor Cyan}
            else                                        {Write-Host "-OSMedia:        $OSBuilderOSMedia (does not exist)" -ForegroundColor Cyan}
        if (Test-Path $OSBuilderPEBuilds)               {Write-Host "-PEBuilds:       $OSBuilderPEBuilds" -ForegroundColor Cyan}
            else                                        {Write-Host "-PEBuilds:       $OSBuilderPEBuilds (does not exist)" -ForegroundColor Cyan}
        if (Test-Path $OSBuilderTasks)                  {Write-Host "-Tasks:          $OSBuilderTasks" -ForegroundColor Cyan}
            else                                        {Write-Host "-Tasks:          $OSBuilderTasks (does not exist)" -ForegroundColor Cyan}
        Write-Host ""
        if (Test-Path $OSBuilderContent)                {Write-Host "Content:         $OSBuilderContent" -ForegroundColor Yellow}
            else                                        {Write-Host "Content:         $OSBuilderContent (does not exist)" -ForegroundColor Yellow}
        if (Test-Path $OSBuilderContent\Drivers)        {Write-Host "-Drivers:        $OSBuilderContent\Drivers" -ForegroundColor Cyan}
            else                                        {Write-Host "-Drivers:        $OSBuilderContent\Drivers (does not exist)" -ForegroundColor Cyan}
        if (Test-Path $OSBuilderContent\ExtraFiles)     {Write-Host "-Extra Files:    $OSBuilderContent\ExtraFiles" -ForegroundColor Cyan}
            else                                        {Write-Host "-Extra Files:    $OSBuilderContent\ExtraFiles (does not exist)" -ForegroundColor Cyan}
        if (Test-Path $OSBuilderContent\Mount)          {Write-Host "-MountPath:      $OSBuilderContent\Mount" -ForegroundColor Cyan}
            else                                        {Write-Host "-MountPath:      $OSBuilderContent\Mount (does not exist)" -ForegroundColor Cyan}
        if (Test-Path $OSBuilderContent\Packages)       {Write-Host "-Packages:       $OSBuilderContent\Packages" -ForegroundColor Cyan}
            else                                        {Write-Host "-Packages:       $OSBuilderContent\Packages (does not exist)" -ForegroundColor Cyan}
        if (Test-Path $OSBuilderContent\Provisioning)   {Write-Host "-Provisioning:   $OSBuilderContent\Provisioning" -ForegroundColor Cyan}
            else                                        {Write-Host "-Provisioning:   $OSBuilderContent\Provisioning (does not exist)" -ForegroundColor Cyan}
        if (Test-Path $OSBuilderContent\Scripts)        {Write-Host "-Scripts:        $OSBuilderContent\Scripts" -ForegroundColor Cyan}
            else                                        {Write-Host "-Scripts:        $OSBuilderContent\Scripts (does not exist)" -ForegroundColor Cyan}
        if (Test-Path $OSBuilderContent\StartLayout)    {Write-Host "-Start Layouts:  $OSBuilderContent\StartLayout" -ForegroundColor Cyan}
            else                                        {Write-Host "-Start Layouts:  $OSBuilderContent\StartLayout (does not exist)" -ForegroundColor Cyan}
        if (Test-Path $OSBuilderContent\Unattend)       {Write-Host "-Unattend XML:   $OSBuilderContent\Unattend" -ForegroundColor Cyan}
            else                                        {Write-Host "-Unattend XML:   $OSBuilderContent\Unattend (does not exist)" -ForegroundColor Cyan}
        if (Test-Path $OSBuilderContent\Updates)        {Write-Host "-Updates:        $OSBuilderContent\Updates" -ForegroundColor Cyan}
            else                                        {Write-Host "-Updates:        $OSBuilderContent\Updates (does not exist)" -ForegroundColor Cyan}
        if (Test-Path $OSBuilderContent\WinPE)          {Write-Host "-WinPE Content:  $OSBuilderContent\WinPE" -ForegroundColor Cyan}
            else                                        {Write-Host "-WinPE Content:  $OSBuilderContent\WinPE (does not exist)" -ForegroundColor Cyan}
        Write-Host ""
    }
    #======================================================================================
    #   Show Details 18.10.1
    #======================================================================================
    if ($HideDetails -eq $false) {
        if (Test-Path $OSBuilderOSMedia) {
            $ListOSLibrary = Get-ChildItem -Path $OSBuilderOSMedia -Directory
            $ListOSLibrary = $ListOSLibrary | Where-Object {$_.Name -like "*.*"}
            $ListOSLibrary = $ListOSLibrary | Where-Object {Test-Path $(Join-Path $_.FullName (Join-Path 'OS' (Join-Path "sources" "install.wim")))}
            $ListOSLibrary = $ListOSLibrary | Where-Object {$_.Name -notlike "*Archive*"}
            if (@($ListOSLibrary).Count -gt 0) {
                Write-Host "OSMedia: $OSBuilderOSMedia\* (Imported Operating Systems)" -ForegroundColor Yellow
                if ($(Get-ChildItem -Path $OSBuilderOSMedia -Directory | Where-Object {$_.Name -notlike "*.*" -and $_.Name -notlike "*Archive*"})) {
                    Write-Warning "One or more directories does not have a valid UBR at the end of the OSMedia Name"
                    Write-Warning "They are excluded from this list and from OSMedia Selection"
                    Write-Warning "The UBR at the end of the Name is required for functions related to versioning"
                }
                $($ListOSLibrary.Name)
                Write-Host ""
            }
        }
        if (Test-Path $OSBuilderOSBuilds) {
            $ListOSBuilds = Get-ChildItem -Path $OSBuilderOSBuilds -Directory
            $ListOSBuilds = $ListOSBuilds | Where-Object {$_.Name -like "*.*"}
            $ListOSBuilds = $ListOSBuilds | Where-Object {Test-Path $(Join-Path $_.FullName (Join-Path 'OS' (Join-Path "sources" "install.wim")))}
            if (@($ListOSBuilds).Count -gt 0) {
                Write-Host "OSBuilds: $OSBuilderOSBuilds\* (Modified Operating Systems)" -ForegroundColor Yellow
                if ($(Get-ChildItem -Path $OSBuilderOSBuilds -Directory | Where-Object {$_.Name -notlike "*.*" -and $_.Name -notlike "*Archive*"})) {
                    Write-Warning "One or more directories does not have a valid UBR at the end of the OSBuild Name"
                    Write-Warning "They are excluded from this list and from OSBuild Selection"
                    Write-Warning "The UBR at the end of the Name is required for functions related to versioning"
                }
                $($ListOSBuilds.Name)
                Write-Host ""
            }
        }
        if (Test-Path $OSBuilderPEBuilds) {
            $ListPEBuilds = Get-ChildItem -Path $OSBuilderPEBuilds -Directory
            $ListPEBuilds = $ListPEBuilds | Where-Object {$_.Name -like "*.*"}
            $ListPEBuilds = $ListPEBuilds | Where-Object {Test-Path $(Join-Path $_.FullName (Join-Path 'OS' (Join-Path "sources" "install.wim")))}
            if (@($ListPEBuilds).Count -gt 0) {
                Write-Host "OSBuilds: $OSBuilderOSBuilds\* (Modified Operating Systems)" -ForegroundColor Yellow
                if ($(Get-ChildItem -Path $OSBuilderOSBuilds -Directory | Where-Object {$_.Name -notlike "*.*" -and $_.Name -notlike "*Archive*"})) {
                    Write-Warning "One or more directories does not have a valid UBR at the end of the OSBuild Name"
                    Write-Warning "They are excluded from this list and from OSBuild Selection"
                    Write-Warning "The UBR at the end of the Name is required for functions related to versioning"
                }
                $($ListPEBuilds.Name)
                Write-Host ""
            }
        }
        if (Test-Path $OSBuilderTasks) {
            $ListTasks = Get-ChildItem -Path $OSBuilderTasks *.json -File | Where-Object {$_.Name -notlike "*OSMedia*"}
            if (@($ListTasks).Count -gt 0) {
                Write-Host "Tasks: $OSBuilderTasks\* (Automated Task Sequences)" -ForegroundColor Yellow
                $($ListTasks.BaseName)
                Write-Host ""
            }
        }
        if (Test-Path $OSBuilderContent\Scripts) {
            $ListScripts = Get-ChildItem -Path $OSBuilderContent\Scripts *.ps1 -File
            if (@($ListScripts).Count -gt 0) {
                Write-Host "Scripts: $OSBuilderContent\Scripts\*" -ForegroundColor Yellow
                $($ListScripts.Name)
                Write-Host ""
            }
        }
        if (Test-Path $OSBuilderContent\StartLayout) {
            $ListStartLayout = Get-ChildItem -Path $OSBuilderContent\StartLayout *.xml -File
            if (@($ListStartLayout).Count -gt 0) {
                Write-Host "Start Layouts: $OSBuilderContent\StartLayout\*" -ForegroundColor Yellow
                $($ListStartLayout.Name)
                Write-Host ""
            }
        }
        if (Test-Path $OSBuilderContent\Unattend) {
            $ListUnattend = Get-ChildItem -Path $OSBuilderContent\Unattend *.xml -File
            if (@($ListUnattend).Count -gt 0) {
                Write-Host "Unattend XMLs: $OSBuilderContent\Unattend\*" -ForegroundColor Yellow
                $($ListUnattend.Name)
                Write-Host ""
            }
        }
        if (Test-Path $OSBuilderContent\Drivers) {
            $ListDrivers = Get-ChildItem -Path "$OSBuilderContent\Drivers\*" -Directory
            if (@($ListDrivers).Count -gt 0) {
                Write-Host "Drivers: $OSBuilderContent\Drivers\*" -ForegroundColor Yellow
                $($ListDrivers.FullName).replace("$OSBuilderContent\Drivers\","")
                Write-Host ""
            }
        }
        if (Test-Path $OSBuilderContent\ExtraFiles) {
            $ListExtraFiles = Get-ChildItem -Path $OSBuilderContent\ExtraFiles -Directory
            $ListExtraFiles = $ListExtraFiles | Where-Object {(Get-ChildItem $_.FullName | Measure-Object).Count -gt 0}
            if (@($ListExtraFiles).Count -gt 0) {
                Write-Host "Windows Extra Files: $OSBuilderContent\ExtraFiles\*" -ForegroundColor Yellow
                $($ListExtraFiles.Name)
                Write-Host ""
            }
        }
        if (Test-Path "$OSBuilderContent\WinPE\DaRT") {
            $ListWinPEDaRT = Get-ChildItem -Path "$OSBuilderContent\WinPE\DaRT" *.cab -Recurse -File
            if (@($ListWinPEDaRT).Count -gt 0) {
                Write-Host "WinPE DaRT: $OSBuilderContent\WinPE\DaRT\*" -ForegroundColor Yellow
                $($ListWinPEDaRT.FullName).replace("$OSBuilderContent\WinPE\DaRT\","")
                Write-Host ""
            }
        }
        if (Test-Path "$OSBuilderContent\WinPE\Drivers") {
            $ListWinPEDrivers = Get-ChildItem -Path "$OSBuilderContent\WinPE\Drivers\*\*" -Directory
            if (@($ListWinPEDrivers).Count -gt 0) {
                Write-Host "WinPE Drivers: $OSBuilderContent\WinPE\Drivers\*" -ForegroundColor Yellow
                $($ListWinPEDrivers.FullName).replace("$OSBuilderContent\WinPE\Drivers\","")
                Write-Host ""
            }
        }
<#         if (Test-Path "$OSBuilderContent\WinPE\Wallpaper") {
            $ListWinPEWallpaper = Get-ChildItem -Path "$OSBuilderContent\WinPE\Wallpaper" *.jpg -Recurse -File
            if (@($ListWinPEWallpaper).Count -gt 0) {
                Write-Host "WinPE Wallpaper: $OSBuilderContent\WinPE\Wallpaper\*" -ForegroundColor Yellow
                $($ListWinPEWallpaper.FullName).replace("$OSBuilderContent\WinPE\Wallpaper\","")
                Write-Host ""
            }
        } #>
        if (Test-Path $OSBuilderContent\Packages) {
            $ListPackages = Get-ChildItem -Path $OSBuilderContent\Packages -Include *.msu, *.cab -Recurse -File
            if (@($ListPackages).Count -gt 0) {
                Write-Host "Packages: $OSBuilderContent\Packages\*" -ForegroundColor Yellow
                $($ListPackages.FullName).replace("$OSBuilderContent\Packages\","")
                Write-Host ""
            }
        }
        if (Test-Path $OSBuilderContent\Provisioning) {
            $ListPackages = Get-ChildItem -Path $OSBuilderContent\Provisioning -Include *.ppkg, -Recurse -File
            if (@($ListPackages).Count -gt 0) {
                Write-Host "Provisioning: $OSBuilderContent\Provisioning\*" -ForegroundColor Yellow
                $($ListPackages.FullName).replace("$OSBuilderContent\Provisioning\","")
                Write-Host ""
            }
        }
<# 		if (Test-Path "$OSBuilderContent\Updates\Adobe") {
            $ListAdobeUpdates = Get-ChildItem -Path "$OSBuilderContent\Updates\Adobe" -Include *.msu, *.cab -Recurse -File
            if (@($ListAdobeUpdates).Count -gt 0) {
                Write-Host "Adobe Updates: $OSBuilderContent\Updates\Adobe\*" -ForegroundColor Yellow
                $($ListAdobeUpdates.FullName).replace("$OSBuilderContent\Updates\Adobe\","")
                Write-Host ""
            }
        }
        if (Test-Path "$OSBuilderContent\Updates\Component") {
            $ListComponentUpdates = Get-ChildItem -Path "$OSBuilderContent\Updates\Component" -Include *.msu, *.cab -Recurse -File
            if (@($ListComponentUpdates).Count -gt 0) {
                Write-Host "Component Updates: $OSBuilderContent\Updates\Component\*" -ForegroundColor Yellow
                $($ListComponentUpdates.FullName).replace("$OSBuilderContent\Updates\Component\","")
                Write-Host ""
            }
        }
        if (Test-Path "$OSBuilderContent\Updates\Cumulative") {
            $ListCumulativeUpdates = Get-ChildItem -Path "$OSBuilderContent\Updates\Cumulative" -Include *.msu, *.cab -Recurse -File
            if (@($ListCumulativeUpdates).Count -gt 0) {
                Write-Host "Cumulative Updates: $OSBuilderContent\Updates\Cumulative\*" -ForegroundColor Yellow
                $($ListCumulativeUpdates.FullName).replace("$OSBuilderContent\Updates\Cumulative\","")
                Write-Host ""
            }
        }
        if (Test-Path "$OSBuilderContent\Updates\Servicing") {
            $ListServicingUpdates = Get-ChildItem -Path "$OSBuilderContent\Updates\Servicing" -Include *.msu, *.cab -Recurse -File
            if (@($ListServicingUpdates).Count -gt 0) {
                Write-Host "Servicing Updates: $OSBuilderContent\Updates\Servicing\*" -ForegroundColor Yellow
                $($ListServicingUpdates.FullName).replace("$OSBuilderContent\Updates\Servicing\","")
                Write-Host ""
            }
        }
        if (Test-Path "$OSBuilderContent\Updates\Setup") {
            $ListSetupUpdates = Get-ChildItem -Path "$OSBuilderContent\Updates\Setup" -Include *.msu, *.cab -Recurse -File
            if (@($ListSetupUpdates).Count -gt 0) {
                Write-Host "Setup Updates: $OSBuilderContent\Updates\Setup\*" -ForegroundColor Yellow
                $($ListSetupUpdates.FullName).replace("$OSBuilderContent\Updates\Setup\","")
                Write-Host ""
            }
        } #>
    }
    #======================================================================================
    #   Check for OSBuilder Module Updates 18.10.2
    #======================================================================================
    if ($HideDetails -eq $false) {
        $statuscode = try {(Invoke-WebRequest -Uri $OSBuilderURL -UseBasicParsing -DisableKeepAlive).StatusCode}
        catch [Net.WebException]{[int]$_.Exception.Response.StatusCode}
        if (!($statuscode -eq "200")) {
        } else {
            $LatestModuleVersion = @()
            $LatestModuleVersion = Invoke-RestMethod -Uri $OSBuilderURL
            foreach ($line in $($LatestModuleVersion.News)) {Write-Host $line -ForegroundColor Green}
            Write-Host ""

            if ([System.Version]$($LatestModuleVersion.Version) -eq [System.Version]$OSBuilderVersion) {
                Write-Host "OSBuilder Module: OK" -ForegroundColor Green
            } else {
                Write-Warning "OSBuilder Module: Current Version: $OSBuilderVersion"
                Write-Warning "OSBuilder Module: PowerShell Gallery Version: $($LatestModuleVersion.Version)"
                Write-Host ""
                foreach ($line in $($LatestModuleVersion.Info)) {Write-Host $line -ForegroundColor Yellow}
                Write-Host ""
            }
        }
    }
    #======================================================================================
    #   Check for OSBuilder Windows Updates 18.10.2
    #======================================================================================
<# 			if (Test-Path "$Script:UpdatesPath\Catalog.json") {
                $updates = Get-Content -Path "$Script:UpdatesPath\Catalog.json"
                $updates = $updates | ConvertFrom-Json
                if ($($osbuilder.osbuilder.Updates) -eq $($updates.KBNumber[0])) {
                    Write-Host "OSBuilder Microsoft Updates: OK" -ForegroundColor Green
                    Write-Host ""
                } else {
                    Write-Warning "OSBuilder Microsoft Updates: Needs Update"
                    Write-Host ""
                    foreach ($line in $($osbuilder.osbuilder.UpdatesInfo)) {Write-Warning $line}
                    Write-Host ""
                }
            } else {
                Write-Warning "OSBuilder Microsoft Updates: Missing"
                Write-Warning "Get-OSBuilderUpdates can help with this problem"
            } #>


    if ($HideDetails -eq $false) {
        $statuscode = try {(Invoke-WebRequest -Uri $OSBuilderCatalogURL -UseBasicParsing -DisableKeepAlive).StatusCode}
        catch [Net.WebException]{[int]$_.Exception.Response.StatusCode}
        if (!($statuscode -eq "200")) {
        } else {
            $LatestUpdateVersion = @()
            $LatestUpdateVersion = Invoke-RestMethod -Uri $OSBuilderCatalogURL
            if ([System.Version]$($LatestUpdateVersion.Version) -eq [System.Version]$OSBuilderCatalogVersion) {
                Write-Host "OSBuilder Update Catalogs: OK" -ForegroundColor Green
            } else {
                Write-Warning "OSBuilder Update Catalogs: Current Version: $OSBuilderCatalogVersion"
                Write-Warning "OSBuilder Update Catalogs: Latest Version: $($LatestUpdateVersion.Version)"
                Write-Host ""
                foreach ($line in $($LatestUpdateVersion.Info)) {Write-Host $line -ForegroundColor Yellow}
                Write-Host ""
            }
        }
    }
}