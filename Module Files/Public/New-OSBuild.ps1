<#
.SYNOPSIS
Applies Adobe, Component, Cumulative, Servicing Stack, and Setup Updates to Windows 10, Windows Server 2016, and Windows Server 2019 using Offline Servicing

.DESCRIPTION
Updates are gathered from the OSBuilder Update Catalogs

.PARAMETER CustomCumulativeUpdate
Specify a custom Cumulative Update

.PARAMETER CustomServicingStack
Specify a custom Servicing Stack

.PARAMETER DownloadUpdates
Automatically download the required updates if they are not present in the Content\Updates directory

.PARAMETER Execute
Execute the Build

.PARAMETER PromptBeforeDismount
Adds a 'Press Enter to Continue' prompt before the Install.wim is dismounted

.PARAMETER PromptBeforeDismountWinPE
Adds a 'Press Enter to Continue' prompt before the WinPE Wims are dismounted
#>
function New-OSBuild {
    [CmdletBinding(DefaultParameterSetName='Default')]
    Param (
        [switch]$DownloadUpdates,
        [switch]$Execute,
        [Parameter(ParameterSetName='Advanced')]
        [switch]$PromptBeforeDismount,
        [Parameter(ParameterSetName='Advanced')]
        [switch]$PromptBeforeDismountWinPE,
        [Parameter(ParameterSetName='Advanced')]
        [switch]$CustomCumulativeUpdate,
        [Parameter(ParameterSetName='Advanced')]
        [switch]$CustomServicingStack,
        [Parameter(ParameterSetName='Advanced')]
        [switch]$DontUseNewestMedia
    )
    #======================================================================================
    #   Start 18.9.27
    #======================================================================================
    Write-Host "===========================================================================" -ForegroundColor Green
    Write-Host "New-OSBuild" -ForegroundColor Green
    Write-Host "===========================================================================" -ForegroundColor Green
    #======================================================================================
    #   Validate Administrator Rights 18.9.27
    #======================================================================================
    if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host ""
        Write-Host "OSBuilder: This function needs to be run as Administrator" -ForegroundColor Yellow
        Write-Host ""
        Return
    }
    #======================================================================================
    #	Initialize OSBuilder 18.9.24
    #======================================================================================
    Get-OSBuilder -CreatePaths -HideDetails
    #======================================================================================
    #	Select Task JSON 18.10.17
    #======================================================================================
    $SelectTask = Get-ChildItem -Path $OSBuilderTasks OSBuild*.json -File | Where-Object {$_.Name -notlike "*OSMedia*"} | Select-Object -Property BaseName, FullName, Length, CreationTime, LastWriteTime | Sort-Object -Property FullName
    if ($CustomCumulativeUpdate.IsPresent -or $CustomServicingStack.IsPresent) {
		$SelectTask = $SelectTask | Out-GridView -Title "OSBuilder Tasks: Select one or more Tasks to execute and press OK (Cancel to Exit)" -OutputMode Single
	} else {
		$SelectTask = $SelectTask | Out-GridView -Title "OSBuilder Tasks: Select one or more Tasks to execute and press OK (Cancel to Exit)" -Passthru
	}
	
    if($null -eq $SelectTask) {
        Write-Warning "OSBuild Task was not selected or found . . . Exiting!"
        Return
    }
    #======================================================================================
    #	Start Task 18.10.3
    #======================================================================================
    foreach ($TaskFile in $SelectTask) {
        #======================================================================================
        #	Read Task Contents 18.10.3
        #======================================================================================
        $Task = Get-Content "$($TaskFile.FullName)" | ConvertFrom-Json
        $TaskName = $($Task.TaskName)
        $TaskVersion = $($Task.TaskVersion)
        $TaskType = $($Task.TaskType)
        $MediaName = $($Task.MediaName)
        $MediaPath = "$OSBuilderOSMedia\$MediaName"
        $BuildName = $($Task.BuildName)
        $CustomBuildName = $($Task.BuildName)
        $DisableFeature = $($Task.DisableWindowsOptionalFeature)
        $Drivers = $($Task.AddWindowsDriver)
        $EnableFeature = $($Task.EnableWindowsOptionalFeature)
        $EnableNetFX3 = $($Task.EnableNetFX3)
        $ExtraFiles = $($Task.RobocopyExtraFiles)
        $FeaturesOnDemand = $($Task.AddFeatureOnDemand)
        $LanguageFeatures = $($Task.AddLanguageFeature)
        $LanguageInterfacePacks = $($Task.AddLanguageInterfacePack)
        $LanguagePacks = $($Task.AddLanguagePack)
        $Packages = $($Task.AddWindowsPackage)
        $RemoveAppx = $($Task.RemoveAppxProvisionedPackage)
        $RemoveCapability = $($Task.RemoveWindowsCapability)
        $RemovePackage = $($Task.RemoveWindowsPackage)
        $Scripts = $($Task.InvokeScript)
        $SetAllIntl = $($Task.LangSetAllIntl)
        $SetInputLocale = $($Task.LangSetInputLocale)
        $SetSKUIntlDefaults = $($Task.LangSetSKUIntlDefaults)
        $SetSetupUILang = $($Task.LangSetSetupUILang)
        $SetSysLocale = $($Task.LangSetSysLocale)
        $SetUILang = $($Task.LangSetUILang)
        $SetUILangFallback = $($Task.LangSetUILangFallback)
        $SetUserLocale = $($Task.LangSetUserLocale)
        $StartLayout = $($Task.ImportStartLayout)
        $Unattend = $($Task.UseWindowsUnattend)
        $WinPEADKPE = $($Task.WinPEAddADKPE)
        $WinPEADKRE = $($Task.WinPEAddADKRE)
        $WinPEADKSetup = $($Task.WinPEAddADKSetup)
        $WinPEDaRT = $($Task.WinPEAddDaRT)
        $WinPEDrivers = $($Task.WinPEAddWindowsDriver)
        $WinPEExtraFilesPE = $($Task.WinPERobocopyExtraFilesPE)
        $WinPEExtraFilesRE = $($Task.WinPERobocopyExtraFilesRE)
        $WinPEExtraFilesSetup = $($Task.WinPERobocopyExtraFilesSetup)
        $WinPEScriptsPE = $($Task.WinPEInvokeScriptPE)
        $WinPEScriptsRE = $($Task.WinPEInvokeScriptRE)
        $WinPEScriptsSetup = $($Task.WinPEInvokeScriptSetup)
        #======================================================================================
        #   Start Task 18.9.24
        #======================================================================================
        Write-Host "===========================================================================" -ForegroundColor Green
        Write-Host "Starting Task: $TaskName" -ForegroundColor Green
        Write-Host "===========================================================================" -ForegroundColor Green
        #======================================================================================
        #	Validate Proper TaskVersion 18.9.24
        #======================================================================================
        if ([System.Version]$TaskVersion -lt [System.Version]"18.9.24") {
            Write-Warning "OSBuilder Tasks need to be version 18.9.24 or newer"
            Write-Warning "Recreate this Task using New-OSBuildTask"
            Return
        }
        #======================================================================================
        #	Select Latest Media 18.9.24
        #======================================================================================
        if (!($DontUseNewestMedia)) {
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Task Source OSMedia" -ForegroundColor Yellow
            Write-Host "-Media Name:        $MediaName" -ForegroundColor Cyan
            Write-Host "-Media Path:        $MediaPath" -ForegroundColor Cyan
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Latest Source OSMedia" -ForegroundColor Yellow
            #$LatestSource = Get-ChildItem $OSBuilderOSMedia -Directory -filter "*$($MediaName.split(".")[0]).*" | Sort-Object {[int] $_.Name.Split(".")[1]} | Select-Object -Last 1
            $LatestSource = Get-ChildItem $OSBuilderOSMedia -Directory -filter "*$($MediaName.split(".")[0]).*" | Sort-Object {[int] $(($_.Name.Split(".")[1]).Split(" ")[0])} | Select-Object -Last 1
            $MediaName = $LatestSource.BaseName
            $MediaPath = "$OSBuilderOSMedia\$MediaName"
            Write-Host "-Media Name:		$MediaName" -ForegroundColor Cyan
            Write-Host "-Media Path:		$MediaPath" -ForegroundColor Cyan
        }
        #======================================================================================
        #	Get Windows Image Information 18.10.3
        #======================================================================================
        $OSSourcePath = $MediaPath
        $OSImagePath = "$OSSourcePath\OS\sources\install.wim"
        $OSImageIndex = 1
        $WindowsImage = Get-WindowsImage -ImagePath "$OSImagePath" -Index $OSImageIndex | Select-Object -Property *

        $OSImageName = $($WindowsImage.ImageName)
        $OSImageDescription = $($WindowsImage.ImageDescription)
        if ($($WindowsImage.Architecture) -eq 0) {$OSArchitecture = 'x86'}
        elseif ($($WindowsImage.Architecture) -eq 1) {$OSArchitecture = 'MIPS'}
        elseif ($($WindowsImage.Architecture) -eq 2) {$OSArchitecture = 'Alpha'}
        elseif ($($WindowsImage.Architecture) -eq 3) {$OSArchitecture = 'PowerPC'}
        elseif ($($WindowsImage.Architecture) -eq 6) {$OSArchitecture = 'ia64'}
        elseif ($($WindowsImage.Architecture) -eq 9) {$OSArchitecture = 'x64'}
        else {$OSArchitecture = $null}
        $OSEditionID = $($WindowsImage.EditionId)
        $OSInstallationType = $($WindowsImage.InstallationType)
        $OSLanguages = $($WindowsImage.Languages)
        $OSBuild = $($WindowsImage.Build)
        $OSVersion = $($WindowsImage.Version)
        $OSSPBuild = $($WindowsImage.SPBuild)
        $OSSPLevel = $($WindowsImage.SPLevel)
        $OSImageBootable = $($WindowsImage.ImageBootable)
        $OSWIMBoot = $($WindowsImage.WIMBoot)
        $OSCreatedTime = $($WindowsImage.CreatedTime)
        $OSModifiedTime = $($WindowsImage.ModifiedTime)
        #======================================================================================
        Write-Host "OSMedia Information" -ForegroundColor Yellow
        Write-Host "-Source Path:           $OSSourcePath" -ForegroundColor Cyan
        Write-Host "-Image File:            $OSImagePath" -ForegroundColor Cyan
        Write-Host "-Image Index:           $OSImageIndex" -ForegroundColor Cyan
        Write-Host "-Name:                  $OSImageName" -ForegroundColor Cyan
        Write-Host "-Description:           $OSImageDescription" -ForegroundColor Cyan
        Write-Host "-Architecture:          $OSArchitecture" -ForegroundColor Cyan
        Write-Host "-Edition:               $OSEditionID" -ForegroundColor Cyan
        Write-Host "-Type:                  $OSInstallationType" -ForegroundColor Cyan
        Write-Host "-Languages:             $OSLanguages" -ForegroundColor Cyan
        Write-Host "-Build:                 $OSBuild" -ForegroundColor Cyan
        Write-Host "-Version:               $OSVersion" -ForegroundColor Cyan
        Write-Host "-SPBuild:               $OSSPBuild" -ForegroundColor Cyan
        Write-Host "-SPLevel:               $OSSPLevel" -ForegroundColor Cyan
        Write-Host "-Bootable:              $OSImageBootable" -ForegroundColor Cyan
        Write-Host "-WimBoot:               $OSWIMBoot" -ForegroundColor Cyan
        Write-Host "-Created Time:          $OSCreatedTime" -ForegroundColor Cyan
        Write-Host "-Modified Time:         $OSModifiedTime" -ForegroundColor Cyan
        #======================================================================================
        if (Test-Path "$OSSourcePath\info\xml\CurrentVersion.xml") {
            $RegCurrentVersion = Import-Clixml -Path "$OSSourcePath\info\xml\CurrentVersion.xml"
            $OSVersionNumber = $($RegCurrentVersion.ReleaseId)            
            if ($OSVersionNumber -gt 1809) {
                Write-Warning "OSBuilder does not currently support this version of Windows ... Check for an updated version"
                #Write-Warning "OSBuilder cannot proceed . . . Exiting"
                #Return
            }
        } else {
            if ($OSBuild -eq 10240) {$OSVersionNumber = 1507}
            if ($OSBuild -eq 14393) {$OSVersionNumber = 1607}
            if ($OSBuild -eq 15063) {$OSVersionNumber = 1703}
            if ($OSBuild -eq 16299) {$OSVersionNumber = 1709}
            if ($OSBuild -eq 17134) {$OSVersionNumber = 1803}
            if ($OSBuild -eq 17763) {$OSVersionNumber = 1809}
        }
        #======================================================================================
        #	Set Working Path 18.9.24
        #======================================================================================
        $BuildName = "build$((Get-Date).ToString('mmss'))"
        $WorkingPath = "$OSBuilderOSBuilds\$BuildName"
        #======================================================================================
        #	Validate Exiting WorkingPath 18.9.24
        #======================================================================================
        if (Test-Path $WorkingPath) {
            Write-Warning "$WorkingPath exists.  Contents will be replaced"
            Remove-Item -Path "$WorkingPath" -Force -Recurse
            Write-Host ""
        }
        #======================================================================================
        #	Update Catalogs 18.9.23
        #======================================================================================
        if ($DownloadUpdates.IsPresent) {Get-OSBuilderUpdates -UpdateCatalogs -HideDetails}
        if (!(Test-Path $CatalogLocal)) {Get-OSBuilderUpdates -UpdateCatalogs -HideDetails}
        #======================================================================================
        #	Get Catalogs 18.9.23
        #======================================================================================
        $ImportCatalog = @()
        $CatalogDownloads = @()
        $CatalogsXmls = Get-ChildItem "$OSBuilderContent\Updates" *.xml -Recurse
        foreach ($CatalogsXml in $CatalogsXmls) {
            $ImportCatalog = Import-Clixml -Path "$($CatalogsXml.FullName)"
            $CatalogDownloads += $ImportCatalog
        }
        #======================================================================================
        #   Adobe Updates 18.10.12
        #======================================================================================
        $UpdateCatAdobe = @()
        $UpdateCatAdobe = $CatalogDownloads | Where-Object {$_.Category -eq 'Adobe'}
        $UpdateCatAdobe = $UpdateCatAdobe | Where-Object {$_.KBTitle -like "*$OSVersionNumber*"}
        $UpdateCatAdobe = $UpdateCatAdobe | Where-Object {$_.KBTitle -like "*$OSArchitecture*"}
        if ($OSInstallationType -like "*Server*") {
            $UpdateCatAdobe = $UpdateCatAdobe | Where-Object {$_.KBTitle -like "*Server*"}
        } else {
            $UpdateCatAdobe = $UpdateCatAdobe | Where-Object {$_.KBTitle -notlike "*Server*"}
        }
        #======================================================================================
        #   Component Updates 18.10.12
        #======================================================================================
        $UpdateCatComponent = @()
        $UpdateCatComponent = $CatalogDownloads | Where-Object {$_.Category -eq 'Component'}
        $UpdateCatComponent = $UpdateCatComponent | Where-Object {$_.KBTitle -like "*$OSVersionNumber*"}
        $UpdateCatComponent = $UpdateCatComponent | Where-Object {$_.KBTitle -like "*$OSArchitecture*"}
        if ($OSInstallationType -like "*Server*") {
            $UpdateCatComponent = $UpdateCatComponent | Where-Object {$_.KBTitle -like "*Server*"}
        } else {
            $UpdateCatComponent = $UpdateCatComponent | Where-Object {$_.KBTitle -notlike "*Server*"}
        }
        $UpdateCatComponent = $UpdateCatComponent | Sort-Object -Property KBTitle
        #======================================================================================
        #   Cumulative Updates 18.10.12
        #======================================================================================
        if ($CustomCumulativeUpdate.IsPresent) {
            #Custom Cumulative Update
        } else {
            $UpdateCatCumulative = @()
            $UpdateCatCumulative = $CatalogDownloads | Where-Object {$_.Category -eq 'Cumulative'}
            $UpdateCatCumulative = $UpdateCatCumulative | Where-Object {$_.KBTitle -like "*$OSVersionNumber*"}
            $UpdateCatCumulative = $UpdateCatCumulative | Where-Object {$_.KBTitle -like "*$OSArchitecture*"}
            if ($OSInstallationType -like "*Server*") {
                $UpdateCatCumulative = $UpdateCatCumulative | Where-Object {$_.KBTitle -like "*Server*"}
            } else {
                $UpdateCatCumulative = $UpdateCatCumulative | Where-Object {$_.KBTitle -notlike "*Server*"}
            }
            $UpdateCatCumulative = $UpdateCatCumulative | Sort-Object -Property DatePosted
        }
        #======================================================================================
        #   Servicing Stacks 18.10.12
        #======================================================================================
        if ($CustomServicingStack.IsPresent) {
            #Custom Servicing Stack
        } else {
            $UpdateCatServicing = @()
            $UpdateCatServicing = $CatalogDownloads | Where-Object {$_.Category -eq 'Servicing'}
            $UpdateCatServicing = $UpdateCatServicing | Where-Object {$_.KBTitle -like "*$OSVersionNumber*"}
            $UpdateCatServicing = $UpdateCatServicing | Where-Object {$_.KBTitle -like "*$OSArchitecture*"}
            if ($OSInstallationType -like "*Server*") {
                $UpdateCatServicing = $UpdateCatServicing | Where-Object {$_.KBTitle -like "*Server*"}
            } else {
                $UpdateCatServicing = $UpdateCatServicing | Where-Object {$_.KBTitle -notlike "*Server*"}
            }
        }
        #======================================================================================
        #   Setup Updates 18.10.12
        #======================================================================================
        $UpdateCatSetup = @()
        $UpdateCatSetup = $CatalogDownloads | Where-Object {$_.Category -eq 'Setup'}
        $UpdateCatSetup = $UpdateCatSetup | Where-Object {$_.KBTitle -like "*$OSVersionNumber*"}
        $UpdateCatSetup = $UpdateCatSetup | Where-Object {$_.KBTitle -like "*$OSArchitecture*"}
        if ($OSInstallationType -like "*Server*") {
            $UpdateCatSetup = $UpdateCatSetup | Where-Object {$_.KBTitle -like "*Server*"}
        } else {
            $UpdateCatSetup = $UpdateCatSetup | Where-Object {$_.KBTitle -notlike "*Server*"}
        }
        #======================================================================================
        #	Update Validation 18.10.12
        #======================================================================================
        Write-Host "===========================================================================" -ForegroundColor Yellow
        Write-Host "Updates to Apply" -ForegroundColor Yellow

        foreach ($Update in $UpdateCatAdobe) {
            $(Get-ChildItem -Path $OSBuilderContent\Updates -Directory -Recurse | Where-Object {$_.Name -eq $($Update.KBTitle)}).FullName
            if (!(Test-Path "$OSBuilderContent\Updates\*\$($Update.KBTitle)\$($Update.FileName)")) {
                if ($DownloadUpdates.IsPresent) {
                    Write-Warning "Missing $($Update.KBTitle) ... Downloading"
                    Get-OSBuilderUpdates -FilterKBTitle "$($Update.KBTitle)" -Download -HideDetails
                } else {
                    Write-Warning "Missing $($Update.KBTitle) ... Execution will be Disabled"
                    $Execute = $false
                }
            }
        }
        foreach ($Update in $UpdateCatComponent) {
            $(Get-ChildItem -Path $OSBuilderContent\Updates -Directory -Recurse | Where-Object {$_.Name -eq $($Update.KBTitle)}).FullName
            if (!(Test-Path "$OSBuilderContent\Updates\*\$($Update.KBTitle)\$($Update.FileName)")) {
                if ($DownloadUpdates.IsPresent) {
                    Write-Warning "Missing $($Update.KBTitle) ... Downloading"
                    Get-OSBuilderUpdates -FilterKBTitle "$($Update.KBTitle)" -Download -HideDetails
                } else {
                    Write-Warning "Missing $($Update.KBTitle) ... Execution will be Disabled"
                    $Execute = $false
                }
            }
        }
        if ($CustomCumulativeUpdate.IsPresent) {
            Write-Host "$($UpdateCatCumulative.FullName)"
        } else {
            foreach ($Update in $UpdateCatCumulative) {
                $(Get-ChildItem -Path $OSBuilderContent\Updates -Directory -Recurse | Where-Object {$_.Name -eq $($Update.KBTitle)}).FullName
                if (!(Test-Path "$OSBuilderContent\Updates\*\$($Update.KBTitle)\$($Update.FileName)")) {
                    if ($DownloadUpdates.IsPresent) {
                        Write-Warning "Missing $($Update.KBTitle) ... Downloading"
                        Get-OSBuilderUpdates -FilterKBTitle "$($Update.KBTitle)" -Download -HideDetails
                    } else {
                        Write-Warning "Missing $($Update.KBTitle) ... Execution will be Disabled"
                        $Execute = $false
                    }
                }
            }
        }
        if ($CustomServicingStack.IsPresent) {
            Write-Host "$($UpdateCatServicing.FullName)"
        } else {
            foreach ($Update in $UpdateCatServicing) {
                $(Get-ChildItem -Path $OSBuilderContent\Updates -Directory -Recurse | Where-Object {$_.Name -eq $($Update.KBTitle)}).FullName
                if (!(Test-Path "$OSBuilderContent\Updates\*\$($Update.KBTitle)\$($Update.FileName)")) {
                    if ($DownloadUpdates.IsPresent) {
                        Write-Warning "Missing $($Update.KBTitle) ... Downloading"
                        Get-OSBuilderUpdates -FilterKBTitle "$($Update.KBTitle)" -Download -HideDetails
                    } else {
                        Write-Warning "Missing $($Update.KBTitle) ... Execution will be Disabled"
                        $Execute = $false
                    }
                }
            }
        }
        foreach ($Update in $UpdateCatSetup) {
            $(Get-ChildItem -Path $OSBuilderContent\Updates -Directory -Recurse | Where-Object {$_.Name -eq $($Update.KBTitle)}).FullName
            if (!(Test-Path "$OSBuilderContent\Updates\*\$($Update.KBTitle)\$($Update.FileName)")) {
                if ($DownloadUpdates.IsPresent) {
                    Write-Warning "Missing $($Update.KBTitle) ... Downloading"
                    Get-OSBuilderUpdates -FilterKBTitle "$($Update.KBTitle)" -Download -HideDetails
                } else {
                    Write-Warning "Missing $($Update.KBTitle) ... Execution will be Disabled"
                    $Execute = $false
                }
            }
        }
        #======================================================================================
        #	Task Information 18.9.28
        #======================================================================================
        Write-Host "===========================================================================" -ForegroundColor Yellow
        Write-Host "Task Information" -ForegroundColor Yellow
        Write-Host "-TaskName:			$TaskName" -ForegroundColor Cyan
        Write-Host "-TaskVersion:		$TaskVersion" -ForegroundColor Cyan
        Write-Host "-TaskType:			$TaskType" -ForegroundColor Cyan
        Write-Host "-Media Name:		$MediaName" -ForegroundColor Cyan
        Write-Host "-Media Path:		$MediaPath" -ForegroundColor Cyan
        Write-Host "-Build Name:		$BuildName" -ForegroundColor Cyan
        Write-Host "-Build Path:		$WorkingPath" -ForegroundColor Cyan
        Write-Host "-Disable Feature:" -ForegroundColor Cyan
        if ($DisableFeature){foreach ($item in $DisableFeature) {Write-Host $item}}
        Write-Host "-Drivers:" -ForegroundColor Cyan
        if ($Drivers){foreach ($item in $Drivers) {Write-Host $item}}
        Write-Host "-Enable Feature:" -ForegroundColor Cyan
        if ($EnableFeature){foreach ($item in $EnableFeature) {Write-Host $item}}
        Write-Host "-Enable NetFx3:		$EnableNetFX3" -ForegroundColor Cyan
        Write-Host "-Extra Files:" -ForegroundColor Cyan
        if ($ExtraFiles){foreach ($item in $ExtraFiles) {Write-Host $item}}
        Write-Host "-Features On Demand:" -ForegroundColor Cyan
        if ($FeaturesOnDemand){foreach ($item in $FeaturesOnDemand) {Write-Host $item}}
        Write-Host "-Language Features:" -ForegroundColor Cyan
        if ($LanguageFeatures){foreach ($item in $LanguageFeatures) {Write-Host $item}}
        Write-Host "-Language Interface Packs:" -ForegroundColor Cyan
        if ($LanguageInterfacePacks){foreach ($item in $LanguageInterfacePacks) {Write-Host $item}}
        Write-Host "-Language Packs:" -ForegroundColor Cyan
        if ($LanguagePacks){foreach ($item in $LanguagePacks) {Write-Host $item}}
        Write-Host "-Packages:" -ForegroundColor Cyan
        if ($Packages){foreach ($item in $Packages) {Write-Host $item}}
        Write-Host "-Remove Appx:" -ForegroundColor Cyan
        if ($RemoveAppx){foreach ($item in $RemoveAppx) {Write-Host $item}}
        Write-Host "-Remove Capability:" -ForegroundColor Cyan
        if ($RemoveCapability){foreach ($item in $RemoveCapability) {Write-Host $item}}
        Write-Host "-Remove Packages:" -ForegroundColor Cyan
        if ($RemovePackage){foreach ($item in $RemovePackage) {Write-Host $item}}
        Write-Host "-Scripts:" -ForegroundColor Cyan
        if ($Scripts){foreach ($item in $Scripts) {Write-Host $item}}
        Write-Host "-SetAllIntl (Language): $SetAllIntl" -ForegroundColor Cyan
        Write-Host "-SetInputLocale (Language): $SetInputLocale" -ForegroundColor Cyan
        Write-Host "-SetSKUIntlDefaults (Language): $SetSKUIntlDefaults" -ForegroundColor Cyan
        Write-Host "-SetSetupUILang (Language): $SetSetupUILang" -ForegroundColor Cyan
        Write-Host "-SetSysLocale (Language): $SetSysLocale" -ForegroundColor Cyan
        Write-Host "-SetUILang (Language): $SetUILang" -ForegroundColor Cyan
        Write-Host "-SetUILangFallback (Language): $SetUILangFallback" -ForegroundColor Cyan
        Write-Host "-SetUserLocale (Language): $SetUserLocale" -ForegroundColor Cyan
        Write-Host "-Start Layout:		$StartLayout" -ForegroundColor Cyan
        Write-Host "-Unattend:			$Unattend" -ForegroundColor Cyan
        Write-Host "-WinPE ADK Pkgs WinPE:" -ForegroundColor Cyan
        if ($WinPEADKPE){foreach ($item in $WinPEADKPE) {Write-Host $item}}
        Write-Host "-WinPE ADK Pkgs WinRE:" -ForegroundColor Cyan
        if ($WinPEADKRE){foreach ($item in $WinPEADKRE) {Write-Host $item}}
        Write-Host "-WinPE ADK Pkgs Setup:" -ForegroundColor Cyan
        if ($WinPEADKSetup){foreach ($item in $WinPEADKSetup) {Write-Host $item}}
        Write-Host "-WinPE DaRT:		$WinPEDaRT" -ForegroundColor Cyan
        Write-Host "-WinPE Drivers:		$WinPEDrivers" -ForegroundColor Cyan
        Write-Host "-WinPE Extra Files WinPE:" -ForegroundColor Cyan
        if ($WinPEExtraFilesPE){foreach ($item in $WinPEExtraFilesPE) {Write-Host $item}}
        Write-Host "-WinPE Extra Files WinRE:" -ForegroundColor Cyan
        if ($WinPEExtraFilesRE){foreach ($item in $WinPEExtraFilesRE) {Write-Host $item}}
        Write-Host "-WinPE Extra Files Setup:" -ForegroundColor Cyan
        if ($WinPEExtraFilesSetup){foreach ($item in $WinPEExtraFilesSetup) {Write-Host $item}}
        Write-Host "-WinPE Scripts WinPE:" -ForegroundColor Cyan
        if ($WinPEScriptsPE){foreach ($item in $WinPEScriptsPE) {Write-Host $item}}
        Write-Host "-WinPE Scripts WinRE:" -ForegroundColor Cyan
        if ($WinPEScriptsRE){foreach ($item in $WinPEScriptsRE) {Write-Host $item}}
        Write-Host "-WinPE Scripts Setup:" -ForegroundColor Cyan
        if ($WinPEScriptsSetup){foreach ($item in $WinPEScriptsSetup) {Write-Host $item}}
        #======================================================================================
        #	Execute 18.9.24
        #======================================================================================
        if ($Execute.IsPresent) {
            $Info = Join-Path $WorkingPath 'info'
            $LogsJS = Join-Path $Info 'json'
            $LogsXML = Join-Path $Info 'xml'
            $Logs =	Join-Path $Info "logs"
            if (!(Test-Path "$Info"))		{New-Item "$Info" -ItemType Directory -Force | Out-Null}
            if (!(Test-Path "$LogsJS"))		{New-Item "$LogsJS" -ItemType Directory -Force | Out-Null}
            if (!(Test-Path "$LogsXML"))	{New-Item "$LogsXML" -ItemType Directory -Force | Out-Null}
            if (!(Test-Path "$Logs"))		{New-Item "$Logs" -ItemType Directory -Force | Out-Null}

            $OS = Join-Path $WorkingPath "OS"
            $WinPE = Join-Path $WorkingPath "WinPE"
            if (!(Test-Path "$OS"))			{New-Item "$OS" -ItemType Directory -Force | Out-Null}
            if (!(Test-Path "$WinPE"))		{New-Item "$WinPE" -ItemType Directory -Force | Out-Null}

            $PEInfo = Join-Path $WinPE 'info'
            $PELogsJS = Join-Path $PEInfo 'json'
            $PELogsXML = Join-Path $PEInfo 'xml'
            $PELogs =	Join-Path $PEInfo "logs"

            if (!(Test-Path "$PEInfo"))		{New-Item "$PEInfo" -ItemType Directory -Force | Out-Null}
            if (!(Test-Path "$PELogsJS"))	{New-Item "$PELogsJS" -ItemType Directory -Force | Out-Null}
            if (!(Test-Path "$PELogsXML"))	{New-Item "$PELogsXML" -ItemType Directory -Force | Out-Null}
            if (!(Test-Path "$PELogs"))		{New-Item "$PELogs" -ItemType Directory -Force | Out-Null}

            $WimTemp = Join-Path $WorkingPath "WimTemp"
            if (!(Test-Path "$WimTemp"))	{New-Item "$WimTemp" -ItemType Directory -Force | Out-Null}
            #======================================================================================
            #   Start the Transcript 18.9.24
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Starting Transcript" -ForegroundColor Yellow
            $ScriptName = $MyInvocation.MyCommand.Name
            $LogName = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-$ScriptName.log"
            Start-Transcript -Path (Join-Path $Logs $LogName)
            #======================================================================================
            #   Display Build Paths 18.9.24
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Creating $BuildName" -ForegroundColor Yellow
            Write-Host "Working Path:       $WorkingPath" -ForegroundColor Yellow
            Write-Host "-Info:              $Info" -ForegroundColor Cyan
            Write-Host "-Logs:              $Logs" -ForegroundColor Cyan
            Write-Host "-OS:                $OS" -ForegroundColor Cyan
            Write-Host "-WinPE:             $WinPE" -ForegroundColor Cyan
            #======================================================================================
            #   Create Mount Directories 18.9.10
            #======================================================================================
            $MountDirectory = Join-Path $OSBuilderContent\Mount "os$((Get-Date).ToString('mmss'))"
            if ( ! (Test-Path "$MountDirectory")) {New-Item "$MountDirectory" -ItemType Directory -Force | Out-Null}
            $MountWinPE = Join-Path $OSBuilderContent\Mount "winpe$((Get-Date).ToString('mmss'))"
            if ( ! (Test-Path "$MountWinPE")) {New-Item "$MountWinPE" -ItemType Directory -Force | Out-Null}
            $MountSetup = Join-Path $OSBuilderContent\Mount "setup$((Get-Date).ToString('mmss'))"
            if ( ! (Test-Path "$MountSetup")) {New-Item "$MountSetup" -ItemType Directory -Force | Out-Null}
            $MountWinRE = Join-Path $OSBuilderContent\Mount "winre$((Get-Date).ToString('mmss'))"
            if ( ! (Test-Path "$MountWinRE")) {New-Item "$MountWinRE" -ItemType Directory -Force | Out-Null}
            #======================================================================================
            #	Copy OS 18.10.3
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Copy Operating System to $WorkingPath" -ForegroundColor Yellow
            Copy-Item -Path "$OSSourcePath\*" -Destination "$WorkingPath" -Exclude ('*.wim','*.iso') -Recurse -Force | Out-Null
            if (Test-Path "$WorkingPath\ISO") {Remove-Item -Path "$WorkingPath\ISO" -Force -Recurse | Out-Null}
            Copy-Item -Path "$OSSourcePath\OS\sources\install.wim" -Destination "$WimTemp\install.wim" -Force | Out-Null
            Copy-Item -Path "$OSSourcePath\WinPE\*.wim" -Destination "$WimTemp" -Exclude boot.wim -Force | Out-Null
            #======================================================================================
            #   Setup Update 18.9.24
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Setup Update" -ForegroundColor Yellow
            if (!($null -eq $UpdateCatSetup)) {
                foreach ($Update in $UpdateCatSetup) {
                    $UpdateCatSetup = $(Get-ChildItem -Path $OSBuilderContent\Updates -File -Recurse | Where-Object {$_.Name -eq $($Update.FileName)}).FullName
                    if (Test-Path "$UpdateCatSetup") {
                        expand.exe "$UpdateCatSetup" -F:*.* "$OS\Sources"
                    } else {
                        Write-Warning "Not Found: $UpdateCatSetup"
                    }
                }
            }
            #======================================================================================
            #   WinPE Phase: Mount 18.9.10
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: Mount Setup WIM" -ForegroundColor Yellow
            Mount-WindowsImage -ImagePath "$WimTemp\setup.wim" -Index 1 -Path "$MountSetup" -Optimize -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Mount-WindowsImage-setup.wim.log"
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: Mount WinPE WIM" -ForegroundColor Yellow
            Mount-WindowsImage -ImagePath "$WimTemp\winpe.wim" -Index 1 -Path "$MountWinPE" -Optimize -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Mount-WindowsImage-winpe.wim.log"
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: Mount WinRE WIM" -ForegroundColor Yellow
            Mount-WindowsImage -ImagePath "$WimTemp\winre.wim" -Index 1 -Path "$MountWinRE" -Optimize -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Mount-WindowsImage-winre.wim.log"
            #======================================================================================
            #   WinPE Phase: Servicing Update 18.10.3
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: Servicing Update" -ForegroundColor Yellow
            if (!($null -eq $UpdateCatServicing)) {
                if ($CustomServicingStack.IsPresent) {
                    Write-Host "setup.wim:"
                    Add-WindowsPackage -Path "$MountSetup" -PackagePath "$($UpdateCatServicing.FullName)" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateServicing-setup.wim.log"
                    Write-Host "winpe.wim:"
                    Add-WindowsPackage -Path "$MountWinPE" -PackagePath "$($UpdateCatServicing.FullName)" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateServicing-winpe.wim.log"
                    Write-Host "winre.wim:"
                    Add-WindowsPackage -Path "$MountWinRE" -PackagePath "$($UpdateCatServicing.FullName)" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateServicing-winre.wim.log"
                } else {
                    foreach ($Update in $UpdateCatServicing) {
                        $UpdateSSU = $(Get-ChildItem -Path $OSBuilderContent\Updates -Directory -Recurse | Where-Object {$_.Name -eq $($Update.KBTitle)}).FullName
                        if (Test-Path "$UpdateSSU") {
                            Write-Host "setup.wim: $UpdateSSU"
                            if (Get-WindowsPackage -Path "$MountSetup" | Where-Object {$_.PackageName -like "*$($Update.KBNumber)*"}) {
                                Write-Warning "KB$($Update.KBNumber) Installed ... Skipping Update"
                            } else {
                                Add-WindowsPackage -Path "$MountSetup" -PackagePath "$UpdateSSU" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateServicing-KB$($Update.KBNumber)-setup.wim.log"
                            }
                            Write-Host "winpe.wim: $UpdateSSU"
                            if (Get-WindowsPackage -Path "$MountWinPE" | Where-Object {$_.PackageName -like "*$($Update.KBNumber)*"}) {
                                Write-Warning "KB$($Update.KBNumber) Installed ... Skipping Update"
                            } else {
                                Add-WindowsPackage -Path "$MountWinPE" -PackagePath "$UpdateSSU" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateServicing-KB$($Update.KBNumber)-winpe.wim.log"
                            }
                            Write-Host "winre.wim: $UpdateSSU"
                            if (Get-WindowsPackage -Path "$MountWinRE" | Where-Object {$_.PackageName -like "*$($Update.KBNumber)*"}) {
                                Write-Warning "KB$($Update.KBNumber) Installed ... Skipping Update"
                            } else {
                                Add-WindowsPackage -Path "$MountWinRE" -PackagePath "$UpdateSSU" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateServicing-KB$($Update.KBNumber)-winre.wim.log"
                            }
                        } else {
                            Write-Warning "Not Found: $UpdateSSU"
                        }
                    }
                }
            }
            #======================================================================================
            #	WinPE Phase: Setup WIM ADK Optional Components 18.9.28
            #   OSBuild Only
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: Setup WIM ADK Optional Components" -ForegroundColor Yellow
            if ([string]::IsNullOrEmpty($WinPEADKSetup) -or [string]::IsNullOrWhiteSpace($WinPEADKSetup)) {
                # Do Nothing
            } else {
                foreach ($PackagePath in $WinPEADKSetup) {
                    if ($PackagePath -like "*WinPE-NetFx*") {
                        Write-Host "$OSBuilderContent\$PackagePath" -ForegroundColor Cyan
                        Add-WindowsPackage -PackagePath "$OSBuilderContent\$PackagePath" -Path "$MountSetup" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Add-WindowsPackage-setup.wim.log" | Out-Null
                    }
                }
                $WinPEADKSetup = $WinPEADKSetup | Where-Object {$_.Name -notlike "*WinPE-NetFx*"}
                foreach ($PackagePath in $WinPEADKSetup) {
                    if ($PackagePath -like "*WinPE-PowerShell*") {
                        Write-Host "$OSBuilderContent\PackagePath" -ForegroundColor Cyan
                        Add-WindowsPackage -PackagePath "$OSBuilderContent\$PackagePath" -Path "$MountSetup" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Add-WindowsPackage-setup.wim.log" | Out-Null
                    }
                }
                $WinPEADKSetup = $WinPEADKSetup | Where-Object {$_.Name -notlike "*WinPE-PowerShell*"}
                foreach ($PackagePath in $WinPEADKSetup) {
                    Write-Host "$OSBuilderContent\$PackagePath" -ForegroundColor Cyan
                    Add-WindowsPackage -PackagePath "$OSBuilderContent\$PackagePath" -Path "$MountSetup" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Add-WindowsPackage-setup.wim.log" | Out-Null
                }
            }
            #======================================================================================
            #	WinPE Phase: WinPE WIM ADK Optional Components 18.9.28
            #   OSBuild Only
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: WinPE WIM ADK Optional Components" -ForegroundColor Yellow
            if ([string]::IsNullOrEmpty($WinPEADKPE) -or [string]::IsNullOrWhiteSpace($WinPEADKPE)) {
                # Do Nothing
            } else {
                foreach ($PackagePath in $WinPEADKPE) {
                    if ($PackagePath -like "*WinPE-NetFx*") {
                        Write-Host "$OSBuilderContent\$PackagePath" -ForegroundColor Cyan
                        Add-WindowsPackage -PackagePath "$OSBuilderContent\$PackagePath" -Path "$MountWinPE" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Add-WindowsPackage-winpe.wim.log" | Out-Null
                    }
                }
                $WinPEADKPE = $WinPEADKPE | Where-Object {$_.Name -notlike "*WinPE-NetFx*"}
                foreach ($PackagePath in $WinPEADKPE) {
                    if ($PackagePath -like "*WinPE-PowerShell*") {
                        Write-Host "$OSBuilderContent\$PackagePath" -ForegroundColor Cyan
                        Add-WindowsPackage -PackagePath "$OSBuilderContent\$PackagePath" -Path "$MountWinPE" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Add-WindowsPackage-winpe.wim.log" | Out-Null
                    }
                }
                $WinPEADKPE = $WinPEADKPE | Where-Object {$_.Name -notlike "*WinPE-PowerShell*"}
                foreach ($PackagePath in $WinPEADKPE) {
                    Write-Host "$OSBuilderContent\$PackagePath" -ForegroundColor Cyan
                    Add-WindowsPackage -PackagePath "$OSBuilderContent\$PackagePath" -Path "$MountWinPE" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Add-WindowsPackage-winpe.wim.log" | Out-Null
                }
            }
            #======================================================================================
            #	WinPE Phase: WinRE WIM ADK Optional Components 18.9.28
            #   OSBuild Only
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: WinRE WIM ADK Optional Components" -ForegroundColor Yellow
            if ([string]::IsNullOrEmpty($WinPEADKRE) -or [string]::IsNullOrWhiteSpace($WinPEADKRE)) {
                # Do Nothing
            } else {
                foreach ($PackagePath in $WinPEADKRE) {
                    if ($PackagePath -like "*WinPE-NetFx*") {
                        Write-Host "$OSBuilderContent\$PackagePath" -ForegroundColor Cyan
                        Add-WindowsPackage -PackagePath "$OSBuilderContent\$PackagePath" -Path "$MountWinRE" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Add-WindowsPackage-winre.wim.log" | Out-Null
                    }
                }
                $WinPEADKRE = $WinPEADKRE | Where-Object {$_.Name -notlike "*WinPE-NetFx*"}
                foreach ($PackagePath in $WinPEADKRE) {
                    if ($PackagePath -like "*WinPE-PowerShell*") {
                        Write-Host "$OSBuilderContent\$PackagePath" -ForegroundColor Cyan
                        Add-WindowsPackage -PackagePath "$OSBuilderContent\$PackagePath" -Path "$MountWinRE" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Add-WindowsPackage-winre.wim.log" | Out-Null
                    }
                }
                $WinPEADKRE = $WinPEADKRE | Where-Object {$_.Name -notlike "*WinPE-PowerShell*"}
                foreach ($PackagePath in $WinPEADKRE) {
                    Write-Host "$OSBuilderContent\$PackagePath" -ForegroundColor Cyan
                    Add-WindowsPackage -PackagePath "$OSBuilderContent\$PackagePath" -Path "$MountWinRE" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Add-WindowsPackage-winre.wim.log" | Out-Null
                }
            }
            #======================================================================================
            #   WinPE Phase: Cumulative Update 18.10.3
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: Cumulative Update" -ForegroundColor Yellow
            if (!($null -eq $UpdateCatCumulative)) {
                if ($CustomCumulativeUpdate.IsPresent) {
                    Write-Host "setup.wim:"
                    Add-WindowsPackage -Path "$MountSetup" -PackagePath "$($UpdateCatCumulative.FullName)" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateCumulative-setup.wim.log"
                    Dism /Image:"$MountSetup" /Cleanup-Image /StartComponentCleanup /ResetBase /LogPath:"$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dism-Cleanup-Image-setup.wim.log"
                    Write-Host "winpe.wim:"
                    Add-WindowsPackage -Path "$MountWinPE" -PackagePath "$($UpdateCatCumulative.FullName)" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateCumulative-winpe.wim.log"
                    Dism /Image:"$MountWinPE" /Cleanup-Image /StartComponentCleanup /ResetBase /LogPath:"$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dism-Cleanup-Image-winpe.wim.log"
                    Write-Host "winre.wim:"
                    Add-WindowsPackage -Path "$MountWinRE" -PackagePath "$($UpdateCatCumulative.FullName)" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateCumulative-winre.wim.log"
                    Dism /Image:"$MountWinRE" /Cleanup-Image /StartComponentCleanup /ResetBase /LogPath:"$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dism-Cleanup-Image-winre.wim.log"
                } else {
                    foreach ($Update in $UpdateCatCumulative) {
                        $UpdateCU = $(Get-ChildItem -Path $OSBuilderContent\Updates -Directory -Recurse | Where-Object {$_.Name -eq $($Update.KBTitle)}).FullName
                        if (Test-Path "$UpdateCU") {
                            Write-Host "setup.wim: $UpdateCU"
                            #if (Get-WindowsPackage -Path "$MountSetup" | Where-Object {$_.PackageName -like "*$($Update.KBNumber)*"}) {}
                            $SessionsXmlSetup = "$MountSetup\Windows\Servicing\Sessions\Sessions.xml"
                            if (Test-Path $SessionsXmlSetup) {
                                [xml]$XmlDocument = Get-Content -Path $SessionsXmlSetup
                                if ($XmlDocument.Sessions.Session.Tasks.Phase.package | Where-Object {$_.Name -like "*$($Update.KBNumber)*" -and $_.targetState -eq 'Installed'}) {
                                    Write-Warning "KB$($Update.KBNumber) Installed ... Skipping Update"
                                } else {
                                    Add-WindowsPackage -Path "$MountSetup" -PackagePath "$UpdateCU" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateCumulative-KB$($Update.KBNumber)-setup.wim.log"
                                    Dism /Image:"$MountSetup" /Cleanup-Image /StartComponentCleanup /ResetBase /LogPath:"$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dism-Cleanup-Image-setup.wim.log"
                                }
                            } else {
                                Add-WindowsPackage -Path "$MountSetup" -PackagePath "$UpdateCU" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateCumulative-KB$($Update.KBNumber)-setup.wim.log"
                                Dism /Image:"$MountSetup" /Cleanup-Image /StartComponentCleanup /ResetBase /LogPath:"$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dism-Cleanup-Image-setup.wim.log"
                            }
                            Write-Host "winpe.wim: $UpdateCU"
                            #if (Get-WindowsPackage -Path "$MountWinPE" | Where-Object {$_.PackageName -like "*$($Update.KBNumber)*"}) {}
                            $SessionsXmlWinPE = "$MountWinPE\Windows\Servicing\Sessions\Sessions.xml"
                            if (Test-Path $SessionsXmlWinPE) {
                                [xml]$XmlDocument = Get-Content -Path $SessionsXmlWinPE
                                if ($XmlDocument.Sessions.Session.Tasks.Phase.package | Where-Object {$_.Name -like "*$($Update.KBNumber)*" -and $_.targetState -eq 'Installed'}) {
                                    Write-Warning "KB$($Update.KBNumber) Installed ... Skipping Update"
                                } else {
                                    Add-WindowsPackage -Path "$MountWinPE" -PackagePath "$UpdateCU" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateCumulative-KB$($Update.KBNumber)-winpe.wim.log"
                                    Dism /Image:"$MountWinPE" /Cleanup-Image /StartComponentCleanup /ResetBase /LogPath:"$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dism-Cleanup-Image-winpe.wim.log"
                                }
                            } else {
                                Add-WindowsPackage -Path "$MountWinPE" -PackagePath "$UpdateCU" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateCumulative-KB$($Update.KBNumber)-winpe.wim.log"
                                Dism /Image:"$MountWinPE" /Cleanup-Image /StartComponentCleanup /ResetBase /LogPath:"$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dism-Cleanup-Image-winpe.wim.log"
                            }
                            Write-Host "winre.wim: $UpdateCU"
                            #if (Get-WindowsPackage -Path "$MountWinRE" | Where-Object {$_.PackageName -like "*$($Update.KBNumber)*"}) {}
                            $SessionsXmlWinRE = "$MountWinRE\Windows\Servicing\Sessions\Sessions.xml"
                            if (Test-Path $SessionsXmlWinRE) {
                                [xml]$XmlDocument = Get-Content -Path $SessionsXmlWinRE
                                if ($XmlDocument.Sessions.Session.Tasks.Phase.package | Where-Object {$_.Name -like "*$($Update.KBNumber)*" -and $_.targetState -eq 'Installed'}) {
                                    Write-Warning "KB$($Update.KBNumber) Installed ... Skipping Update"
                                } else {
                                    Add-WindowsPackage -Path "$MountWinRE" -PackagePath "$UpdateCU" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateCumulative-KB$($Update.KBNumber)-winre.wim.log"
                                    Dism /Image:"$MountWinRE" /Cleanup-Image /StartComponentCleanup /ResetBase /LogPath:"$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dism-Cleanup-Image-winre.wim.log"
                                }
                            } else {
                                Add-WindowsPackage -Path "$MountWinRE" -PackagePath "$UpdateCU" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateCumulative-KB$($Update.KBNumber)-winre.wim.log"
                                Dism /Image:"$MountWinRE" /Cleanup-Image /StartComponentCleanup /ResetBase /LogPath:"$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dism-Cleanup-Image-winre.wim.log"
                            }
                        } else {
                            Write-Warning "Not Found: $UpdateCU"
                        }
                    }
                }
            }
            #======================================================================================
            #	WinPE Phase: WinPE DaRT 18.9.28
            #   OSBuild Only
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: Microsoft DaRT" -ForegroundColor Yellow
            if ($WinPEDaRT) {
                if ([string]::IsNullOrEmpty($WinPEDaRT) -or [string]::IsNullOrWhiteSpace($WinPEDaRT)) {Write-Warning "Skipping WinPE DaRT"}
                elseif (Test-Path "$OSBuilderContent\$WinPEDaRT") {
                    #======================================================================================
                    if (Test-Path $(Join-Path $(Split-Path "$OSBuilderContent\$WinPEDart") 'DartConfig.dat')) {
                        Write-Host "winpe.wim: $OSBuilderContent\$WinPEDaRT"
                        expand.exe "$OSBuilderContent\$WinPEDaRT" -F:*.* "$MountWinPE"
                        if (Test-Path "$MountWinPE\Windows\System32\winpeshl.ini") {Remove-Item -Path "$MountWinPE\Windows\System32\winpeshl.ini" -Force}
                        #======================================================================================
                        Write-Host "setup.wim: $OSBuilderContent\$WinPEDaRT"
                        expand.exe "$OSBuilderContent\$WinPEDaRT" -F:*.* "$MountSetup"
                        if (Test-Path "$MountSetup\Windows\System32\winpeshl.ini") {Remove-Item -Path "$MountSetup\Windows\System32\winpeshl.ini" -Force}
                        #======================================================================================
                        Write-Host "winre.wim: $OSBuilderContent\$WinPEDaRT"
                        expand.exe "$OSBuilderContent\$WinPEDaRT" -F:*.* "$MountWinRE"
                        (Get-Content "$MountWinRE\Windows\System32\winpeshl.ini") | ForEach-Object {$_ -replace '-prompt','-network'} | Out-File "$MountWinRE\Windows\System32\winpeshl.ini"
                        #======================================================================================
                        Write-Host "winpe.wim: Copying DartConfig.dat to $MountWinPE\Windows\System32\DartConfig.dat"
                        Copy-Item -Path $(Join-Path $(Split-Path "$OSBuilderContent\$WinPEDart") 'DartConfig.dat') -Destination "$MountWinPE\Windows\System32\DartConfig.dat" -Force | Out-Null
                        #======================================================================================
                        Write-Host "setup.wim: Copying DartConfig.dat to $MountSetup\Windows\System32\DartConfig.dat"
                        Copy-Item -Path $(Join-Path $(Split-Path "$OSBuilderContent\$WinPEDart") 'DartConfig.dat') -Destination "$MountSetup\Windows\System32\DartConfig.dat" -Force | Out-Null
                        #======================================================================================
                        Write-Host "winre.wim: Copying DartConfig.dat to $MountWinRE\Windows\System32\DartConfig.dat"
                        Copy-Item -Path $(Join-Path $(Split-Path "$OSBuilderContent\$WinPEDart") 'DartConfig.dat') -Destination "$MountWinRE\Windows\System32\DartConfig.dat" -Force | Out-Null
                        #======================================================================================
                    } elseif (Test-Path $(Join-Path $(Split-Path $WinPEDart) 'DartConfig8.dat')) {
                        Write-Host "winpe.wim: $OSBuilderContent\$WinPEDaRT"
                        expand.exe "$OSBuilderContent\$WinPEDaRT" -F:*.* "$MountWinPE"
                        if (Test-Path "$MountSetup\Windows\System32\winpeshl.ini") {Remove-Item -Path "$MountSetup\Windows\System32\winpeshl.ini" -Force}
                        #======================================================================================
                        Write-Host "setup.wim: $OSBuilderContent\$WinPEDaRT"
                        expand.exe "$OSBuilderContent\$WinPEDaRT" -F:*.* "$MountSetup"
                        if (Test-Path "$MountSetup\Windows\System32\winpeshl.ini") {Remove-Item -Path "$MountSetup\Windows\System32\winpeshl.ini" -Force}
                        #======================================================================================
                        Write-Host "winre.wim: $OSBuilderContent\$WinPEDaRT"
                        expand.exe "$OSBuilderContent\$WinPEDaRT" -F:*.* "$MountWinRE"
                        (Get-Content "$MountWinRE\Windows\System32\winpeshl.ini") | ForEach-Object {$_ -replace '-prompt','-network'} | Out-File "$MountWinRE\Windows\System32\winpeshl.ini"
                        #======================================================================================
                        Write-Host "winpe.wim: Copying DartConfig8.dat to $MountWinPE\Windows\System32\DartConfig.dat"
                        Copy-Item -Path $(Join-Path $(Split-Path "$OSBuilderContent\$WinPEDart") 'DartConfig8.dat') -Destination "$MountWinPE\Windows\System32\DartConfig.dat" -Force | Out-Null
                        #======================================================================================
                        Write-Host "winpe.wim: Copying DartConfig8.dat to $MountSetup\Windows\System32\DartConfig.dat"
                        Copy-Item -Path $(Join-Path $(Split-Path "$OSBuilderContent\$WinPEDart") 'DartConfig8.dat') -Destination "$MountSetup\Windows\System32\DartConfig.dat" -Force | Out-Null
                        #======================================================================================
                        Write-Host "winre.wim: Copying DartConfig8.dat to $MountWinRE\Windows\System32\DartConfig.dat"
                        Copy-Item -Path $(Join-Path $(Split-Path "$OSBuilderContent\$WinPEDart") 'DartConfig8.dat') -Destination "$MountWinRE\Windows\System32\DartConfig.dat" -Force | Out-Null
                        #======================================================================================
                    }
                    #======================================================================================
                } else {Write-Warning "WinPE DaRT do not exist in $OSBuilderContent\$WinPEDart"}
            }
            #======================================================================================
            #	WinPE Phase: Extra Files 18.9.28
            #   OSBuild Only
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: Setup WIM Extra Files" -ForegroundColor Yellow
            foreach ($ExtraFile in $WinPEExtraFilesSetup) {robocopy "$OSBuilderContent\$ExtraFile" "$MountSetup" *.* /e /ndl /xx /b /np /ts /tee /r:0 /w:0 /log:"$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-ExtraFiles-setup.wim.log"}
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: WinPE WIM Extra Files" -ForegroundColor Yellow
            foreach ($ExtraFile in $WinPEExtraFilesPE) {robocopy "$OSBuilderContent\$ExtraFile" "$MountWinPE" *.* /e /ndl /xx /b /np /ts /tee /r:0 /w:0 /log:"$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-ExtraFiles-winpe.wim.log"}
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: WinRE WIM Extra Files" -ForegroundColor Yellow
            foreach ($ExtraFile in $WinPEExtraFilesRE) {robocopy "$OSBuilderContent\$ExtraFile" "$MountWinRE" *.* /e /ndl /xx /b /np /ts /tee /r:0 /w:0 /log:"$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-ExtraFiles-winre.wim.log"}
            #======================================================================================
            #	WinPE Phase: Drivers 18.9.28
            #   OSBuild Only
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: Setup WIM Drivers" -ForegroundColor Yellow
            foreach ($WinPEDriver in $WinPEDrivers) {
                Write-Host "$OSBuilderContent\$WinPEDriver" -ForegroundColor Cyan
                Add-WindowsDriver -Path "$MountSetup" -Driver "$OSBuilderContent\$WinPEDriver" -Recurse -ForceUnsigned -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Add-WindowsDriver-setup.wim.log" | Out-Null
            }
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: WinPE WIM Drivers" -ForegroundColor Yellow
            foreach ($WinPEDriver in $WinPEDrivers) {
                Write-Host "$OSBuilderContent\$WinPEDriver" -ForegroundColor Cyan
                Add-WindowsDriver -Path "$MountWinPE" -Driver "$OSBuilderContent\$WinPEDriver" -Recurse -ForceUnsigned -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Add-WindowsDriver-winpe.wim.log" | Out-Null
            }
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: WinRE WIM Drivers" -ForegroundColor Yellow
            foreach ($WinPEDriver in $WinPEDrivers) {
                Write-Host "$OSBuilderContent\$WinPEDriver" -ForegroundColor Cyan
                Add-WindowsDriver -Path "$MountWinRE" -Driver "$OSBuilderContent\$WinPEDriver" -Recurse -ForceUnsigned -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Add-WindowsDriver-winre.wim.log" | Out-Null
            }
            #======================================================================================
            #   WinPE Phase: PowerShell Scripts 18.9.28
            #   OSBuild Only
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: Setup WIM PowerShell Scripts" -ForegroundColor Yellow
            foreach ($PSWimScript in $WinPEScriptsSetup) {
                if (Test-Path "$OSBuilderContent\$PSWimScript") {
                    Write-Host "Setup WIM: $OSBuilderContent\$PSWimScript" -ForegroundColor Cyan
                    Invoke-Expression "& '$OSBuilderContent\$PSWimScript'"
                }
            }
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: WinPE WIM PowerShell Scripts" -ForegroundColor Yellow
            foreach ($PSWimScript in $WinPEScriptsPE) {
                if (Test-Path "$OSBuilderContent\$PSWimScript") {
                    Write-Host "WinPE WIM: $OSBuilderContent\$PSWimScript" -ForegroundColor Cyan
                    Invoke-Expression "& '$OSBuilderContent\$PSWimScript'"
                }
            }
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: WinRE WIM PowerShell Scripts" -ForegroundColor Yellow
            foreach ($PSWimScript in $WinPEScriptsRE) {
                if (Test-Path "$OSBuilderContent\$PSWimScript") {
                    Write-Host "WinRE WIM: $OSBuilderContent\$PSWimScript" -ForegroundColor Cyan
                    Invoke-Expression "& '$OSBuilderContent\$PSWimScript'"
                }
            }
            #======================================================================================
            #   WinPE Phase: Update Media Sources 18.10.2
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: Updating Media Sources with Setup.wim" -ForegroundColor Yellow
            #[void](Read-Host 'Press Enter to Continue')
            robocopy "$MountSetup\sources" "$OS\sources" setup.exe /ndl /xo /xx /xl /b /np /ts /tee /r:0 /w:0 /log:"$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Robocopy-setup.wim-MediaSources.log"
            robocopy "$MountSetup\sources" "$OS\sources" setuphost.exe /ndl /xo /xx /xl /b /np /ts /tee /r:0 /w:0 /log:"$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Robocopy-setup.wim-MediaSources.log"
            #======================================================================================
            #   WinPE Mounted Package Inventory 18.9.10
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: Exporting Package Inventory" -ForegroundColor Yellow
            Write-Host "$PEInfo\setup-WindowsPackage.txt"
            $GetWindowsPackage = Get-WindowsPackage -Path "$MountSetup"
            $GetWindowsPackage | Out-File "$PEInfo\setup-WindowsPackage.txt"
            $GetWindowsPackage | Out-File "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsPackage-setup.wim.txt"
            $GetWindowsPackage | Export-Clixml -Path "$PELogsXML\Get-WindowsPackage-setup.wim.xml"
            $GetWindowsPackage | Export-Clixml -Path "$PELogsXML\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsPackage-setup.wim.xml"
            $GetWindowsPackage | ConvertTo-Json | Out-File "$PELogsJS\Get-WindowsPackage-setup.wim.json"
            $GetWindowsPackage | ConvertTo-Json | Out-File "$PELogsJS\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsPackage-setup.wim.json"

            Write-Host "$PEInfo\winpe-WindowsPackage.txt"
            $GetWindowsPackage = Get-WindowsPackage -Path "$MountWinPE"
            $GetWindowsPackage | Out-File "$PEInfo\winpe-WindowsPackage.txt"
            $GetWindowsPackage | Out-File "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsPackage-winpe.wim.txt"
            $GetWindowsPackage | Export-Clixml -Path "$PELogsXML\Get-WindowsPackage-winpe.wim.xml"
            $GetWindowsPackage | Export-Clixml -Path "$PELogsXML\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsPackage-winpe.wim.xml"
            $GetWindowsPackage | ConvertTo-Json | Out-File "$PELogsJS\Get-WindowsPackage-winpe.wim.json"
            $GetWindowsPackage | ConvertTo-Json | Out-File "$PELogsJS\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsPackage-winpe.wim.json"

            Write-Host "$PEInfo\winre-WindowsPackage.txt"
            $GetWindowsPackage = Get-WindowsPackage -Path "$MountWinRE"
            $GetWindowsPackage | Out-File "$PEInfo\winre-WindowsPackage.txt"
            $GetWindowsPackage | Out-File "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsPackage-winre.wim.txt"
            $GetWindowsPackage | Export-Clixml -Path "$PELogsXML\Get-WindowsPackage-winre.wim.xml"
            $GetWindowsPackage | Export-Clixml -Path "$PELogsXML\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsPackage-winre.wim.xml"
            $GetWindowsPackage | ConvertTo-Json | Out-File "$PELogsJS\Get-WindowsPackage-winre.wim.json"
            $GetWindowsPackage | ConvertTo-Json | Out-File "$PELogsJS\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsPackage-winre.wim.json"
            #======================================================================================
            #   WinPE Dismount and Save 18.9.10
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: Dismount and Save" -ForegroundColor Yellow
            if ($PromptBeforeDismountWinPE.IsPresent){[void](Read-Host 'Press Enter to Continue')}
            Write-Host "setup.wim: Dismount and Save $MountSetup"
            Dismount-WindowsImage -Path "$MountSetup" -Save -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dismount-WindowsImage-setup.wim.log" | Out-Null
            Write-Host "winpe.wim: Dismount and Save $MountWinPE"
            Dismount-WindowsImage -Path "$MountWinPE" -Save -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dismount-WindowsImage-winpe.wim.log" | Out-Null
            Write-Host "winre.wim: Dismount and Save $MountWinRE"
            Dismount-WindowsImage -Path "$MountWinRE" -Save -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dismount-WindowsImage-winre.wim.log" | Out-Null
            #======================================================================================
            #   Export WinPE 18.9.10
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: Exporting WinPE WIMs" -ForegroundColor Yellow
            Write-Host "setup.wim: Exporting to $WinPE\setup.wim"
            Export-WindowsImage -SourceImagePath "$WimTemp\setup.wim" -SourceIndex 1 -DestinationImagePath "$WinPE\setup.wim" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Export-WindowsImage-setup.wim.log" | Out-Null
            Write-Host "winpe.wim: Exporting to $WinPE\winpe.wim"
            Export-WindowsImage -SourceImagePath "$WimTemp\winpe.wim" -SourceIndex 1 -DestinationImagePath "$WinPE\winpe.wim" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Export-WindowsImage-winpe.wim.log" | Out-Null
            Write-Host "winre.wim: Exporting to $WinPE\winre.wim"
            Export-WindowsImage -SourceImagePath "$WimTemp\winre.wim" -SourceIndex 1 -DestinationImagePath "$WinPE\winre.wim" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Export-WindowsImage-winre.wim.log" | Out-Null
            #======================================================================================
            #   Rebuild Boot.wim 18.9.10
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: Rebuilding Boot.wim" -ForegroundColor Yellow
            Write-Host "Rebuilding updated Boot.wim Index 1 at $WinPE\boot.wim"
            Export-WindowsImage -SourceImagePath "$WimTemp\winpe.wim" -SourceIndex 1 -DestinationImagePath "$WinPE\boot.wim" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Export-WindowsImage-boot.wim.log" | Out-Null
            Write-Host "Rebuilding updated Boot.wim Index 2 at $WinPE\boot.wim Bootable"
            Export-WindowsImage -SourceImagePath "$WimTemp\setup.wim" -SourceIndex 1 -DestinationImagePath "$WinPE\boot.wim" -Setbootable -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Export-WindowsImage-boot.wim.log" | Out-Null
            Write-Host "Copying Boot.wim to $OS\sources\boot.wim"
            Copy-Item -Path "$WinPE\boot.wim" -Destination "$OS\sources\boot.wim" -Force | Out-Null
            #======================================================================================
            #   Mount Install.wim 18.9.10
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Install.wim Phase: Mounting Operating System" -ForegroundColor Yellow
            Write-Host $MountDirectory
            Mount-WindowsImage -ImagePath "$WimTemp\install.wim" -Index 1 -Path "$MountDirectory" -Optimize -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Mount-WindowsImage.log"
            #======================================================================================
            #   Get Registry and UBR 18.9.20
            #======================================================================================
            reg LOAD 'HKLM\OSMedia' "$MountDirectory\Windows\System32\Config\SOFTWARE"
            $RegCurrentVersion = Get-ItemProperty -Path 'HKLM:\OSMedia\Microsoft\Windows NT\CurrentVersion'
            reg UNLOAD 'HKLM\OSMedia'

            $OSVersionNumber = $null
            $OSVersionNumber = $($RegCurrentVersion.ReleaseId)
            $RegCurrentVersionUBR = $($RegCurrentVersion.UBR)
            $UBR = "$OSBuild.$RegCurrentVersionUBR"
            #======================================================================================
            #   Export RegCurrentVersion 18.9.20
            #======================================================================================
            $RegCurrentVersion | Out-File "$Info\CurrentVersion.txt"
            $RegCurrentVersion | Out-File "$WorkingPath\CurrentVersion.txt"
            $RegCurrentVersion | Out-File "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-CurrentVersion.txt"
            $RegCurrentVersion | Export-Clixml -Path "$LogsXML\CurrentVersion.xml"
            $RegCurrentVersion | Export-Clixml -Path "$LogsXML\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-CurrentVersion.xml"
            $RegCurrentVersion | ConvertTo-Json | Out-File "$LogsJS\CurrentVersion.json"
            $RegCurrentVersion | ConvertTo-Json | Out-File "$LogsJS\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-CurrentVersion.json"
            #======================================================================================
            #   Replace WinRE 18.9.10
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Install.wim Phase: Replacing WinRE.wim" -ForegroundColor Yellow
            Write-Host "Removing existing $MountDirectory\Windows\System32\Recovery\winre.wim"
            if (Test-Path "$MountDirectory\Windows\System32\Recovery\winre.wim") {
                Remove-Item -Path "$MountDirectory\Windows\System32\Recovery\winre.wim" -Force
            }
            #======================================================================================
            Write-Host "Copying WinRE.wim to $MountDirectory\Windows\System32\Recovery\winre.wim"
            Copy-Item -Path "$WinPE\winre.wim" -Destination "$MountDirectory\Windows\System32\Recovery\winre.wim" -Force | Out-Null
            #======================================================================================
            Write-Host "Generating WinRE.wim info"
            $GetWindowsImage = Get-WindowsImage -ImagePath "$WinPE\winre.wim" -Index 1 | Select-Object -Property *
            $GetWindowsImage | Out-File "$PEInfo\winre.txt"
            (Get-Content "$PEInfo\winre.txt") | Where-Object {$_.Trim(" `t")} | Set-Content "$PEInfo\winre.txt"
            $GetWindowsImage | Out-File "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsImage-winre.wim.txt"
            $GetWindowsImage | Export-Clixml -Path "$PELogsXML\Get-WindowsImage-winre.wim.xml"
            $GetWindowsImage | Export-Clixml -Path "$PELogsXML\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsImage-winre.wim.xml"
            $GetWindowsImage | ConvertTo-Json | Out-File "$PELogsJS\Get-WindowsImage-winre.wim.json"
            $GetWindowsImage | ConvertTo-Json | Out-File "$PELogsJS\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsImage-winre.wim.json"
            #======================================================================================
            #   Install.wim Servicing Update 18.10.3
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Install.wim Phase: Servicing Update" -ForegroundColor Yellow
            if (!($null -eq $UpdateCatServicing)) {
                if ($CustomServicingStack.IsPresent) {
                    Write-Host "install.wim:"
                    Add-WindowsPackage -Path "$MountDirectory" -PackagePath "$($UpdateCatServicing.FullName)" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateServicing-install.wim.log"
                } else {
                    foreach ($Update in $UpdateCatServicing) {
                        $UpdateSSU = $(Get-ChildItem -Path $OSBuilderContent\Updates -Directory -Recurse | Where-Object {$_.Name -eq $($Update.KBTitle)}).FullName
                        if (Test-Path "$UpdateSSU") {
                            Write-Host "install.wim: $UpdateSSU"
                            if (Get-WindowsPackage -Path "$MountDirectory" | Where-Object {$_.PackageName -like "*$($Update.KBNumber)*"}) {
                                Write-Warning "KB$($Update.KBNumber) Installed ... Skipping Update"
                            } else {
                                Add-WindowsPackage -Path "$MountDirectory" -PackagePath "$UpdateSSU" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateServicing-KB$($Update.KBNumber)-install.wim.log"
                            }
                        } else {
                            Write-Warning "Not Found: $UpdateSSU"
                        }
                    }
                }
            }
            #======================================================================================
            #   Install.wim Component Update 18.10.3
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Install.wim Phase: Component Update" -ForegroundColor Yellow
            if (!($null -eq $UpdateCatComponent)) {
                foreach ($Update in $UpdateCatComponent) {
                    $UpdateComp = $(Get-ChildItem -Path $OSBuilderContent\Updates -Directory -Recurse | Where-Object {$_.Name -eq $($Update.KBTitle)}).FullName
                    if (Test-Path "$UpdateComp") {
                        Write-Host "install.wim: $UpdateComp"
                        if (Get-WindowsPackage -Path "$MountDirectory" | Where-Object {$_.PackageName -like "*$($Update.KBNumber)*"}) {
                            Write-Warning "KB$($Update.KBNumber) Installed ... Skipping Update"
                        } else {
                            Add-WindowsPackage -Path "$MountDirectory" -PackagePath "$UpdateComp" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateComponent-KB$($Update.KBNumber)-install.wim.log"
                        }
                    } else {
                        Write-Warning "Not Found: $UpdateComp"
                    }
                }
            }
            #======================================================================================
            #   Get UBR (Pre Windows Updates) 18.9.20
            #======================================================================================
            $UBRPre = $UBR
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Install.wim Phase: Update Build Revision $UBRPre (Pre-Windows Updates)"	-ForegroundColor Yellow
            #======================================================================================
            #   Install.wim Cumulative Update 18.10.3
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Install.wim Phase: Cumulative Update" -ForegroundColor Yellow
            if (!($null -eq $UpdateCatCumulative)) {
                if ($CustomCumulativeUpdate.IsPresent) {
                    Add-WindowsPackage -Path "$MountDirectory" -PackagePath "$($UpdateCatCumulative.FullName)" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateCumulative-install.wim.log"
                } else {
                    foreach ($Update in $UpdateCatCumulative) {
                        $UpdateCU = $(Get-ChildItem -Path $OSBuilderContent\Updates -Directory -Recurse | Where-Object {$_.Name -eq $($Update.KBTitle)}).FullName
                        if (Test-Path "$UpdateCU") {
                            Write-Host "install.wim: $UpdateCU"
                            $SessionsXmlInstall = "$MountDirectory\Windows\Servicing\Sessions\Sessions.xml"
                            if (Test-Path $SessionsXmlInstall) {
                                [xml]$XmlDocument = Get-Content -Path $SessionsXmlInstall
                                if ($XmlDocument.Sessions.Session.Tasks.Phase.package | Where-Object {$_.Name -like "*$($Update.KBNumber)*" -and $_.targetState -eq 'Installed'}) {
                                    Write-Warning "KB$($Update.KBNumber) Installed ... Skipping Update"
                                } else {
                                    Add-WindowsPackage -Path "$MountDirectory" -PackagePath "$UpdateCU" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateCumulative-KB$($Update.KBNumber)-install.wim.log"
                                }
                            } else {
                                Add-WindowsPackage -Path "$MountDirectory" -PackagePath "$UpdateCU" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateCumulative-KB$($Update.KBNumber)-install.wim.log"
                            }
                        } else {
                            Write-Warning "Not Found: $UpdateCU"
                        }
                    }
                }
            }
            #======================================================================================
            #	Get Registry and UBR 18.9.20
            #======================================================================================
            reg LOAD 'HKLM\OSMedia' "$MountDirectory\Windows\System32\Config\SOFTWARE"
            $RegCurrentVersion = Get-ItemProperty -Path 'HKLM:\OSMedia\Microsoft\Windows NT\CurrentVersion'
            reg UNLOAD 'HKLM\OSMedia'

            $OSVersionNumber = $null
            $OSVersionNumber = $($RegCurrentVersion.ReleaseId)
            $RegCurrentVersionUBR = $($RegCurrentVersion.UBR)
            $UBR = "$OSBuild.$RegCurrentVersionUBR"
            #======================================================================================
            #   Export RegCurrentVersion 18.9.20
            #======================================================================================
            $RegCurrentVersion | Out-File "$Info\CurrentVersion.txt"
            $RegCurrentVersion | Out-File "$WorkingPath\CurrentVersion.txt"
            $RegCurrentVersion | Out-File "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-CurrentVersion.txt"
            $RegCurrentVersion | Export-Clixml -Path "$LogsXML\CurrentVersion.xml"
            $RegCurrentVersion | Export-Clixml -Path "$LogsXML\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-CurrentVersion.xml"
            $RegCurrentVersion | ConvertTo-Json | Out-File "$LogsJS\CurrentVersion.json"
            $RegCurrentVersion | ConvertTo-Json | Out-File "$LogsJS\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-CurrentVersion.json"
            #======================================================================================
            #   Get UBR (Post Windows Updates) 18.9.20
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Install.wim Phase: Update Build Revision $UBR (Post-Windows Updates)"	-ForegroundColor Yellow
            #======================================================================================
            #   Install.wim Adobe Update 18.9.24
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Install.wim Phase: Adobe Update" -ForegroundColor Yellow
            if (!($null -eq $UpdateCatAdobe)) {
                foreach ($Update in $UpdateCatAdobe) {
                    $UpdateA = $(Get-ChildItem -Path $OSBuilderContent\Updates -Directory -Recurse | Where-Object {$_.Name -eq $($Update.KBTitle)}).FullName
                    if (Test-Path "$UpdateA") {
                        Write-Host "install.wim: $UpdateA"
                        if (Get-WindowsPackage -Path "$MountDirectory" | Where-Object {$_.PackageName -like "*$($Update.KBNumber)*"}) {
                            Write-Warning "KB$($Update.KBNumber) Installed ... Skipping Update"
                        } else {
                            Add-WindowsPackage -Path "$MountDirectory" -PackagePath "$UpdateA" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateAdobe-KB$($Update.KBNumber)-install.wim.log"
                        }
                    } else {
                        Write-Warning "Not Found: $UpdateA"
                    }
                }
            }
            #======================================================================================
            #   Install.wim Image Cleanup 18.9.10
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Install.wim Phase: Windows Image Cleanup" -ForegroundColor Yellow
            if ($(Get-WindowsCapability -Path $MountDirectory | Where-Object {$_.state -eq "*pending*"})) {
                Write-Warning "Cannot run WindowsImage Cleanup on a WIM with Pending Installations"
            } else {
                Write-Host "Performing Image Cleanup on $MountDirectory"
                Dism /Image:"$MountDirectory" /Cleanup-Image /StartComponentCleanup /ResetBase /LogPath:"$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dism-Cleanup-Image.log"
            }
            #======================================================================================
            #   OSBuild Language Packs 18.9.24
            #   OSBuild Only
            #======================================================================================
            if ($LanguagePacks) {
                Write-Host "===========================================================================" -ForegroundColor Yellow
                Write-Host "Install.wim Phase: Language Packs"	-ForegroundColor Yellow
                foreach ($Update in $LanguagePacks) {
                    if (Test-Path "$OSBuilderContent\$Update") {
                        Write-Host "$OSBuilderContent\$Update"
                        Add-WindowsPackage -Path "$MountDirectory" -PackagePath "$OSBuilderContent\$Update" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-LanguagePack-install.wim.log"
                    } else {
                        Write-Warning "Not Found: $OSBuilderContent\$Update"
                    }
                }
            }
            if ($LanguageInterfacePacks) {
                Write-Host "===========================================================================" -ForegroundColor Yellow
                Write-Host "Install.wim Phase: Language Interface Packs"	-ForegroundColor Yellow
                foreach ($Update in $LanguageInterfacePacks) {
                    if (Test-Path "$OSBuilderContent\$Update") {
                        Write-Host "$OSBuilderContent\$Update"
                        Add-WindowsPackage -Path "$MountDirectory" -PackagePath "$OSBuilderContent\$Update" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-LanguageInterfacePack-install.wim.log"
                    } else {
                        Write-Warning "Not Found: $OSBuilderContent\$Update"
                    }
                }
            }
            if ($LanguageFeatures) {
                Write-Host "===========================================================================" -ForegroundColor Yellow
                Write-Host "Install.wim Phase: Language Features"	-ForegroundColor Yellow
                foreach ($Update in $LanguageFeatures | Where-Object {$_ -notlike "*Speech*"}) {
                    if (Test-Path "$OSBuilderContent\$Update") {
                        Write-Host "$OSBuilderContent\$Update"
                        Add-WindowsPackage -Path "$MountDirectory" -PackagePath "$OSBuilderContent\$Update" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-LanguageFeatures-install.wim.log"
                    }
                }
                foreach ($Update in $LanguageFeatures | Where-Object {$_ -like "*TextToSpeech*"}) {
                    if (Test-Path "$OSBuilderContent\$Update") {
                        Write-Host "$OSBuilderContent\$Update"
                        Add-WindowsPackage -Path "$MountDirectory" -PackagePath "$OSBuilderContent\$Update" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-LanguageFeatures-install.wim.log"
                    }
                }
                foreach ($Update in $LanguageFeatures | Where-Object {$_ -like "*Speech*" -and $_ -notlike "*TextToSpeech*"}) {
                    if (Test-Path "$OSBuilderContent\$Update") {
                        Write-Host "$OSBuilderContent\$Update"
                        Add-WindowsPackage -Path "$MountDirectory" -PackagePath "$OSBuilderContent\$Update" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-LanguageFeatures-install.wim.log"
                    }
                }
            }
            #======================================================================================
            #	Install.wim Phase: Reapply Cumulative Update 18.9.24
            #======================================================================================
            if ($LanguagePacks -or $LanguageInterfacePacks -or $LanguageFeatures) {
                #======================================================================================
                #	Install.wim Phase: Generating Langini 18.9.24
                #======================================================================================
                Write-Host "===========================================================================" -ForegroundColor Yellow
                Write-Host "Install.wim Phase: Generating Updated Langini" -ForegroundColor Yellow
                Dism /Image:"$MountDirectory" /Gen-LangIni /Distribution:"$OS" /LogPath:"$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dism-gen-langini.log"
                #======================================================================================
                #	Install.wim Phase: Set Language Settings 18.9.25
                #======================================================================================
                if ($SetAllIntl) {
                    Write-Host "===========================================================================" -ForegroundColor Yellow
                    Write-Host "Install.wim Phase: SetAllIntl" -ForegroundColor Yellow
                    Dism /Image:"$MountDirectory" /Set-AllIntl:"$SetAllIntl" /LogPath:"$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dism-SetAllIntl.log"
                }
                if ($SetInputLocale) {
                    Write-Host "===========================================================================" -ForegroundColor Yellow
                    Write-Host "Install.wim Phase: SetInputLocale" -ForegroundColor Yellow
                    Dism /Image:"$MountDirectory" /Set-InputLocale:"$SetInputLocale" /LogPath:"$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dism-SetInputLocale.log"
                }
                if ($SetSKUIntlDefaults) {
                    Write-Host "===========================================================================" -ForegroundColor Yellow
                    Write-Host "Install.wim Phase: SetSKUIntlDefaults" -ForegroundColor Yellow
                    Dism /Image:"$MountDirectory" /Set-SKUIntlDefaults:"$SetSKUIntlDefaults" /LogPath:"$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dism-SetSKUIntlDefaults.log"
                }
                if ($SetSetupUILang) {
                    Write-Host "===========================================================================" -ForegroundColor Yellow
                    Write-Host "Install.wim Phase: SetSetupUILang" -ForegroundColor Yellow
                    Dism /Image:"$MountDirectory" /Set-SetupUILang:"$SetSetupUILang" /Distribution:"$OS" /LogPath:"$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dism-SetSetupUILang.log"
                }
                if ($SetSysLocale) {
                    Write-Host "===========================================================================" -ForegroundColor Yellow
                    Write-Host "Install.wim Phase: SetSysLocale" -ForegroundColor Yellow
                    Dism /Image:"$MountDirectory" /Set-SysLocale:"$SetSysLocale" /LogPath:"$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dism-SetSysLocale.log"
                }
                if ($SetUILang) {
                    Write-Host "===========================================================================" -ForegroundColor Yellow
                    Write-Host "Install.wim Phase: SetUILang" -ForegroundColor Yellow
                    Dism /Image:"$MountDirectory" /Set-UILang:"$SetUILang" /LogPath:"$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dism-SetUILang.log"
                }
                if ($SetUILangFallback) {
                    Write-Host "===========================================================================" -ForegroundColor Yellow
                    Write-Host "Install.wim Phase: SetUILangFallback" -ForegroundColor Yellow
                    Dism /Image:"$MountDirectory" /Set-UILangFallback:"$SetUILangFallback" /LogPath:"$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dism-SetUILangFallback.log"
                }
                if ($SetUserLocale) {
                    Write-Host "===========================================================================" -ForegroundColor Yellow
                    Write-Host "Install.wim Phase: SetUserLocale" -ForegroundColor Yellow
                    Dism /Image:"$MountDirectory" /Set-UserLocale:"$SetUserLocale" /LogPath:"$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dism-SetUserLocale.log"
                }
                #======================================================================================
                #	Install.wim Cumulative Update 18.9.24
                #======================================================================================
                Write-Host "===========================================================================" -ForegroundColor Yellow
                Write-Host "Install.wim Phase: Cumulative Update" -ForegroundColor Yellow
                if (!($null -eq $UpdateCatCumulative)) {
                    if ($CustomCumulativeUpdate.IsPresent) {
                        Add-WindowsPackage -Path "$MountDirectory" -PackagePath "$($UpdateCatCumulative.FullName)" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateCumulative-install.wim.log"
                    } else {
                        foreach ($Update in $UpdateCatCumulative) {
                            $UpdateCU = $(Get-ChildItem -Path $OSBuilderContent\Updates -Directory -Recurse | Where-Object {$_.Name -eq $($Update.KBTitle)}).FullName
                            if (Test-Path "$UpdateCU") {
                                Write-Host "install.wim: $UpdateCU"
                                Add-WindowsPackage -Path "$MountDirectory" -PackagePath "$UpdateCU" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateCatCumulative-KB$($Update.KBNumber)-install.wim.log"
                            } else {
                                Write-Warning "Not Found: $UpdateCU"
                            }
                        }
                    }
                }
                #======================================================================================
                #	Windows Image Cleanup 18.9.24
                #======================================================================================
                Write-Host "===========================================================================" -ForegroundColor Yellow
                Write-Host "Install.wim Phase: Windows Image Cleanup" -ForegroundColor Yellow
                if ($(Get-WindowsCapability -Path $MountDirectory | Where-Object {$_.state -like "*pending*"})) {
                    Write-Warning "Cannot run WindowsImage Cleanup on a WIM with Pending Installations"
                } else {
                    Write-Host "Performing Image Cleanup on $MountDirectory"
                    Dism /Image:"$MountDirectory" /Cleanup-Image /StartComponentCleanup /ResetBase /LogPath:"$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dism-Cleanup-Image.log"
                }
            }
            #======================================================================================
            #	OSBuild Windows Optional Features
            #======================================================================================
            if ($EnableFeature) {
                Write-Host "===========================================================================" -ForegroundColor Yellow
                Write-Host "Install.wim Phase: Enable Windows Optional Feature"	-ForegroundColor Yellow
                foreach ($FeatureName in $EnableFeature) {
                    Write-Host $FeatureName
                    Enable-WindowsOptionalFeature -FeatureName $FeatureName -Path "$MountDirectory" -All -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Enable-WindowsOptionalFeature.log" | Out-Null
                }
                #======================================================================================
                #	Install.wim Cumulative Update 18.9.24
                #======================================================================================
                Write-Host "===========================================================================" -ForegroundColor Yellow
                Write-Host "Install.wim Phase: Cumulative Update" -ForegroundColor Yellow
                if (!($null -eq $UpdateCatCumulative)) {
                    if ($CustomCumulativeUpdate.IsPresent) {
                        Add-WindowsPackage -Path "$MountDirectory" -PackagePath "$($UpdateCatCumulative.FullName)" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateCumulative-install.wim.log"
                    } else {
                        foreach ($Update in $UpdateCatCumulative) {
                            $UpdateCU = $(Get-ChildItem -Path $OSBuilderContent\Updates -Directory -Recurse | Where-Object {$_.Name -eq $($Update.KBTitle)}).FullName
                            if (Test-Path "$UpdateCU") {
                                Write-Host "install.wim: $UpdateCU"
                                Add-WindowsPackage -Path "$MountDirectory" -PackagePath "$UpdateCU" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateCatCumulative-KB$($Update.KBNumber)-install.wim.log"
                            } else {
                                Write-Warning "Not Found: $UpdateCU"
                            }
                        }
                    }
                }
                #======================================================================================
                #	Windows Image Cleanup 18.9.24
                #======================================================================================
                Write-Host "===========================================================================" -ForegroundColor Yellow
                Write-Host "Install.wim Phase: Windows Image Cleanup" -ForegroundColor Yellow
                if ($(Get-WindowsCapability -Path $MountDirectory | Where-Object {$_.state -like "*pending*"})) {
                    Write-Warning "Cannot run WindowsImage Cleanup on a WIM with Pending Installations"
                } else {
                    Write-Host "Performing Image Cleanup on $MountDirectory"
                    Dism /Image:"$MountDirectory" /Cleanup-Image /StartComponentCleanup /ResetBase /LogPath:"$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dism-Cleanup-Image.log"
                }
            }
            #======================================================================================
            #	OSBuild EnableNetFX3 18.9.28
            #   OSBuild Only
            #======================================================================================
            if ($EnableNetFX3 -eq 'True') {
                Write-Host "===========================================================================" -ForegroundColor Yellow
                Write-Host "Install.wim Phase: Enable NetFX 3.5"	-ForegroundColor Yellow
                Enable-WindowsOptionalFeature -Path "$MountDirectory" -FeatureName NetFX3 -All -LimitAccess -Source "$OS\sources\sxs" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-NetFX3.log"
                #======================================================================================
                #	Install.wim Cumulative Update 18.9.24
                #======================================================================================
                Write-Host "===========================================================================" -ForegroundColor Yellow
                Write-Host "Install.wim Phase: Cumulative Update" -ForegroundColor Yellow
                if (!($null -eq $UpdateCatCumulative)) {
                    if ($CustomCumulativeUpdate.IsPresent) {
                        Add-WindowsPackage -Path "$MountDirectory" -PackagePath "$($UpdateCatCumulative.FullName)" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateCumulative-install.wim.log"
                    } else {
                        foreach ($Update in $UpdateCatCumulative) {
                            $UpdateCU = $(Get-ChildItem -Path $OSBuilderContent\Updates -Directory -Recurse | Where-Object {$_.Name -eq $($Update.KBTitle)}).FullName
                            if (Test-Path "$UpdateCU") {
                                Write-Host "install.wim: $UpdateCU"
                                Add-WindowsPackage -Path "$MountDirectory" -PackagePath "$UpdateCU" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-UpdateCatCumulative-KB$($Update.KBNumber)-install.wim.log"
                            } else {
                                Write-Warning "Not Found: $UpdateCU"
                            }
                        }
                    }
                }
            }
            #======================================================================================
            #	Remove Appx Packages 18.9.28
            #   OSBuild Only
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Install.wim Phase: Remove Appx Packages"	-ForegroundColor Yellow
            if ($RemoveAppx) {
                foreach ($item in $RemoveAppx) {
                    Write-Host $item
                    Remove-AppxProvisionedPackage -Path "$MountDirectory" -PackageName $item -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Remove-AppxProvisionedPackage.log" | Out-Null
                }
            }
            #======================================================================================
            #	Remove Packages 18.9.28
            #   OSBuild Only
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Install.wim Phase: Remove Windows Packages"	-ForegroundColor Yellow
            if ($RemovePackage) {
                foreach ($PackageName in $RemovePackage) {
                    Write-Host $item
                    Remove-WindowsPackage -Path "$MountDirectory" -PackageName $PackageName -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Remove-WindowsPackage.log" | Out-Null
                }
            }
            #======================================================================================
            #	Remove Capability 18.9.28
            #   OSBuild Only
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Install.wim Phase: Remove Windows Capability"	-ForegroundColor Yellow
            if ($RemoveCapability) {
                foreach ($Name in $RemoveCapability) {
                    Write-Host $Name
                    Remove-WindowsCapability -Path "$MountDirectory" -Name $Name -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Remove-WindowsCapability.log" | Out-Null
                }
            }
            #======================================================================================
            #	Disable Windows Optional Feature 18.9.28
            #   OSBuild Only
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Install.wim Phase: Disable Windows Optional Feature" -ForegroundColor Yellow
            if ($DisableFeature) {
                foreach ($FeatureName in $DisableFeature) {
                    Write-Host $FeatureName
                    Disable-WindowsOptionalFeature -FeatureName $FeatureName -Path "$MountDirectory" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Disable-WindowsOptionalFeature.log" | Out-Null
                }
            }
            #======================================================================================
            #	Add Packages 18.9.28
            #   OSBuild Only
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Install.wim Phase: Add Packages"	-ForegroundColor Yellow
            if ($Packages) {
                foreach ($PackagePath in $Packages) {
                    Write-Host "$OSBuilderContent\$PackagePath"
                    Add-WindowsPackage -PackagePath "$OSBuilderContent\$PackagePath" -Path "$MountDirectory" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Add-WindowsPackage.log" | Out-Null
                }
            }
            #======================================================================================
            #	Add Drivers 18.9.28
            #   OSBuild Only
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Install.wim Phase: Add Drivers"	-ForegroundColor Yellow
            if ($Drivers) {
                foreach ($Driver in $Drivers) {
                    Write-Host "$OSBuilderContent\$Driver"
                    Add-WindowsDriver -Driver "$OSBuilderContent\$Driver" -Recurse -Path "$MountDirectory" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Add-WindowsDriver.log" | Out-Null
                }
            }
            #======================================================================================
            #	Extra Files 18.9.28
            #   OSBuild Only
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Install.wim Phase: Extra Files"	-ForegroundColor Yellow
            if ($ExtraFiles) {
                foreach ($ExtraFile in $ExtraFiles) {
                    Write-Host "$OSBuilderContent\$ExtraFile"
                    robocopy "$OSBuilderContent\$ExtraFile" "$MountDirectory" *.* /e /ndl /xx /b /np /ts /tee /r:0 /w:0 /log:"$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-ExtraFiles.log"
                }
            }
            #======================================================================================
            # 	Start Layout 18.9.28
            #   OSBuild Only
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Install.wim Phase: Start Layout"	-ForegroundColor Yellow
            if ($StartLayout) {
                Write-Host "$OSBuilderContent\$StartLayout"
                Copy-Item -Path "$OSBuilderContent\$StartLayout" -Destination "$MountDirectory\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml" -Recurse -Force | Out-Null
            }
            #======================================================================================
            #	Unattend.xml 18.10.5
            #   OSBuild Only
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Install.wim Phase: Unattend.xml"	-ForegroundColor Yellow
            if ($Unattend) {
                Write-Host "$OSBuilderContent\$Unattend"
                if (!(Test-Path "$MountDirectory\Windows\Panther")) {New-Item -Path "$MountDirectory\Windows\Panther" -ItemType Directory -Force | Out-Null}
                Copy-Item -Path "$OSBuilderContent\$Unattend" -Destination "$MountDirectory\Windows\Panther\Unattend.xml" -Force
                Use-WindowsUnattend -UnattendPath "$OSBuilderContent\$Unattend" -Path "$MountDirectory" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Use-WindowsUnattend.log" | Out-Null
            }
            #[void](Read-Host 'Press Enter to Continue')
            #======================================================================================
            #	PowerShell Scripts 18.9.28
            #   OSBuild Only
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Install.wim Phase: PowerShell Scripts" -ForegroundColor Yellow
            foreach ($PSScript in $Scripts) {
                if (Test-Path "$OSBuilderContent\$PSScript") {
                    Write-Host "Install WIM: $OSBuilderContent\$PSScript" -ForegroundColor Cyan
                    Invoke-Expression "& '$OSBuilderContent\$PSScript'"
                }
            }
            #======================================================================================
            #   Auto ExtraFiles 18.10.16
            #======================================================================================
            $AEFLogs = "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Robocopy-AutoExtraFiles.log"
            robocopy "$MountDirectory\Windows\System32" "$WorkingPath\WinPE\AutoExtraFiles\Windows\System32" cacls.exe* /s /xd rescache servicing /ndl /b /np /ts /tee /r:0 /w:0 /log+:"$AEFLogs"
            robocopy "$MountDirectory\Windows\System32" "$WorkingPath\WinPE\AutoExtraFiles\Windows\System32" choice.exe* /s /xd rescache servicing /ndl /b /np /ts /tee /r:0 /w:0 /log+:"$AEFLogs"
            #robocopy "$MountDirectory\Windows\System32" "$WorkingPath\WinPE\AutoExtraFiles\Windows\System32" cleanmgr.exe* /s /xd rescache servicing /ndl /b /np /ts /tee /r:0 /w:0 /log+:"$AEFLogs"
            robocopy "$MountDirectory\Windows\System32" "$WorkingPath\WinPE\AutoExtraFiles\Windows\System32" comp.exe*.* /s /xd rescache servicing /ndl /b /np /ts /tee /r:0 /w:0 /log+:"$AEFLogs"
            robocopy "$MountDirectory\Windows\System32" "$WorkingPath\WinPE\AutoExtraFiles\Windows\System32" defrag*.* /s /xd rescache servicing /ndl /b /np /ts /tee /r:0 /w:0 /log+:"$AEFLogs"
            robocopy "$MountDirectory\Windows\System32" "$WorkingPath\WinPE\AutoExtraFiles\Windows\System32" djoin*.* /s /xd rescache servicing /ndl /b /np /ts /tee /r:0 /w:0 /log+:"$AEFLogs"
            robocopy "$MountDirectory\Windows\System32" "$WorkingPath\WinPE\AutoExtraFiles\Windows\System32" forfiles*.* /s /xd rescache servicing /ndl /b /np /ts /tee /r:0 /w:0 /log+:"$AEFLogs"
            robocopy "$MountDirectory\Windows\System32" "$WorkingPath\WinPE\AutoExtraFiles\Windows\System32" getmac*.* /s /xd rescache servicing /ndl /b /np /ts /tee /r:0 /w:0 /log+:"$AEFLogs"
            robocopy "$MountDirectory\Windows\System32" "$WorkingPath\WinPE\AutoExtraFiles\Windows\System32" makecab.* /s /xd rescache servicing /ndl /b /np /ts /tee /r:0 /w:0 /log+:"$AEFLogs"
            robocopy "$MountDirectory\Windows\System32" "$WorkingPath\WinPE\AutoExtraFiles\Windows\System32" msinfo32.* /s /xd rescache servicing /ndl /b /np /ts /tee /r:0 /w:0 /log+:"$AEFLogs"
            robocopy "$MountDirectory\Windows\System32" "$WorkingPath\WinPE\AutoExtraFiles\Windows\System32" nslookup.* /s /xd rescache servicing /ndl /b /np /ts /tee /r:0 /w:0 /log+:"$AEFLogs"
            robocopy "$MountDirectory\Windows\System32" "$WorkingPath\WinPE\AutoExtraFiles\Windows\System32" systeminfo.* /s /xd rescache servicing /ndl /b /np /ts /tee /r:0 /w:0 /log+:"$AEFLogs"
            robocopy "$MountDirectory\Windows\System32" "$WorkingPath\WinPE\AutoExtraFiles\Windows\System32" tskill.* /s /xd rescache servicing /ndl /b /np /ts /tee /r:0 /w:0 /log+:"$AEFLogs"
            robocopy "$MountDirectory\Windows\System32" "$WorkingPath\WinPE\AutoExtraFiles\Windows\System32" winver.* /s /xd rescache servicing /ndl /b /np /ts /tee /r:0 /w:0 /log+:"$AEFLogs"
            #AeroLite Theme
            robocopy "$MountDirectory\Windows\Resources" "$WorkingPath\WinPE\AutoExtraFiles\Windows\Resources" aerolite*.* /s /ndl /b /np /ts /tee /r:0 /w:0 /log+:"$AEFLogs"
            robocopy "$MountDirectory\Windows\Resources" "$WorkingPath\WinPE\AutoExtraFiles\Windows\Resources" shellstyle*.* /s /ndl /b /np /ts /tee /r:0 /w:0 /log+:"$AEFLogs"
            #Magnify
            robocopy "$MountDirectory\Windows\System32" "$WorkingPath\WinPE\AutoExtraFiles\Windows\System32" magnify*.* /s /xd rescache servicing /ndl /b /np /ts /tee /r:0 /w:0 /log+:"$AEFLogs"
            robocopy "$MountDirectory\Windows\System32" "$WorkingPath\WinPE\AutoExtraFiles\Windows\System32" magnification*.* /s /xd rescache servicing /ndl /b /np /ts /tee /r:0 /w:0 /log+:"$AEFLogs"
            #On Screen Keyboard
            robocopy "$MountDirectory\Windows\System32" "$WorkingPath\WinPE\AutoExtraFiles\Windows\System32" osk*.* /s /xd rescache servicing /ndl /b /np /ts /tee /r:0 /w:0 /log+:"$AEFLogs"
            #RDP
            robocopy "$MountDirectory\Windows\System32" "$WorkingPath\WinPE\AutoExtraFiles\Windows\System32" mstsc*.* /s /xd rescache servicing /ndl /b /np /ts /tee /r:0 /w:0 /log+:"$AEFLogs"
            robocopy "$MountDirectory\Windows\System32" "$WorkingPath\WinPE\AutoExtraFiles\Windows\System32" pdh.dll* /s /xd rescache servicing /ndl /b /np /ts /tee /r:0 /w:0 /log+:"$AEFLogs"
            robocopy "$MountDirectory\Windows\System32" "$WorkingPath\WinPE\AutoExtraFiles\Windows\System32" srpapi.dll* /s /xd rescache servicing /ndl /b /np /ts /tee /r:0 /w:0 /log+:"$AEFLogs"
            #Shutdown
            robocopy "$MountDirectory\Windows\System32" "$WorkingPath\WinPE\AutoExtraFiles\Windows\System32" shutdown.* /s /xd rescache servicing /ndl /b /np /ts /tee /r:0 /w:0 /log+:"$AEFLogs"
            robocopy "$MountDirectory\Windows\System32" "$WorkingPath\WinPE\AutoExtraFiles\Windows\System32" shutdownext.* /s /xd rescache servicing /ndl /b /np /ts /tee /r:0 /w:0 /log+:"$AEFLogs"
            robocopy "$MountDirectory\Windows\System32" "$WorkingPath\WinPE\AutoExtraFiles\Windows\System32" shutdownux.* /s /xd rescache servicing /ndl /b /np /ts /tee /r:0 /w:0 /log+:"$AEFLogs"
            #======================================================================================
            #	Install.wim Save Mounted Windows Image Configuration 18.9.10
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Install.wim Phase: Saving Mounted Windows Image Configuration" -ForegroundColor Yellow
            #======================================================================================
            if ($MediaName -notlike "*server*") {
                Write-Host "$WorkingPath\AppxProvisionedPackage.txt"
                $GetAppxProvisionedPackage = Get-AppxProvisionedPackage -Path "$MountDirectory"
                $GetAppxProvisionedPackage | Out-File "$Info\Get-AppxProvisionedPackage.txt"
                $GetAppxProvisionedPackage | Out-File "$WorkingPath\AppxProvisionedPackage.txt"
                $GetAppxProvisionedPackage | Out-File "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-AppxProvisionedPackage.txt"
                $GetAppxProvisionedPackage | Export-Clixml -Path "$LogsXML\Get-AppxProvisionedPackage.xml"
                $GetAppxProvisionedPackage | Export-Clixml -Path "$LogsXML\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-AppxProvisionedPackage.xml"
                $GetAppxProvisionedPackage | ConvertTo-Json | Out-File "$LogsJS\Get-AppxProvisionedPackage.json"
                $GetAppxProvisionedPackage | ConvertTo-Json | Out-File "$LogsJS\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-AppxProvisionedPackage.json"
            }
            Write-Host "$WorkingPath\WindowsOptionalFeature.txt"
            $GetWindowsOptionalFeature = Get-WindowsOptionalFeature -Path "$MountDirectory"
            $GetWindowsOptionalFeature | Out-File "$Info\Get-WindowsOptionalFeature.txt"
            $GetWindowsOptionalFeature | Out-File "$WorkingPath\WindowsOptionalFeature.txt"
            $GetWindowsOptionalFeature | Out-File "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsOptionalFeature.txt"
            $GetWindowsOptionalFeature | Export-Clixml -Path "$LogsXML\Get-WindowsOptionalFeature.xml"
            $GetWindowsOptionalFeature | Export-Clixml -Path "$LogsXML\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsOptionalFeature.xml"
            $GetWindowsOptionalFeature | ConvertTo-Json | Out-File "$LogsJS\Get-WindowsOptionalFeature.json"
            $GetWindowsOptionalFeature | ConvertTo-Json | Out-File "$LogsJS\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsOptionalFeature.json"

            Write-Host "$WorkingPath\WindowsCapability.txt"
            $GetWindowsCapability = Get-WindowsCapability -Path "$MountDirectory"
            $GetWindowsCapability | Out-File "$Info\Get-WindowsCapability.txt"
            $GetWindowsCapability | Out-File "$WorkingPath\WindowsCapability.txt"
            $GetWindowsCapability | Out-File "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsCapability.txt"
            $GetWindowsCapability | Export-Clixml -Path "$LogsXML\Get-WindowsCapability.xml"
            $GetWindowsCapability | Export-Clixml -Path "$LogsXML\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsCapability.xml"
            $GetWindowsCapability | ConvertTo-Json | Out-File "$LogsJS\Get-WindowsCapability.json"
            $GetWindowsCapability | ConvertTo-Json | Out-File "$LogsJS\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsCapability.json"

            Write-Host "$WorkingPath\WindowsPackage.txt"
            $GetWindowsPackage = Get-WindowsPackage -Path "$MountDirectory"
            $GetWindowsPackage | Out-File "$Info\Get-WindowsPackage.txt"
            $GetWindowsPackage | Out-File "$WorkingPath\WindowsPackage.txt"
            $GetWindowsPackage | Out-File "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsPackage.txt"
            $GetWindowsPackage | Export-Clixml -Path "$LogsXML\Get-WindowsPackage.xml"
            $GetWindowsPackage | Export-Clixml -Path "$LogsXML\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsPackage.xml"
            $GetWindowsPackage | ConvertTo-Json | Out-File "$LogsJS\Get-WindowsPackage.json"
            $GetWindowsPackage | ConvertTo-Json | Out-File "$LogsJS\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsPackage.json"
            #======================================================================================
            #   Dismount and Save 18.10.2
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Install.wim Phase: Dismount and Save" -ForegroundColor Yellow
            if ($PromptBeforeDismount.IsPresent){[void](Read-Host 'Press Enter to Continue')}
            Write-Host "Dismount and Save $MountDirectory"
            Dismount-WindowsImage -Path "$MountDirectory" -Save -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dismount-WindowsImage.log"
            #======================================================================================
            #   Export Install.wim 18.10.2
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Install.wim Phase: Export Install.wim" -ForegroundColor Yellow
            Write-Host "Exporting $WimTemp\install.wim"
            Export-WindowsImage -SourceImagePath "$WimTemp\install.wim" -SourceIndex 1 -DestinationImagePath "$OS\sources\install.wim" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Export-WindowsImage.log"
            #======================================================================================
            #   Saving WinPE Image Configuration 18.10.2
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Inventory Phase: Saving WinPE Image Configuration" -ForegroundColor Yellow
            #======================================================================================
            #   Get-WindowsImage Boot.wim 18.10.2
            #======================================================================================
            Write-Host "$PEInfo\boot.txt"
            $GetWindowsImage = Get-WindowsImage -ImagePath "$OS\sources\boot.wim"
            $GetWindowsImage | Out-File "$PEInfo\boot.txt"
            (Get-Content "$PEInfo\boot.txt") | Where-Object {$_.Trim(" `t")} | Set-Content "$PEInfo\boot.txt"
            $GetWindowsImage | Out-File "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsImage-boot.wim.txt"
            $GetWindowsImage | Export-Clixml -Path "$PELogsXML\Get-WindowsImage-boot.wim.xml"
            $GetWindowsImage | Export-Clixml -Path "$PELogsXML\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsImage-boot.wim.xml"
            $GetWindowsImage | ConvertTo-Json | Out-File "$PELogsJS\Get-WindowsImage-boot.wim.json"
            $GetWindowsImage | ConvertTo-Json | Out-File "$PELogsJS\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsImage-boot.wim.json"
            #======================================================================================
            #   Get-WindowsImage WinPE 18.10.2
            #======================================================================================
            Write-Host "$PEInfo\winpe.txt"
            $GetWindowsImage = Get-WindowsImage -ImagePath "$OS\sources\boot.wim" -Index 1 | Select-Object -Property *
            $GetWindowsImage | Out-File "$PEInfo\winpe.txt"
            (Get-Content "$PEInfo\winpe.txt") | Where-Object {$_.Trim(" `t")} | Set-Content "$PEInfo\winpe.txt"
            $GetWindowsImage | Out-File "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsImage-winpe.wim.txt"
            $GetWindowsImage | Export-Clixml -Path "$PELogsXML\Get-WindowsImage-winpe.wim.xml"
            $GetWindowsImage | Export-Clixml -Path "$PELogsXML\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsImage-winpe.wim.xml"
            $GetWindowsImage | ConvertTo-Json | Out-File "$PELogsJS\Get-WindowsImage-winpe.wim.json"
            $GetWindowsImage | ConvertTo-Json | Out-File "$PELogsJS\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsImage-winpe.wim.json"
            #======================================================================================
            #   Get-WindowsImage Setup 18.10.2
            #======================================================================================
            Write-Host "$PEInfo\setup.txt"
            $GetWindowsImage = Get-WindowsImage -ImagePath "$OS\sources\boot.wim" -Index 2 | Select-Object -Property *
            $GetWindowsImage | Out-File "$PEInfo\setup.txt"
            (Get-Content "$PEInfo\setup.txt") | Where-Object {$_.Trim(" `t")} | Set-Content "$PEInfo\setup.txt"
            $GetWindowsImage | Out-File "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsImage-setup.wim.txt"
            $GetWindowsImage | Export-Clixml -Path "$PELogsXML\Get-WindowsImage-setup.wim.xml"
            $GetWindowsImage | Export-Clixml -Path "$PELogsXML\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsImage-setup.wim.xml"
            $GetWindowsImage | ConvertTo-Json | Out-File "$PELogsJS\Get-WindowsImage-setup.wim.json"
            $GetWindowsImage | ConvertTo-Json | Out-File "$PELogsJS\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsImage-setup.wim.json"
            #======================================================================================
            #   Saving Windows Image Configuration 18.10.2
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Inventory Phase: Saving Windows Image Configuration" -ForegroundColor Yellow
            Write-Host "$WorkingPath\WindowsImage.txt"
            $GetWindowsImage = Get-WindowsImage -ImagePath "$OS\sources\install.wim" -Index 1 | Select-Object -Property *
            $GetWindowsImage | Add-Member -Type NoteProperty -Name "UBR" -Value $UBR
            $GetWindowsImage | Out-File "$WorkingPath\WindowsImage.txt"
            $GetWindowsImage | Out-File "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsImage.txt"
            $GetWindowsImage | Export-Clixml -Path "$LogsXML\Get-WindowsImage.xml"
            $GetWindowsImage | Export-Clixml -Path "$LogsXML\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsImage.xml"
            $GetWindowsImage | ConvertTo-Json | Out-File "$LogsJS\Get-WindowsImage.json"
            $GetWindowsImage | ConvertTo-Json | Out-File "$LogsJS\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsImage.json"
            (Get-Content "$WorkingPath\WindowsImage.txt") | Where-Object {$_.Trim(" `t")} | Set-Content "$WorkingPath\WindowsImage.txt"
            #======================================================================================
            #   Get-WindowsImageContent 18.10.2
            #======================================================================================
            Write-Host "$Info\Get-WindowsImageContent.txt"  
            Get-WindowsImageContent -ImagePath "$OS\Sources\install.wim" -Index 1 | Out-File "$Info\Get-WindowsImageContent.txt"
            #======================================================================================
            #   Display OS Information 18.10.2
            #======================================================================================
            Show-OSInfo $WorkingPath
            #======================================================================================
            #   Remove Temporary Files 18.9.13
            #======================================================================================
            if (Test-Path "$WimTemp") {Remove-Item -Path "$WimTemp" -Force -Recurse | Out-Null}
            if (Test-Path "$MountDirectory") {Remove-Item -Path "$MountDirectory" -Force -Recurse | Out-Null}
            if (Test-Path "$MountWinRE") {Remove-Item -Path "$MountWinRE" -Force -Recurse | Out-Null}
            if (Test-Path "$MountWinPE") {Remove-Item -Path "$MountWinPE" -Force -Recurse | Out-Null}
            if (Test-Path "$MountSetup") {Remove-Item -Path "$MountSetup" -Force -Recurse | Out-Null}
            #======================================================================================
            #   UBR Validation 18.9.12
            #======================================================================================
            if ($UBRPre -eq $UBR) {
                Write-Host "===========================================================================" -ForegroundColor Yellow
                Write-Warning "The Update Build Revision did not change after Windows Updates"
                Write-Warning "There may have been an issue applying the Cumulative Update if this was not expected"
            }
            if (!($UBR)) {$UBR = $((Get-Date).ToString('mmss'))}
            #======================================================================================
            #   Set New Name 18.9.12
            #======================================================================================
            $OSImageName = $($GetWindowsImage.ImageName)
            $OSImageName = $OSImageName -replace "Windows 10", "Win10"
            $OSImageName = $OSImageName -replace "Enterprise", "Ent"
            $OSImageName = $OSImageName -replace "Education", "Edu"
            $OSImageName = $OSImageName -replace " for ", " "
            $OSImageName = $OSImageName -replace "Workstations", "Wks"
            $OSImageName = $OSImageName -replace "Windows Server 2016", "Svr2016"
			$OSImageName = $OSImageName -replace "Windows Server 2019", "Svr2019"
            $OSImageName = $OSImageName -replace "ServerStandardACore", "Std Core"
            $OSImageName = $OSImageName -replace "ServerDatacenterACore", "DC Core"
            $OSImageName = $OSImageName -replace "ServerStandardCore", "Std Core"
            $OSImageName = $OSImageName -replace "ServerDatacenterCore", "DC Core"
            $OSImageName = $OSImageName -replace "ServerStandard", "Std"
            $OSImageName = $OSImageName -replace "ServerDatacenter", "DC"
            $OSImageName = $OSImageName -replace "Standard", "Std"
            $OSImageName = $OSImageName -replace "Datacenter", "DC"
            $OSImageName = $OSImageName -replace 'Desktop Experience', 'DTE'
            $OSImageName = $OSImageName -replace '\(', ''
            $OSImageName = $OSImageName -replace '\)', ''

            $OSArchitecture = $($GetWindowsImage.Architecture)
            if ($OSArchitecture -eq 0) {$OSArchitecture = 'x86'}
            elseif ($OSArchitecture -eq 1) {$OSArchitecture = 'MIPS'}
            elseif ($OSArchitecture -eq 2) {$OSArchitecture = 'Alpha'}
            elseif ($OSArchitecture -eq 3) {$OSArchitecture = 'PowerPC'}
            elseif ($OSArchitecture -eq 6) {$OSArchitecture = 'ia64'}
            elseif ($OSArchitecture -eq 9) {$OSArchitecture = 'x64'}

            $OSBuild = $($GetWindowsImage.Build)
            $OSVersionNumber = $null
            if (Test-Path "$LogsXML\CurrentVersion.xml") {
                $RegCurrentVersion = Import-Clixml -Path "$LogsXML\CurrentVersion.xml"
                $OSVersionNumber = $($RegCurrentVersion.ReleaseId)
            } else {
                if ($OSBuild -eq 10240) {$OSVersionNumber = 1507}
                if ($OSBuild -eq 14393) {$OSVersionNumber = 1607}
                if ($OSBuild -eq 15063) {$OSVersionNumber = 1703}
                if ($OSBuild -eq 16299) {$OSVersionNumber = 1709}
                if ($OSBuild -eq 17134) {$OSVersionNumber = 1803}
				if ($OSBuild -eq 17763) {$OSVersionNumber = 1809}
            }

            $OSLanguages = $($GetWindowsImage.Languages)
            if ($null -eq $OSVersionNumber ) {
                Write-Host ""
                Write-Warning "OS Build $OSVersionNumber is not automatically recognized"
                Write-Warning "Check for an updated version of OSBuilder"
                Write-Host ""
                if ($BuildName -like "build*") {$BuildName = "$OSImageName $OSArchitecture"}
            } else {
                if ($BuildName -like "build*") {$BuildName = "$OSImageName $OSArchitecture $OSVersionNumber"}
                
            }
            $BuildName = "$BuildName $OSLanguages"
            if ($($OSLanguages.count) -eq 1) {$BuildName = $BuildName.replace(' en-US', '')}
            if ($CustomBuildName) {$BuildName = "$CustomBuildName"}
            $NewWorkingPathName = "$BuildName $UBR"
            $NewWorkingPath = "$OSBuilderOSBuilds\$NewWorkingPathName"
            #======================================================================================
            # Rename Build Directory
            #======================================================================================									  
            if (Test-Path $NewWorkingPath) {
                Write-Host ""
                Write-Warning "Trying to rename the Build directory, but it already exists"
                Write-Warning "Appending the HHmm to the directory name"
                $NewWorkingPathName = "$NewWorkingPathName $((Get-Date).ToString('mmss'))"
            }
            #======================================================================================
            #   Create Variables 18.10.4
            #======================================================================================
            Get-Variable | Select-Object -Property Name, Value | Export-Clixml "$LogsXML\Variables.xml"
            Get-Variable | Select-Object -Property Name, Value | ConvertTo-Json | Out-File "$LogsJS\Variables.json"
            #======================================================================================
            #   Close 18.10.4
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Closing Phase: Renaming ""$WorkingPath"" to ""$NewWorkingPathName""" -ForegroundColor Yellow
            Stop-Transcript
            Rename-Item -Path "$WorkingPath" -NewName "$NewWorkingPathName" -ErrorAction Stop
        }
        Write-Host "===========================================================================" -ForegroundColor Green
        Write-Host "Complete!" -ForegroundColor Green
        Write-Host "===========================================================================" -ForegroundColor Green
    }
}