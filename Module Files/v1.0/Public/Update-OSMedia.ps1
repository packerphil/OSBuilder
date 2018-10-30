<#
.SYNOPSIS
Applies Adobe, Component, Cumulative, Servicing Stack, and Setup Updates to Windows 10, Windows Server 2016, and Windows Server 2019 using Offline Servicing

.DESCRIPTION
Updates are gathered from the OSBuilder Update Catalogs

.PARAMETER ByName
Enter the name of the existing OSMedia to update

.EXAMPLE
Update-OSMedia -ByName 'Win10 Ent x64 1803 17134.345'

.PARAMETER CustomCumulativeUpdate
Specify a custom Cumulative Update

.PARAMETER CustomServicingStack
Specify a custom Servicing Stack

.PARAMETER DownloadUpdates
Automatically download the required updates if they are not present in the Content\Updates directory

.PARAMETER Execute
Execute the Update

.PARAMETER PromptBeforeDismount
Adds a 'Press Enter to Continue' prompt before the Install.wim is dismounted

.PARAMETER PromptBeforeDismountWinPE
Adds a 'Press Enter to Continue' prompt before the WinPE Wims are dismounted
#>
function Update-OSMedia {
    [CmdletBinding()]
    Param (
        [string]$ByName,
        [switch]$CustomCumulativeUpdate,
        [switch]$CustomServicingStack,
        [switch]$DownloadUpdates,
        [switch]$Execute,
        [switch]$PromptBeforeDismount,
        [switch]$PromptBeforeDismountWinPE
    )
    #======================================================================================
    #   Start 18.9.27
    #======================================================================================
    Write-Host "===========================================================================" -ForegroundColor Green
    Write-Host "Update-OSMedia" -ForegroundColor Green
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
    #   Initialize OSBuilder 18.9.24
    #======================================================================================
    Get-OSBuilder -CreatePaths -HideDetails
    #======================================================================================
    #   Validate OSMedia has Content 18.10.12
    #======================================================================================
    $AllOSMedia = @()
    $AllOSMedia = Get-ChildItem -Path "$OSBuilderOSMedia" -Directory | Where-Object {$_.Name -like "*.*"} | Select-Object -Property Name, FullName, CreationTime
    if ($null -eq $AllOSMedia) {
        Write-Warning "OSMedia content not found.  Use Import-OSMedia to import an Operating System first . . . Exiting!"
        Break
    }
    #======================================================================================
    #   Validate OSMedia has an install.wim 18.9.13
    #======================================================================================
    $AllOSMedia = $AllOSMedia | Where-Object {Test-Path $(Join-Path $_.FullName (Join-Path "OS" (Join-Path "sources" "install.wim")))}
    if ($null -eq $AllOSMedia) {
        Write-Warning "OSMedia Install.wim not found.  Use Import-OSMedia to import an Operating System first . . . Exiting!"
        Break
    }
    #======================================================================================
    #   Validate OSMedia was imported with Import-OSMedia 18.9.13
    #======================================================================================
    $AllOSMedia = $AllOSMedia | Where-Object {Test-Path $(Join-Path $_.FullName "WindowsImage.txt")}
    if ($null -eq $AllOSMedia) {
        Write-Warning "OSMedia content invalid (missing WindowsImage.txt).  Use Import-OSMedia to import an Operating System first . . . Exiting!"
        Break
    }
    #======================================================================================
    #   Select Source OSMedia 18.10.3
    #======================================================================================
    if ($ByName) {
        $AllOSMedia = $AllOSMedia | Where-Object {$_.Name -like "*$ByName*" -or $_.FullName -like "*$ByName*"}
        if ($null -eq $AllOSMedia) {
            Write-Warning "Could not find a matching OSMedia to update . . . Exiting!"
            Break
        }
    } else {
        if ($CustomCumulativeUpdate.IsPresent -or $CustomServicingStack.IsPresent) {
            $AllOSMedia = $AllOSMedia | Out-GridView -Title "Select a single Source OSMedia to Update (Cancel to Exit)" -OutputMode Single
        } else {
            $AllOSMedia = $AllOSMedia | Out-GridView -Title "Select one or more Source OSMedia to Update (Cancel to Exit)" -PassThru
        }
        if($null -eq $AllOSMedia) {
            Write-Warning "Source OSMedia was not selected . . . Exiting!"
            Break
        }
    }
    if ($AllOSMedia.Count -gt 1) {
        Write-Warning "Updating Multiple Operating Systems.  This may take some time ..."
    }
    #======================================================================================
    #   Select Custom Servicing Stack 18.10.2
    #======================================================================================
    if ($CustomServicingStack.IsPresent) {
        $UpdateCatServicing =@()
        $UpdateCatServicing = Get-ChildItem -Path "$OSBuilderContent\Updates\Custom" -File -Recurse | Select-Object -Property FullName
        #foreach ($CustomServicingStackFile in $UpdateCatServicing) {$CustomServicingStackFile.FullName = $($CustomServicingStackFile.FullName).replace("$OSBuilderContent\",'')}
        $UpdateCatServicing = $UpdateCatServicing | Out-GridView -Title "Select Custom Servicing Stack to apply and press OK (Esc or Cancel to Exit)" -OutputMode Single
        if ($null -eq $UpdateCatServicing) {
            Write-Warning "Custom Servicing Stack was not selected ... Exiting"
            Return
        }
    }
    #======================================================================================
    #   Select Custom Cumulative Update 18.10.2
    #======================================================================================
    if ($CustomCumulativeUpdate.IsPresent) {
        $UpdateCatCumulative =@()
        $UpdateCatCumulative = Get-ChildItem -Path "$OSBuilderContent\Updates\Custom" -File -Recurse | Select-Object -Property FullName
        #foreach ($CustomCumulativeUpdateFile in $UpdateCatCumulative) {$CustomCumulativeUpdateFile.FullName = $($CustomCumulativeUpdateFile.FullName).replace("$OSBuilderContent\",'')}
        $UpdateCatCumulative = $UpdateCatCumulative | Out-GridView -Title "Select Custom Cumulative Update to apply and press OK (Esc or Cancel to Exit)" -OutputMode Single
        if ($null -eq $UpdateCatCumulative) {
            Write-Warning "Custom Cumulative Update was not selected ... Exiting"
            Return
        }
    }
    #======================================================================================
    #   Update OSMedia 18.10.3
    #======================================================================================
    foreach ($SelectedOSMedia in $AllOSMedia) {
        #======================================================================================
        #   Get Windows Image Information 18.10.3
        #======================================================================================
        $OSSourcePath = "$($SelectedOSMedia.FullName)"
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
        #   Set Working Path 18.9.24
        #======================================================================================
        $BuildName = "build$((Get-Date).ToString('mmss'))"
        $WorkingPath = "$OSBuilderOSMedia\$BuildName"
        #======================================================================================
        #   Validate Exiting WorkingPath 18.9.24
        #======================================================================================
        if (Test-Path $WorkingPath) {
            Write-Warning "$WorkingPath exists.  Contents will be replaced"
            Remove-Item -Path "$WorkingPath" -Force -Recurse
            Write-Host ""
        }
        #======================================================================================
        #   Update Catalogs 18.10.12
        #======================================================================================
        if ($DownloadUpdates.IsPresent) {Get-OSBuilderUpdates -UpdateCatalogs -HideDetails}
        if (!(Test-Path $CatalogLocal)) {Get-OSBuilderUpdates -UpdateCatalogs -HideDetails}
        #======================================================================================
        #   Get Catalogs 18.9.23
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
        #   Update Validation 18.10.12
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
        #   Execute 18.9.24
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
            #   Install.wim Save Mounted Windows Image Configuration 18.9.10
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
            
            $NewWorkingPathName = "$BuildName $UBR"
            $NewWorkingPath = "$OSBuilderOSMedia\$NewWorkingPathName"
            #======================================================================================
            #   Rename Build Directory
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