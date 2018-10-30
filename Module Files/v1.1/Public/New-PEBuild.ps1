function New-PEBuild {
    [CmdletBinding()]
    Param (
        [switch]$Execute,
        [switch]$PromptAfterMount,
        [switch]$PromptBeforeDismount
    )
#======================================================================================
#   MDT Files 18.10.12
#======================================================================================
$MDTwinpeshl = @'
[LaunchApps]
%SYSTEMROOT%\System32\bddrun.exe,/bootstrap
'@

$DaRTwinpeshl = @'
[LaunchApps]
%windir%\system32\netstart.exe,-network
%SYSTEMDRIVE%\sources\recovery\recenv.exe
'@

$MDTUnattendPEx64 = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            <Display>
                <ColorDepth>32</ColorDepth>
                <HorizontalResolution>1024</HorizontalResolution>
                <RefreshRate>60</RefreshRate>
                <VerticalResolution>768</VerticalResolution>
            </Display>
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add">
                    <Description>Lite Touch PE</Description>
                    <Order>1</Order>
                    <Path>wscript.exe X:\Deploy\Scripts\LiteTouch.wsf</Path>
                </RunSynchronousCommand>
            </RunSynchronous>
        </component>
    </settings>
</unattend>
'@

$MDTUnattendPEx86 = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            <Display>
                <ColorDepth>32</ColorDepth>
                <HorizontalResolution>1024</HorizontalResolution>
                <RefreshRate>60</RefreshRate>
                <VerticalResolution>768</VerticalResolution>
            </Display>
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add">
                    <Description>Lite Touch PE</Description>
                    <Order>1</Order>
                    <Path>wscript.exe X:\Deploy\Scripts\LiteTouch.wsf</Path>
                </RunSynchronousCommand>
            </RunSynchronous>
        </component>
    </settings>
</unattend>
'@

    #======================================================================================
    #   Start 18.10.13
    #======================================================================================
    Write-Host "===========================================================================" -ForegroundColor Green
    Write-Host "Start New-PEBuild" -ForegroundColor Green
    #======================================================================================
    #   Validate Administrator Rights 18.10.13
    #======================================================================================
    if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "===========================================================================" -ForegroundColor Green
        Write-Warning "This function needs to be run as Administrator"
        Write-Host "===========================================================================" -ForegroundColor Green
        Write-Host "Complete!" -ForegroundColor Green
        Write-Host "===========================================================================" -ForegroundColor Green
        Return
    }
    #======================================================================================
    #   Initialize OSBuilder 18.10.13
    #======================================================================================
    Write-Host "===========================================================================" -ForegroundColor Yellow
    Write-Host "Intializing OSBuilder..." -ForegroundColor Yellow
    Get-OSBuilder -CreatePaths -HideDetails
    #======================================================================================
    #   Select Task JSON 18.10.17
    #======================================================================================
    Write-Host "===========================================================================" -ForegroundColor Yellow
    Write-Host "Selecting Task..." -ForegroundColor Yellow
    $SelectTask = Get-ChildItem -Path $OSBuilderTasks *.json -File | Select-Object -Property BaseName, FullName, Length, CreationTime, LastWriteTime | Sort-Object -Property BaseName
    $SelectTask = $SelectTask | Where-Object {$_.BaseName -like "MDT*" -or $_.BaseName -like "Recovery*" -or $_.BaseName -like "WinPE*"}
    if ($CustomCumulativeUpdate.IsPresent -or $CustomServicingStack.IsPresent) {
		$SelectTask = $SelectTask | Out-GridView -Title "PEBuild Tasks: Select one or more Tasks to execute and press OK (Cancel to Exit)" -OutputMode Single
	} else {
		$SelectTask = $SelectTask | Out-GridView -Title "PEBuild Tasks: Select one or more Tasks to execute and press OK (Cancel to Exit)" -Passthru
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
        $TaskName = $($Task.TaskName).replace('PEBuild ','')
        #$BuildName = $($Task.BuildName)
        #$CustomBuildName = $($Task.BuildName)
        $TaskVersion = $($Task.TaskVersion)
        $TaskType = $($Task.TaskType)
        $AutoExtraFiles = $($Task.AutoExtraFiles)
        $MediaName = $($Task.MediaName)
        $MediaPath = "$OSBuilderOSMedia\$MediaName"
        $DeploymentShare = $($Task.DeploymentShare)
        $PEOutput = $($Task.PEOutput)
        $ScratchSpace = $($Task.ScratchSpace)
        $SourceWim = $($Task.SourceWim)
        $WinPEADK = $($Task.WinPEAddADK)
        $WinPEDaRT = $($Task.WinPEAddDaRT)
        $WinPEDrivers = $($Task.WinPEAddWindowsDriver)
        $WinPEExtraFiles = $($Task.WinPERobocopyExtraFiles)
        $WinPEScripts = $($Task.WinPEInvokeScript)
        #$WinPEWallpaper= $($Task.WinPEWallpaper)
        #======================================================================================
        #   Start Task 18.9.24
        #======================================================================================
        Write-Host "===========================================================================" -ForegroundColor Green
        Write-Host "Starting Task: $TaskName" -ForegroundColor Green
        Write-Host "===========================================================================" -ForegroundColor Green
        #======================================================================================
        #	Validate Proper TaskVersion 18.9.24
        #======================================================================================
        if ([System.Version]$TaskVersion -lt [System.Version]"18.10.10") {
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Validating Task Version..." -ForegroundColor Yellow
            Write-Warning "OSBuilder Tasks need to be version 18.10.10 or newer"
            Write-Warning "Recreate this Task using New-OSBuildTask"
            Write-Host "===========================================================================" -ForegroundColor Green
            Write-Host "Complete!" -ForegroundColor Green
            Write-Host "===========================================================================" -ForegroundColor Green
            Return
        }
        #======================================================================================
        #	Select Latest Media 18.9.24
        #======================================================================================
        #if (!($DontUseNewestMedia)) {
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
        #}
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
        #$BuildName = "build$((Get-Date).ToString('mmss'))"
        $WorkingPath = "$OSBuilderPEBuilds\$Taskname"
        #======================================================================================
        #	Validate Exiting WorkingPath 18.9.24
        #======================================================================================
        if (Test-Path $WorkingPath) {
            Write-Warning "$WorkingPath exists.  Contents will be replaced"
            Remove-Item -Path "$WorkingPath\*" -Force -Recurse | Out-Null
        }
        #======================================================================================
        #	Task Information 18.9.28
        #======================================================================================
        Write-Host "===========================================================================" -ForegroundColor Yellow
        Write-Host "Task Information" -ForegroundColor Yellow
        Write-Host "-TaskName:          $TaskName" -ForegroundColor Cyan
        Write-Host "-TaskVersion:       $TaskVersion" -ForegroundColor Cyan
        Write-Host "-TaskType:          $TaskType" -ForegroundColor Cyan
        Write-Host "-Auto ExtraFiles:   $AutoExtraFiles" -ForegroundColor Cyan
        if ($PEOutput -eq 'Recovery') {
            $DestinationName = "Microsoft Windows Recovery Environment ($OSArchitecture)"
        } else {
            $DestinationName = "Microsoft Windows PE ($OSArchitecture)"
        }
        Write-Host "-Destination Name:  $DestinationName" -ForegroundColor Cyan
        Write-Host "-MDT Share:         $DeploymentShare" -ForegroundColor Cyan
        Write-Host "-Media Name:        $MediaName" -ForegroundColor Cyan
        Write-Host "-Media Path:        $MediaPath" -ForegroundColor Cyan
        Write-Host "-PE Output:         $PEOutput" -ForegroundColor Cyan
        Write-Host "-Scratch Space:     $ScratchSpace" -ForegroundColor Cyan
        Write-Host "-Source Wim:        $SourceWim" -ForegroundColor Cyan
        Write-Host "-Working Path:      $WorkingPath" -ForegroundColor Cyan
        Write-Host "-WinPE DaRT:        $WinPEDaRT" -ForegroundColor Cyan
        Write-Host "-WinPE Drivers:" -ForegroundColor Cyan
        if ($WinPEDrivers){foreach ($item in $WinPEDrivers) {Write-Host $item}}
        Write-Host "-WinPE ADK Pkgs:" -ForegroundColor Cyan
        if ($WinPEADK){foreach ($item in $WinPEADK) {Write-Host $item}}
        Write-Host "-WinPE Extra Files:" -ForegroundColor Cyan
        if ($WinPEExtraFiles){foreach ($item in $WinPEExtraFiles) {Write-Host $item}}
        Write-Host "-WinPE Scripts:" -ForegroundColor Cyan
        if ($WinPEScripts){foreach ($item in $WinPEScripts) {Write-Host $item}}
        #Write-Host "-WinPE Wallpaper:   $WinPEWallpaper" -ForegroundColor Cyan
        #======================================================================================
        #	Validate DeploymentShare 18.10.17
        #======================================================================================
        if ($DeploymentShare) {
            if (!(Test-Path "$DeploymentShare")) {
                Write-Warning "MDT Deployment Share not found ... Exiting!"
                Return
            }
        }
        #======================================================================================
        #	Execute 18.10.11
        #======================================================================================
        if ($Execute.IsPresent) {
            $Info = Join-Path $WorkingPath 'info'
            $LogsJS = Join-Path $Info 'json'
            $LogsXML = Join-Path $Info 'xml'
            $Logs =	Join-Path $Info "logs"
            if (!(Test-Path "$Info")) {New-Item "$Info" -ItemType Directory -Force | Out-Null}
            if (!(Test-Path "$LogsJS")) {New-Item "$LogsJS" -ItemType Directory -Force | Out-Null}
            if (!(Test-Path "$LogsXML")) {New-Item "$LogsXML" -ItemType Directory -Force | Out-Null}
            if (!(Test-Path "$Logs")) {New-Item "$Logs" -ItemType Directory -Force | Out-Null}

            $OS = Join-Path $WorkingPath "OS"
            if (!(Test-Path "$OS")) {New-Item "$OS" -ItemType Directory -Force | Out-Null}

            $Sources = "$OS\sources"
            if (!(Test-Path "$Sources")) {New-Item "$Sources" -ItemType Directory -Force | Out-Null}

            $WimTemp = Join-Path $WorkingPath "WimTemp"
            if (!(Test-Path "$WimTemp")) {New-Item "$WimTemp" -ItemType Directory -Force | Out-Null}

            $WorkingWim = "$WorkingPath\WimTemp\boot.wim"
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
            Write-Host "Creating $TaskName" -ForegroundColor Yellow
            Write-Host "Working Path:       $WorkingPath" -ForegroundColor Yellow
            Write-Host "-Logs:              $Logs" -ForegroundColor Cyan
            Write-Host "-Media:             $OS" -ForegroundColor Cyan
            #======================================================================================
            #   Create Mount Directories 18.10.10
            #======================================================================================
            $MountDirectory = Join-Path $OSBuilderContent\Mount "pebuild$((Get-Date).ToString('mmss'))"
            if ( ! (Test-Path "$MountDirectory")) {New-Item "$MountDirectory" -ItemType Directory -Force | Out-Null}
            #======================================================================================
            #   Copy OS 18.10.10
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Copying $OSSourcePath\OS to $OS" -ForegroundColor Yellow
            Copy-Item -Path "$OSSourcePath\OS\bootmgr" -Destination "$OS\bootmgr" -Force | Out-Null
            Copy-Item -Path "$OSSourcePath\OS\bootmgr.efi" -Destination "$OS\bootmgr.efi" -Force | Out-Null
            Copy-Item -Path "$OSSourcePath\OS\boot\" -Destination "$OS\boot\" -Recurse -Force | Out-Null
            Copy-Item -Path "$OSSourcePath\OS\efi\" -Destination "$OS\efi\" -Recurse -Force | Out-Null
            Dism /Export-Image /SourceImageFile:"$OSSourcePath\WinPE\$SourceWim.wim" /SourceIndex:1 /DestinationImageFile:"$WorkingWim" /DestinationName:"$DestinationName" /Bootable /CheckIntegrity
            #Copy-Item -Path "$OSSourcePath\WinPE\$SourceWim.wim" -Destination "$WorkingWim" -Force | Out-Null
            if (!(Test-Path "$Sources")) {New-Item "$Sources" -ItemType Directory -Force | Out-Null}
            #======================================================================================
            #   WinPE Phase: Mount 18.9.10
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: Mount WinPE WIM" -ForegroundColor Yellow
            Mount-WindowsImage -ImagePath "$WorkingWim" -Index 1 -Path "$MountDirectory" -Optimize -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Mount-WindowsImage.log"
            if ($PromptAfterMount.IsPresent){[void](Read-Host 'Press Enter to Continue')}
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
            #   Set-ScratchSpace 18.10.13
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: Set-ScratchSpace" -ForegroundColor Yellow
            Dism /Image:"$MountDirectory" /Set-ScratchSpace:$ScratchSpace
            #======================================================================================
            #   Set-TargetPath 18.10.13
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: Set-TargetPath" -ForegroundColor Yellow
            Dism /Image:"$MountDirectory" /Set-TargetPath:"X:\"
            #======================================================================================
            #   WinPE Phase: ADK Optional Components 18.10.11
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: ADK Optional Components" -ForegroundColor Yellow
            if ([string]::IsNullOrEmpty($WinPEADK) -or [string]::IsNullOrWhiteSpace($WinPEADK)) {
                # Do Nothing
            } else {
                foreach ($PackagePath in $WinPEADK) {
                    if ($PackagePath -like "*NetFx*") {
                        Write-Host "$OSBuilderContent\$PackagePath" -ForegroundColor Cyan
                        Add-WindowsPackage -PackagePath "$OSBuilderContent\$PackagePath" -Path "$MountDirectory" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Add-WindowsPackage.log" | Out-Null
                    }
                }
                $WinPEADK = $WinPEADK | Where-Object {$_ -notlike "*NetFx*"}
                foreach ($PackagePath in $WinPEADK) {
                    if ($PackagePath -like "*WinPE-PowerShell*") {
                        Write-Host "$OSBuilderContent\$PackagePath" -ForegroundColor Cyan
                        Add-WindowsPackage -PackagePath "$OSBuilderContent\$PackagePath" -Path "$MountDirectory" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Add-WindowsPackage.log" | Out-Null
                    }
                }
                $WinPEADK = $WinPEADK | Where-Object {$_ -notlike "*PowerShell*"}
                foreach ($PackagePath in $WinPEADK) {
                    Write-Host "$OSBuilderContent\$PackagePath" -ForegroundColor Cyan
                    Add-WindowsPackage -PackagePath "$OSBuilderContent\$PackagePath" -Path "$MountDirectory" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Add-WindowsPackage.log" | Out-Null
                }
            }
            #======================================================================================
            #   WinPE Phase: WinPE DaRT 18.10.11
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: Microsoft DaRT" -ForegroundColor Yellow
            if ($WinPEDaRT) {
                if ([string]::IsNullOrEmpty($WinPEDaRT) -or [string]::IsNullOrWhiteSpace($WinPEDaRT)) {Write-Warning "Skipping WinPE DaRT"}
                elseif (Test-Path "$OSBuilderContent\$WinPEDaRT") {
                    #======================================================================================
                    if (Test-Path $(Join-Path $(Split-Path "$OSBuilderContent\$WinPEDart") 'DartConfig.dat')) {
                        Write-Host "$OSBuilderContent\$WinPEDaRT"
                        expand.exe "$OSBuilderContent\$WinPEDaRT" -F:*.* "$MountDirectory"
                        #if (Test-Path "$MountDirectory\Windows\System32\winpeshl.ini") {Remove-Item -Path "$MountDirectory\Windows\System32\winpeshl.ini" -Force}
                        #======================================================================================
                        Write-Host "Copying DartConfig.dat to $MountDirectory\Windows\System32\DartConfig.dat"
                        Copy-Item -Path $(Join-Path $(Split-Path "$OSBuilderContent\$WinPEDart") 'DartConfig.dat') -Destination "$MountDirectory\Windows\System32\DartConfig.dat" -Force | Out-Null
                        #======================================================================================
                    } elseif (Test-Path $(Join-Path $(Split-Path $WinPEDart) 'DartConfig8.dat')) {
                        Write-Host "$OSBuilderContent\$WinPEDaRT"
                        expand.exe "$OSBuilderContent\$WinPEDaRT" -F:*.* "$MountDirectory"
                        #if (Test-Path "$MountDirectory\Windows\System32\winpeshl.ini") {Remove-Item -Path "$MountDirectory\Windows\System32\winpeshl.ini" -Force}
                        #======================================================================================
                        Write-Host "Copying DartConfig8.dat to $MountDirectory\Windows\System32\DartConfig.dat"
                        Copy-Item -Path $(Join-Path $(Split-Path "$OSBuilderContent\$WinPEDart") 'DartConfig8.dat') -Destination "$MountDirectory\Windows\System32\DartConfig.dat" -Force | Out-Null
                        #======================================================================================
                    }
                    #======================================================================================
                    #   WinPE Edit winpeshl.ini
                    #======================================================================================
                    if ($PEOutput -eq 'Recovery') {
                        Write-Host "===========================================================================" -ForegroundColor Yellow
                        Write-Host "WinPE Phase: Edit winpeshl.ini" -ForegroundColor Yellow
                        if (Test-Path "$MountDirectory\Windows\System32\winpeshl.ini") {
                            Remove-Item -Path "$MountDirectory\Windows\System32\winpeshl.ini" -Force | Out-Null
                        }
                        $DaRTwinpeshl | Out-File "$MountDirectory\Windows\System32\winpeshl.ini" -Force
                    }
                    #======================================================================================
                } else {Write-Warning "WinPE DaRT do not exist in $OSBuilderContent\$WinPEDart"}
            }
            #======================================================================================
            #   WinPE Remove winpeshl.ini
            #======================================================================================
            if ($PEOutput -ne 'Recovery') {
                Write-Host "===========================================================================" -ForegroundColor Yellow
                Write-Host "WinPE Phase: Remove winpeshl.ini" -ForegroundColor Yellow
                if (Test-Path "$MountDirectory\Windows\System32\winpeshl.ini") {
                    Remove-Item -Path "$MountDirectory\Windows\System32\winpeshl.ini" -Force | Out-Null
                }
            }
            #======================================================================================
            #   Copy MDT 18.10.12
            #======================================================================================
            if ($DeploymentShare) {
                $MDTwinpeshl | Out-File "$MountDirectory\Windows\System32\winpeshl.ini" -Force

                if ($OSArchitecture -eq 'x86') {$MDTUnattendPEx86 | Out-File "$MountDirectory\Unattend.xml" -Encoding utf8 -Force}
                if ($OSArchitecture -eq 'x64') {$MDTUnattendPEx64 | Out-File "$MountDirectory\Unattend.xml" -Encoding utf8 -Force}

                New-Item -Path "$MountDirectory\Deploy\Scripts" -ItemType Directory -Force | Out-Null
                New-Item -Path "$MountDirectory\Deploy\Tools\$OSArchitecture\00000409" -ItemType Directory -Force | Out-Null

                Copy-Item -Path "$DeploymentShare\Control\Bootstrap.ini" -Destination "$MountDirectory\Deploy\Scripts\Bootstrap.ini" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Control\LocationServer.xml" -Destination "$MountDirectory\Deploy\Scripts\LocationServer.xml" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\BDD_Welcome_ENU.xml" -Destination "$MountDirectory\Deploy\Scripts\BDD_Welcome_ENU.xml" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\BackButton.jpg" -Destination "$MountDirectory\Deploy\Scripts\BackButton.jpg" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\BackButton.png" -Destination "$MountDirectory\Deploy\Scripts\BackButton.png" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\Computer.png" -Destination "$MountDirectory\Deploy\Scripts\Computer.png" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\Credentials_ENU.xml" -Destination "$MountDirectory\Deploy\Scripts\Credentials_ENU.xml" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\Credentials_scripts.vbs" -Destination "$MountDirectory\Deploy\Scripts\Credentials_scripts.vbs" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\DeployWiz_Administrator.png" -Destination "$MountDirectory\Deploy\Scripts\DeployWiz_Administrator.png" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\FolderIcon.png" -Destination "$MountDirectory\Deploy\Scripts\FolderIcon.png" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\ItemIcon1.png" -Destination "$MountDirectory\Deploy\Scripts\ItemIcon1.png" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\LTICleanup.wsf" -Destination "$MountDirectory\Deploy\Scripts\LTICleanup.wsf" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\LTIGetFolder.wsf" -Destination "$MountDirectory\Deploy\Scripts\LTIGetFolder.wsf" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\LiteTouch.wsf" -Destination "$MountDirectory\Deploy\Scripts\LiteTouch.wsf" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\MinusIcon1.png" -Destination "$MountDirectory\Deploy\Scripts\MinusIcon1.png" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\NICSettings_Definition_ENU.xml" -Destination "$MountDirectory\Deploy\Scripts\NICSettings_Definition_ENU.xml" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\NavBar.png" -Destination "$MountDirectory\Deploy\Scripts\NavBar.png" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\PlusIcon1.png" -Destination "$MountDirectory\Deploy\Scripts\PlusIcon1.png" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\SelectItem.jpg" -Destination "$MountDirectory\Deploy\Scripts\SelectItem.jpg" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\SelectItem.png" -Destination "$MountDirectory\Deploy\Scripts\SelectItem.png" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\Summary_Definition_ENU.xml" -Destination "$MountDirectory\Deploy\Scripts\Summary_Definition_ENU.xml" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\Summary_scripts.vbs" -Destination "$MountDirectory\Deploy\Scripts\Summary_scripts.vbs" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\WelcomeBanner.jpg" -Destination "$MountDirectory\Deploy\Scripts\WelcomeBanner.jpg" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\WelcomeWiz_Background.jpg" -Destination "$MountDirectory\Deploy\Scripts\WelcomeWiz_Background.jpg" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\WelcomeWiz_Choice.vbs" -Destination "$MountDirectory\Deploy\Scripts\WelcomeWiz_Choice.vbs" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\WelcomeWiz_Choice.xml" -Destination "$MountDirectory\Deploy\Scripts\WelcomeWiz_Choice.xml" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\WelcomeWiz_DeployRoot.vbs" -Destination "$MountDirectory\Deploy\Scripts\WelcomeWiz_DeployRoot.vbs" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\WelcomeWiz_DeployRoot.xml" -Destination "$MountDirectory\Deploy\Scripts\WelcomeWiz_DeployRoot.xml" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\WelcomeWiz_Initialize.vbs" -Destination "$MountDirectory\Deploy\Scripts\WelcomeWiz_Initialize.vbs" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\WelcomeWiz_Initialize.xml" -Destination "$MountDirectory\Deploy\Scripts\WelcomeWiz_Initialize.xml" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\WizUtility.vbs" -Destination "$MountDirectory\Deploy\Scripts\WizUtility.vbs" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\Wizard.css" -Destination "$MountDirectory\Deploy\Scripts\Wizard.css" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\Wizard.hta" -Destination "$MountDirectory\Deploy\Scripts\Wizard.hta" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\Wizard.ico" -Destination "$MountDirectory\Deploy\Scripts\Wizard.ico" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\ZTIBCDUtility.vbs" -Destination "$MountDirectory\Deploy\Scripts\ZTIBCDUtility.vbs" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\ZTIConfigFile.vbs" -Destination "$MountDirectory\Deploy\Scripts\ZTIConfigFile.vbs" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\ZTIDataAccess.vbs" -Destination "$MountDirectory\Deploy\Scripts\ZTIDataAccess.vbs" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\ZTIDiskUtility.vbs" -Destination "$MountDirectory\Deploy\Scripts\ZTIDiskUtility.vbs" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\ZTIGather.wsf" -Destination "$MountDirectory\Deploy\Scripts\ZTIGather.wsf" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\ZTIGather.xml" -Destination "$MountDirectory\Deploy\Scripts\ZTIGather.xml" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\ZTINicConfig.wsf" -Destination "$MountDirectory\Deploy\Scripts\ZTINicConfig.wsf" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\ZTINicUtility.vbs" -Destination "$MountDirectory\Deploy\Scripts\ZTINicUtility.vbs" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\ZTIUtility.vbs" -Destination "$MountDirectory\Deploy\Scripts\ZTIUtility.vbs" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\btnout.png" -Destination "$MountDirectory\Deploy\Scripts\btnout.png" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\btnover.png" -Destination "$MountDirectory\Deploy\Scripts\btnover.png" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\btnsel.png" -Destination "$MountDirectory\Deploy\Scripts\btnsel.png" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\header-image.png" -Destination "$MountDirectory\Deploy\Scripts\header-image.png" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\minusico.gif" -Destination "$MountDirectory\Deploy\Scripts\minusico.gif" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Scripts\plusicon.gif" -Destination "$MountDirectory\Deploy\Scripts\plusicon.gif" -Force -ErrorAction SilentlyContinue | Out-Null

                Copy-Item -Path "$DeploymentShare\Tools\$OSArchitecture\00000409\tsres.dll" -Destination "$MountDirectory\Deploy\Tools\$OSArchitecture\00000409\tsres.dll" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Tools\$OSArchitecture\BDDRUN.exe" -Destination "$MountDirectory\Windows\system32\BDDRUN.exe" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Tools\$OSArchitecture\BGInfo.exe" -Destination "$MountDirectory\Windows\system32\BGInfo.exe" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Tools\$OSArchitecture\BGInfo64.exe" -Destination "$MountDirectory\Windows\system32\BGInfo64.exe" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Tools\$OSArchitecture\CcmCore.dll" -Destination "$MountDirectory\Deploy\Tools\$OSArchitecture\CcmCore.dll" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Tools\$OSArchitecture\CcmUtilLib.dll" -Destination "$MountDirectory\Deploy\Tools\$OSArchitecture\CcmUtilLib.dll" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Tools\$OSArchitecture\Microsoft.BDD.Utility.dll" -Destination "$MountDirectory\Deploy\Tools\$OSArchitecture\Microsoft.BDD.Utility.dll" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Tools\$OSArchitecture\SmsCore.dll" -Destination "$MountDirectory\Deploy\Tools\$OSArchitecture\SmsCore.dll" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Tools\$OSArchitecture\Smsboot.exe" -Destination "$MountDirectory\Deploy\Tools\$OSArchitecture\Smsboot.exe" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Tools\$OSArchitecture\TSEnv.exe" -Destination "$MountDirectory\Deploy\Tools\$OSArchitecture\TSEnv.exe" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Tools\$OSArchitecture\TSResNlc.dll" -Destination "$MountDirectory\Deploy\Tools\$OSArchitecture\TSResNlc.dll" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Tools\$OSArchitecture\TsCore.dll" -Destination "$MountDirectory\Deploy\Tools\$OSArchitecture\TsCore.dll" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Tools\$OSArchitecture\TsManager.exe" -Destination "$MountDirectory\Deploy\Tools\$OSArchitecture\TsManager.exe" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Tools\$OSArchitecture\TsMessaging.dll" -Destination "$MountDirectory\Deploy\Tools\$OSArchitecture\TsMessaging.dll" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Tools\$OSArchitecture\TsProgressUI.exe" -Destination "$MountDirectory\Deploy\Tools\$OSArchitecture\TsProgressUI.exe" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Tools\$OSArchitecture\TsmBootstrap.exe" -Destination "$MountDirectory\Deploy\Tools\$OSArchitecture\TsmBootstrap.exe" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Tools\$OSArchitecture\WinRERUN.exe" -Destination "$MountDirectory\Deploy\Tools\$OSArchitecture\WinRERUN.exe" -Force -ErrorAction SilentlyContinue | Out-Null

                Copy-Item -Path "$DeploymentShare\Tools\$OSArchitecture\xprslib.dll" -Destination "$MountDirectory\Deploy\Tools\$OSArchitecture\xprslib.dll" -Force -ErrorAction SilentlyContinue | Out-Null

                Copy-Item -Path "$DeploymentShare\Tools\$OSArchitecture\CommonUtils.dll" -Destination "$MountDirectory\Deploy\Tools\$OSArchitecture\CommonUtils.dll" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Tools\$OSArchitecture\ccmgencert.dll" -Destination "$MountDirectory\Deploy\Tools\$OSArchitecture\ccmgencert.dll" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Tools\$OSArchitecture\msvcp120.dll" -Destination "$MountDirectory\Deploy\Tools\$OSArchitecture\msvcp120.dll" -Force -ErrorAction SilentlyContinue | Out-Null
                Copy-Item -Path "$DeploymentShare\Tools\$OSArchitecture\msvcr120.dll" -Destination "$MountDirectory\Deploy\Tools\$OSArchitecture\msvcr120.dll" -Force -ErrorAction SilentlyContinue | Out-Null
                #[void](Read-Host 'Press Enter to Continue')
            }
            #======================================================================================
            #   WinPE Auto ExtraFiles 18.10.14
            #======================================================================================
            if ($AutoExtraFiles) {
                Write-Host "===========================================================================" -ForegroundColor Yellow
                Write-Host "WinPE Phase: Auto ExtraFiles" -ForegroundColor Yellow
                robocopy "$OSSourcePath\WinPE\AutoExtraFiles" "$MountDirectory" *.* /e /ndl /xx /b /np /ts /tee /r:0 /w:0 /log:"$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-AutoExtraFiles.log"
            }
            #======================================================================================
            #   WinPE Phase: Extra Files 18.10.11
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: Extra Files" -ForegroundColor Yellow
            foreach ($ExtraFile in $WinPEExtraFiles) {robocopy "$OSBuilderContent\$ExtraFile" "$MountDirectory" *.* /e /ndl /xx /b /np /ts /tee /r:0 /w:0 /log:"$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-ExtraFiles.log"}
            #======================================================================================
            #   WinPE Phase: Drivers 18.10.11
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: Drivers" -ForegroundColor Yellow
            foreach ($WinPEDriver in $WinPEDrivers) {
                Write-Host "$OSBuilderContent\$WinPEDriver" -ForegroundColor Cyan
                Add-WindowsDriver -Path "$MountDirectory" -Driver "$OSBuilderContent\$WinPEDriver" -Recurse -ForceUnsigned -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Add-WindowsDriver.log" | Out-Null
            }
            #======================================================================================
            #   WinPE Wallpaper 18.10.14
            #======================================================================================
<#             if ($WinPEWallpaper) {
                Write-Host "===========================================================================" -ForegroundColor Yellow
                Write-Host "WinPE Wallpaper ..." -ForegroundColor Yellow
                Write-Host "$OSBuilderContent\$WinPEWallpaper ..." -ForegroundColor Yellow
                Copy-Item "$OSBuilderContent\$WinPEWallpaper" -Destination "$OSBuilderContent\Windows\System32\Setup.jpg" -Force
                Copy-Item "$OSBuilderContent\$WinPEWallpaper" -Destination "$OSBuilderContent\Windows\System32\WinPE.jpg" -Force
                Copy-Item "$OSBuilderContent\$WinPEWallpaper" -Destination "$OSBuilderContent\Windows\System32\WinRE.jpg" -Force
            } #>
            #======================================================================================
            #   WinPE Phase: PowerShell Scripts 18.10.17
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: PowerShell Scripts" -ForegroundColor Yellow
            foreach ($PSWimScript in $WinPEScripts) {
                if (Test-Path "$OSBuilderContent\$PSWimScript") {
                    Write-Host "$OSBuilderContent\$PSWimScript" -ForegroundColor Cyan
                    Invoke-Expression "& '$OSBuilderContent\$PSWimScript'"
                }
            }
            #======================================================================================
            #   WinPE Mounted Package Inventory 18.10.11
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: Exporting Package Inventory" -ForegroundColor Yellow
            Write-Host "$Info\WindowsPackage.txt"
            $GetWindowsPackage = Get-WindowsPackage -Path "$MountDirectory"
            $GetWindowsPackage | Out-File "$Info\WindowsPackage.txt"
            $GetWindowsPackage | Out-File "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsPackage.txt"
            $GetWindowsPackage | Export-Clixml -Path "$LogsXML\Get-WindowsPackage.xml"
            $GetWindowsPackage | Export-Clixml -Path "$LogsXML\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsPackage.xml"
            $GetWindowsPackage | ConvertTo-Json | Out-File "$LogsJS\Get-WindowsPackage.json"
            $GetWindowsPackage | ConvertTo-Json | Out-File "$LogsJS\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsPackage.json"
            #======================================================================================
            #	WinPE Dismount and Save 18.10.11
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: Dismount and Save" -ForegroundColor Yellow
            if ($PromptBeforeDismount.IsPresent){[void](Read-Host 'Press Enter to Continue')}
            Dismount-WindowsImage -Path "$MountDirectory" -Save -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dismount-WindowsImage.log" | Out-Null
            #======================================================================================
            #	Export WinPE 18.10.11
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "WinPE Phase: Exporting WinPE WIMs" -ForegroundColor Yellow
            Write-Host "Exporting to $Sources\boot.wim"
            Write-Host "Destination Name: $TaskName"
            Export-WindowsImage -SourceImagePath "$WimTemp\boot.wim" -SourceIndex 1 -DestinationImagePath "$Sources\boot.wim" -Setbootable -DestinationName "$TaskName" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Export-WindowsImage.log" | Out-Null
            #======================================================================================
            #   Saving WinPE Image Configuration 18.10.2
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Inventory Phase: Saving WinPE Image Configuration" -ForegroundColor Yellow
            #======================================================================================
            #   Saving Windows Image Configuration 18.10.11
            #======================================================================================
            Write-Host "===========================================================================" -ForegroundColor Yellow
            Write-Host "Inventory Phase: Saving Windows Image Configuration" -ForegroundColor Yellow
            Write-Host "$WorkingPath\WindowsImage.txt"
            $GetWindowsImage = Get-WindowsImage -ImagePath "$OS\sources\boot.wim" -Index 1 | Select-Object -Property *
            $GetWindowsImage | Add-Member -Type NoteProperty -Name "UBR" -Value $UBR
            $GetWindowsImage | Out-File "$WorkingPath\WindowsImage.txt"
            $GetWindowsImage | Out-File "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsImage.txt"
            $GetWindowsImage | Export-Clixml -Path "$LogsXML\Get-WindowsImage.xml"
            $GetWindowsImage | Export-Clixml -Path "$LogsXML\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsImage.xml"
            $GetWindowsImage | ConvertTo-Json | Out-File "$LogsJS\Get-WindowsImage.json"
            $GetWindowsImage | ConvertTo-Json | Out-File "$LogsJS\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsImage.json"
            (Get-Content "$WorkingPath\WindowsImage.txt") | Where-Object {$_.Trim(" `t")} | Set-Content "$WorkingPath\WindowsImage.txt"
            #======================================================================================
            #   Get-WindowsImageContent 18.10.11
            #======================================================================================
            Write-Host "$Info\Get-WindowsImageContent.txt"  
            Get-WindowsImageContent -ImagePath "$OS\Sources\boot.wim" -Index 1 | Out-File "$Info\Get-WindowsImageContent.txt"
            #======================================================================================
            #   Display OS Information 18.10.2
            #======================================================================================
            Show-OSInfo $WorkingPath
            #======================================================================================
            #   Remove Temporary Files 18.10.11
            #======================================================================================
            if (Test-Path "$WimTemp") {Remove-Item -Path "$WimTemp" -Force -Recurse | Out-Null}
            if (Test-Path "$MountDirectory") {Remove-Item -Path "$MountDirectory" -Force -Recurse | Out-Null}
            #======================================================================================
            #   Create Variables 18.10.15
            #======================================================================================
            Get-Variable | Select-Object -Property Name, Value | Export-Clixml "$LogsXML\Variables.xml"
            Get-Variable | Select-Object -Property Name, Value | ConvertTo-Json | Out-File "$LogsJS\Variables.json"
            #======================================================================================
            #   Close 18.10.11
            #======================================================================================
            Stop-Transcript
        }
        Write-Host "===========================================================================" -ForegroundColor Green
        Write-Host "Complete!" -ForegroundColor Green
        Write-Host "===========================================================================" -ForegroundColor Green
    }
}