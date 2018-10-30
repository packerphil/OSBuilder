function Import-OSMedia {
    [CmdletBinding()]
    Param (
        [ValidateSet('Education','EducationN','Enterprise','EnterpriseN','EnterpriseS','EnterpriseSN','Professional','ProfessionalEducation','ProfessionalEducationN','ProfessionalN','ProfessionalWorkstation','ProfessionalWorkstationN','ServerDatacenter','ServerDatacenterACor','ServerRdsh','ServerStandard','ServerStandardACor')]
        [string]$EditionId,
        [Int]$ImageIndex,
        [ValidateSet('Windows 10 Education','Windows 10 Education N','Windows 10 Enterprise','Windows 10 Enterprise 2016 LTSB','Windows 10 Enterprise for Virtual Desktops','Windows 10 Enterprise LTSC','Windows 10 Enterprise N','Windows 10 Enterprise N LTSC','Windows 10 Pro','Windows 10 Pro Education','Windows 10 Pro Education N','Windows 10 Pro for Workstations','Windows 10 Pro N','Windows 10 Pro N for Workstations','Windows Server 2016 Datacenter','Windows Server 2016 Datacenter (Desktop Experience)','Windows Server 2016 Standard','Windows Server 2016 Standard (Desktop Experience)','Windows Server 2019 Datacenter','Windows Server 2019 Datacenter (Desktop Experience)','Windows Server 2019 Standard','Windows Server 2019 Standard (Desktop Experience)','Windows Server Datacenter','Windows Server Standard')]
        [string]$ImageName,
        [switch]$SkipGridView,
        [switch]$UpdateOSMedia
    )
    #======================================================================================
    #   Start 18.9.13
    #======================================================================================
    Write-Host "===========================================================================" -ForegroundColor Green
    Write-Host "Import-OSMedia" -ForegroundColor Green
    Write-Host "===========================================================================" -ForegroundColor Green
    #======================================================================================
    #	Validate Administrator Rights 18.9.13
    #======================================================================================
    if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
            [Security.Principal.WindowsBuiltInRole] "Administrator"))
    {
        Write-Host ""
        Write-Host "This function needs to be run as Administrator" -ForegroundColor Yellow
        Write-Host ""
        Return
    }
    #======================================================================================
    #	Initialize OSBuilder 18.9.13
    #======================================================================================
    Get-OSBuilder -CreatePaths -HideDetails
    #======================================================================================
    #	Check Drives for Images 18.10.3
    #======================================================================================
    $ImportWims = @()
    $ImportDrives = Get-PSDrive -PSProvider 'FileSystem'
    foreach ($ImportDrive in $ImportDrives) {
        if (Test-Path "$($ImportDrive.Root)Sources") {$ImportWims += Get-ChildItem "$($ImportDrive.Root)Sources" install.* | Select-Object -Property @{Name="OSRoot";Expression={(Get-Item $_.Directory).Parent.FullName}}, @{Name="OSWim";Expression={$_.FullName}}}
        if (Test-Path "$($ImportDrive.Root)x64\Sources") {$ImportWims += Get-ChildItem "$($ImportDrive.Root)x64\Sources" install.* | Select-Object -Property @{Name="OSRoot";Expression={(Get-Item $_.Directory).Parent.FullName}}, @{Name="OSWim";Expression={$_.FullName}}}
        if (Test-Path "$($ImportDrive.Root)x86\Sources") {$ImportWims += Get-ChildItem "$($ImportDrive.Root)x86\Sources" install.* | Select-Object -Property @{Name="OSRoot";Expression={(Get-Item $_.Directory).Parent.FullName}}, @{Name="OSWim";Expression={$_.FullName}}}
    }
    if ($null -eq $ImportWims) {
        Write-Warning "Windows Image could not be found on any CD or DVD Drives . . . Exiting!"
        Return
    }
    #======================================================================================
    #	Scan Drives 18.9.13
    #======================================================================================
    Write-Host "Scanning Image Information ... Please Wait!" -ForegroundColor Yellow
    #======================================================================================
    $WindowsImages = $ImportWims | ForEach-Object {Get-WindowsImage -ImagePath "$($_.OSWim)"} | ForEach-Object {Get-WindowsImage -ImagePath "$($_.ImagePath)" -Index $($_.ImageIndex) | Select-Object -Property * }
    $WindowsImages = $WindowsImages | Select-Object -Property ImagePath, ImageIndex, Languages, ImageName, Architecture, EditionId, Version, MajorVersion, MinorVersion, Build, SPBuild, SPLevel, CreatedTime, ModifiedTime
    foreach ($Image in $WindowsImages) {
        $Image.Architecture = $Image.Architecture -replace "1", "MIPS"
        $Image.Architecture = $Image.Architecture -replace "2", "Alpha"
        $Image.Architecture = $Image.Architecture -replace "3", "PowerPC"
        $Image.Architecture = $Image.Architecture -replace "6", "ia64"
        $Image.Architecture = $Image.Architecture -replace "9", "x64"
        $Image.Architecture = $Image.Architecture -replace "0", "x86"
        #$Image.ImageName = $Image.ImageName -replace "ServerStandardACore", "Standard Core"
        #$Image.ImageName = $Image.ImageName -replace "ServerDatacenterACore", "Datacenter Core"
        #$Image.ImageName = $Image.ImageName -replace "ServerStandardCore", "Standard Core"
        #$Image.ImageName = $Image.ImageName -replace "ServerDatacenterCore", "Datacenter Core"
        #$Image.ImageName = $Image.ImageName -replace "ServerStandard", "Standard"
        #$Image.ImageName = $Image.ImageName -replace "ServerDatacenter", "Datacenter"
    }
    #======================================================================================
    #   18.10.25    Windows 10, Windows Server 2016, Windows Server 2019
    #======================================================================================
    #$WindowsImages = $WindowsImages | Where-Object {$_.MajorVersion -eq '6' -or $_.MajorVersion -eq '10'}
    $WindowsImages = $WindowsImages | Where-Object {$_.MajorVersion -eq '10'}
    #======================================================================================
    #   18.10.24    Parameter Filter
    #======================================================================================
    if ($EditionId) {$WindowsImages = $WindowsImages | Where-Object {$_.EditionId -eq $EditionId}}
    if ($ImageName) {$WindowsImages = $WindowsImages | Where-Object {$_.ImageName -eq $ImageName}}
    if ($ImageIndex) {$WindowsImages = $WindowsImages | Where-Object {$_.ImageIndex -eq $ImageIndex}}
    #======================================================================================
    #   18.10.24    GridView
    #======================================================================================
    if (@($WindowsImages).Count -gt 0) {
        if (!($SkipGridView.IsPresent)) {
            $WindowsImages = $WindowsImages | Out-GridView -Title "Import-OSMedia: Select OSMedia to Import and press OK (Cancel to Exit)" -PassThru        
            if($null -eq $WindowsImages) {
                Write-Warning "OSMedia was not selected . . . Exiting!"
                Return
            }
        }
    } else {
        Write-Warning "OSMedia was not found . . . Exiting!"
        Return
    }
    #======================================================================================
    #	Import Images 18.10.4
    #======================================================================================
    foreach ($WindowsImage in $WindowsImages) {
        #Get-WindowsImage -ImagePath "$($WindowsImage.ImagePath)" -Index $($WindowsImage.ImageIndex) | Select-Object -Property *
        $OSImagePath = $($WindowsImage.ImagePath)
        $OSImageIndex = $($WindowsImage.ImageIndex)
        $OSSourcePath = (Get-Item $OSImagePath).Directory.Parent.FullName
        $WindowsImage = Get-WindowsImage -ImagePath "$OSImagePath" -Index $OSImageIndex | Select-Object -Property *

        $OSImageName = $($WindowsImage.ImageName)
        $OSImageName = $OSImageName -replace "Windows 7", "Win7"
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

        $OSImageDescription = $($WindowsImage.ImageDescription)
        $OSArchitecture = $($WindowsImage.Architecture)
        if ($OSArchitecture -eq 0) {$OSArchitecture = 'x86'}
        elseif ($OSArchitecture -eq 1) {$OSArchitecture = 'MIPS'}
        elseif ($OSArchitecture -eq 2) {$OSArchitecture = 'Alpha'}
        elseif ($OSArchitecture -eq 3) {$OSArchitecture = 'PowerPC'}
        elseif ($OSArchitecture -eq 6) {$OSArchitecture = 'ia64'}
        elseif ($OSArchitecture -eq 9) {$OSArchitecture = 'x64'}
        $OSEditionID = $($WindowsImage.EditionId)
        $OSInstallationType = $($WindowsImage.InstallationType)
        $OSLanguages = $($WindowsImage.Languages)
        $OSMajorVersion = $($WindowsImage.MajorVersion)
        $OSBuild = $($WindowsImage.Build)
        $OSVersion = $($WindowsImage.Version)
        $OSSPBuild = $($WindowsImage.SPBuild)
        $OSSPLevel = $($WindowsImage.SPLevel)
        $OSImageBootable = $($WindowsImage.ImageBootable)
        $OSWIMBoot = $($WindowsImage.WIMBoot)
        $OSCreatedTime = $($WindowsImage.CreatedTime)
        $OSModifiedTime = $($WindowsImage.ModifiedTime)
        #======================================================================================
        #	Export Install.esd 18.10.4
        #======================================================================================
        if ($OSImagePath -like "*.esd") {
            $InstallWimType = "esd"
            $TempESD = "$env:Temp\$((Get-Date).ToString('HHmmss')).wim"
            Write-Host "Exporting Install.esd Index $OSImageIndex to $TempESD"
            Export-WindowsImage -SourceImagePath "$OSImagePath" -SourceIndex $OSImageIndex -DestinationImagePath "$TempESD" -CheckIntegrity -CompressionType max -LogPath "$env:Temp\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Export-WindowsImage.log"
        } else {
            $InstallWimType = "wim"
        }
        #======================================================================================
        #	Mount Install.wim 18.9.13
        #======================================================================================
        Write-Host "===========================================================================" -ForegroundColor Yellow
        Write-Host "Mounting Install.$InstallWimType" -ForegroundColor Yellow
        $MountDirectory = Join-Path $OSBuilderContent\Mount "os$((Get-Date).ToString('HHmmss'))"
        if (!(Test-Path "$MountDirectory")) {New-Item "$MountDirectory" -ItemType Directory -Force | Out-Null}
        if ($InstallWimType -eq "esd") {
            Write-Host "$TempESD"
            Mount-WindowsImage -ImagePath "$TempESD" -Index '1' -Path "$MountDirectory" -Optimize -ReadOnly
        } else {
            Write-Host "$OSImagePath"
            Mount-WindowsImage -ImagePath "$OSImagePath" -Index $OSImageIndex -Path "$MountDirectory" -Optimize -ReadOnly
        }
        #======================================================================================
        #	Get Registry and UBR 18.9.20
        #======================================================================================
        Write-Host "===========================================================================" -ForegroundColor Yellow
        Write-Host "Mounting Registry for UBR Information" -ForegroundColor Yellow
        reg LOAD 'HKLM\OSMedia' "$MountDirectory\Windows\System32\Config\SOFTWARE"
        $RegCurrentVersion = Get-ItemProperty -Path 'HKLM:\OSMedia\Microsoft\Windows NT\CurrentVersion'
        reg UNLOAD 'HKLM\OSMedia'

        $OSVersionNumber = $null
        $RegCurrentVersionUBR = $null
        #======================================================================================
        #   18.10.25    Set OS Main Information
        #======================================================================================
        if ($OSMajorVersion -eq '10') {
            $OSVersionNumber = $($RegCurrentVersion.ReleaseId)
            $RegCurrentVersionUBR = $($RegCurrentVersion.UBR)
            $UBR = "$OSBuild.$RegCurrentVersionUBR"
            if ($OSVersionNumber -gt 1809) {Write-Warning "OSBuilder does not currently support this version of Windows ... Check for an updated version"}
            $OSMediaName = "$OSImageName $OSArchitecture $OSVersionNumber $OSLanguages $UBR"
        } else {
            $UBR = "$OSBuild.$OSSPBuild"
            $OSMediaName = "$OSImageName $OSArchitecture $OSLanguages $UBR"
        }
        if ($($OSLanguages.count) -eq 1) {$OSMediaName = $OSMediaName.replace(' en-US', '')}
        #======================================================================================
        #	 Set WorkingPath 18.9.13
        #======================================================================================
        $WorkingPath = Join-Path $OSBuilderOSMedia $OSMediaName
        Write-Host "Working Path $WorkingPath "
        #======================================================================================
        #	Remove Existing Content 18.9.13
        #======================================================================================
        if (Test-Path $WorkingPath) {
            Write-Warning "$WorkingPath exists.  Contents will be replaced!"
            Remove-Item -Path "$WorkingPath" -Force -Recurse
            Write-Host ""
        }
        #======================================================================================
        #	Working Directories 18.9.13
        #======================================================================================
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
        #======================================================================================
        #	Export RegCurrentVersion 18.9.20
        #======================================================================================
        $RegCurrentVersion | Out-File "$Info\CurrentVersion.txt"
        $RegCurrentVersion | Out-File "$WorkingPath\CurrentVersion.txt"
        $RegCurrentVersion | Out-File "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-CurrentVersion.txt"
        $RegCurrentVersion | Export-Clixml -Path "$LogsXML\CurrentVersion.xml"
        $RegCurrentVersion | Export-Clixml -Path "$LogsXML\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-CurrentVersion.xml"
        $RegCurrentVersion | ConvertTo-Json | Out-File "$LogsJS\CurrentVersion.json"
        $RegCurrentVersion | ConvertTo-Json | Out-File "$LogsJS\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-CurrentVersion.json"
        #======================================================================================
        #	Start the Transcript 18.9.13
        #======================================================================================
        $ScriptName = $MyInvocation.MyCommand.Name
        $LogName = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-$ScriptName.log"
        Start-Transcript -Path (Join-Path $Logs $LogName)
        Write-Host "===========================================================================" -ForegroundColor Yellow
        Write-Host "OSMedia Information" -ForegroundColor Yellow
        Write-Host "===========================================================================" -ForegroundColor Yellow
        Write-Host "Source Path:		$OSSourcePath" -ForegroundColor Yellow
        Write-Host "-Image File:		$OSImagePath" -ForegroundColor Cyan
        Write-Host "-Image Index:		$OSImageIndex" -ForegroundColor Cyan
        Write-Host "-Name:				$OSImageName" -ForegroundColor Cyan
        Write-Host "-Description:		$OSImageDescription" -ForegroundColor Cyan
        Write-Host "-Architecture:		$OSArchitecture" -ForegroundColor Cyan
        Write-Host "-Edition:			$OSEditionID" -ForegroundColor Cyan
        Write-Host "-Type:				$OSInstallationType" -ForegroundColor Cyan
        Write-Host "-Languages:			$OSLanguages" -ForegroundColor Cyan
        Write-Host "-Build:				$OSBuild" -ForegroundColor Cyan
        Write-Host "-Version:			$OSVersion" -ForegroundColor Cyan
        Write-Host "-SPBuild:			$OSSPBuild" -ForegroundColor Cyan
        Write-Host "-SPLevel:			$OSSPLevel" -ForegroundColor Cyan
        Write-Host "-Bootable:			$OSImageBootable" -ForegroundColor Cyan
        Write-Host "-WimBoot:			$OSWIMBoot" -ForegroundColor Cyan
        Write-Host "-Created Time:		$OSCreatedTime" -ForegroundColor Cyan
        Write-Host "-Modified Time:		$OSModifiedTime" -ForegroundColor Cyan
        Write-Host "-UBR:				$UBR" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Working Path:		$WorkingPath" -ForegroundColor Yellow
        Write-Host "-OSMedia Name:		$OSMediaName" -ForegroundColor Cyan
        Write-Host "-Info:				$Info" -ForegroundColor Cyan
        Write-Host "-Logs:				$Logs" -ForegroundColor Cyan
        Write-Host "-OS:				$OS" -ForegroundColor Cyan
        Write-Host "-WinPE:				$WinPE" -ForegroundColor Cyan
        #======================================================================================
        #	 Import Operating System 18.9.13
        #======================================================================================
        Write-Host "===========================================================================" -ForegroundColor Yellow
        Write-Host "Importing Operating System to OSMedia" -ForegroundColor Yellow
        #======================================================================================
        Write-Host "Copying OS to $OS"
        Copy-Item -Path "$OSSourcePath\*" -Destination "$OS" -Exclude "install.$InstallWimType" -Recurse -Force | Out-Null
        Write-Host "Removing the Read Only file flag in $OS"
        Get-ChildItem -Recurse -Path "$OS\*" | Set-ItemProperty -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue | Out-Null

        Write-Host "Exporting Index $OSImageIndex to $OS\sources\install.wim"
        if ($InstallWimType -eq "esd") {
            Export-WindowsImage -SourceImagePath "$TempESD" -SourceIndex 1 -DestinationImagePath "$OS\sources\install.wim" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Export-WindowsImage.log"
        } else {
            Export-WindowsImage -SourceImagePath "$OSImagePath" -SourceIndex $OSImageIndex -DestinationImagePath "$OS\sources\install.wim" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Export-WindowsImage.log"
        }
        #======================================================================================
        #	 Save Mounted Windows Image Configuration 18.9.13
        #======================================================================================
        Write-Host "===========================================================================" -ForegroundColor Yellow
        Write-Host "Saving Mounted Windows Image Configuration" -ForegroundColor Yellow
        #[void](Read-Host 'Press Enter to Continue')
        #======================================================================================
        $GetAppxProvisionedPackage = @()
        if ($OSMajorVersion -eq '10' -and $OSImageName -notlike "*server*") {$GetAppxProvisionedPackage = Get-AppxProvisionedPackage -Path "$MountDirectory"}
        else {Write-Warning "Get-AppxProvisionedPackage is not supported by this Operating System"}
        Write-Host "$WorkingPath\AppxProvisionedPackage.txt"
        $GetAppxProvisionedPackage | Out-File "$Info\Get-AppxProvisionedPackage.txt"
        $GetAppxProvisionedPackage | Out-File "$WorkingPath\AppxProvisionedPackage.txt"
        $GetAppxProvisionedPackage | Out-File "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-AppxProvisionedPackage.txt"
        $GetAppxProvisionedPackage | Export-Clixml -Path "$LogsXML\Get-AppxProvisionedPackage.xml"
        $GetAppxProvisionedPackage | Export-Clixml -Path "$LogsXML\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-AppxProvisionedPackage.xml"
        $GetAppxProvisionedPackage | ConvertTo-Json | Out-File "$LogsJS\Get-AppxProvisionedPackage.json"
        $GetAppxProvisionedPackage | ConvertTo-Json | Out-File "$LogsJS\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-AppxProvisionedPackage.json"

        $GetWindowsOptionalFeature = @()
        Write-Host "$WorkingPath\WindowsOptionalFeature.txt"
        if ($OSMajorVersion -eq '10') {$GetWindowsOptionalFeature = Get-WindowsOptionalFeature -Path "$MountDirectory"}
        $GetWindowsOptionalFeature | Out-File "$Info\Get-WindowsOptionalFeature.txt"
        $GetWindowsOptionalFeature | Out-File "$WorkingPath\WindowsOptionalFeature.txt"
        $GetWindowsOptionalFeature | Out-File "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsOptionalFeature.txt"
        $GetWindowsOptionalFeature | Export-Clixml -Path "$LogsXML\Get-WindowsOptionalFeature.xml"
        $GetWindowsOptionalFeature | Export-Clixml -Path "$LogsXML\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsOptionalFeature.xml"
        $GetWindowsOptionalFeature | ConvertTo-Json | Out-File "$LogsJS\Get-WindowsOptionalFeature.json"
        $GetWindowsOptionalFeature | ConvertTo-Json | Out-File "$LogsJS\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsOptionalFeature.json"

        $GetWindowsCapability = @()
        Write-Host "$WorkingPath\WindowsCapability.txt"
        if ($OSMajorVersion -eq '10') {$GetWindowsCapability = Get-WindowsCapability -Path "$MountDirectory"}
        $GetWindowsCapability | Out-File "$Info\Get-WindowsCapability.txt"
        $GetWindowsCapability | Out-File "$WorkingPath\WindowsCapability.txt"
        $GetWindowsCapability | Out-File "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsCapability.txt"
        $GetWindowsCapability | Export-Clixml -Path "$LogsXML\Get-WindowsCapability.xml"
        $GetWindowsCapability | Export-Clixml -Path "$LogsXML\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsCapability.xml"
        $GetWindowsCapability | ConvertTo-Json | Out-File "$LogsJS\Get-WindowsCapability.json"
        $GetWindowsCapability | ConvertTo-Json | Out-File "$LogsJS\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsCapability.json"

        $GetWindowsPackage = @()
        Write-Host "$WorkingPath\WindowsPackage.txt"
        if ($OSMajorVersion -eq '10') {$GetWindowsPackage = Get-WindowsPackage -Path "$MountDirectory"}
        $GetWindowsPackage | Out-File "$Info\Get-WindowsPackage.txt"
        $GetWindowsPackage | Out-File "$WorkingPath\WindowsPackage.txt"
        $GetWindowsPackage | Out-File "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsPackage.txt"
        $GetWindowsPackage | Export-Clixml -Path "$LogsXML\Get-WindowsPackage.xml"
        $GetWindowsPackage | Export-Clixml -Path "$LogsXML\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsPackage.xml"
        $GetWindowsPackage | ConvertTo-Json | Out-File "$LogsJS\Get-WindowsPackage.json"
        $GetWindowsPackage | ConvertTo-Json | Out-File "$LogsJS\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsPackage.json"
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
        #	 Export WinPE Wims 18.9.13
        #======================================================================================
        Write-Host "===========================================================================" -ForegroundColor Yellow
        Write-Host "Exporting WinPE WIMs" -ForegroundColor Yellow
        #======================================================================================
        Write-Host "$WinPE\boot.wim"
        Copy-Item -Path "$OS\sources\boot.wim" -Destination "$WinPE\boot.wim" -Force
        #======================================================================================
        Write-Host "$WinPE\winpe.wim"
        Export-WindowsImage -SourceImagePath "$OS\sources\boot.wim" -SourceIndex 1 -DestinationImagePath "$WinPE\winpe.wim" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Export-WindowsImage-winpe.wim.log"
        #======================================================================================
        Write-Host "$WinPE\setup.wim"
        Export-WindowsImage -SourceImagePath "$OS\sources\boot.wim" -SourceIndex 2 -DestinationImagePath "$WinPE\setup.wim" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Export-WindowsImage-setup.wim.log"
        #======================================================================================
        Write-Host "$WinPE\winre.wim"
        Export-WindowsImage -SourceImagePath "$MountDirectory\Windows\System32\Recovery\winre.wim" -SourceIndex 1 -DestinationImagePath "$WinPE\winre.wim" -LogPath "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Export-WindowsImage-winre.wim.log"
        #======================================================================================
        #   Dismount Install.wim 18.9.13
        #======================================================================================
        Write-Host "===========================================================================" -ForegroundColor Yellow
        Write-Host "Dismounting Install.wim from $MountDirectory" -ForegroundColor Yellow
        if ($OSImagePath -like "*.esd") {Remove-Item $TempESD -Force | Out-Null}
        Dismount-WindowsImage -Discard -Path "$MountDirectory" -LogPath "$Logs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Dismount-WindowsImage.log"
        #======================================================================================
        #   Save WinPE Image Configuration 18.9.13
        #======================================================================================
        Write-Host "===========================================================================" -ForegroundColor Yellow
        Write-Host "Saving WinPE Image Configuration" -ForegroundColor Yellow
        #======================================================================================
        #   Get-WindowsImage Boot.wim
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
        #	Get-WindowsImage WinPE 18.9.13
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
        #	Get-WindowsImage Setup 18.9.13
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
        #	Get-WindowsImage WinRE 18.9.13
        #======================================================================================
        Write-Host "$PEInfo\winre.txt"
        $GetWindowsImage = Get-WindowsImage -ImagePath "$WinPE\winre.wim" -Index 1 | Select-Object -Property *
        $GetWindowsImage | Out-File "$PEInfo\winre.txt"
        (Get-Content "$PEInfo\winre.txt") | Where-Object {$_.Trim(" `t")} | Set-Content "$PEInfo\winre.txt"
        $GetWindowsImage | Out-File "$PELogs\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsImage-winre.wim.txt"
        $GetWindowsImage | Export-Clixml -Path "$PELogsXML\Get-WindowsImage-winre.wim.xml"
        $GetWindowsImage | Export-Clixml -Path "$PELogsXML\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsImage-winre.wim.xml"
        $GetWindowsImage | ConvertTo-Json | Out-File "$PELogsJS\Get-WindowsImage-winre.wim.json"
        $GetWindowsImage | ConvertTo-Json | Out-File "$PELogsJS\$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Get-WindowsImage-winre.wim.json"
        #======================================================================================
        #	 Save Windows Image Configuration 18.9.13
        #======================================================================================
        Write-Host "===========================================================================" -ForegroundColor Yellow
        Write-Host "Saving Windows Image Configuration" -ForegroundColor Yellow
        #======================================================================================
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
        #	Save Get-WindowsImageContent 18.9.13
        #======================================================================================
        Write-Host "$Info\Get-WindowsImageContent.txt"
        Get-WindowsImageContent -ImagePath "$OS\Sources\install.wim" -Index 1 | Out-File "$Info\Get-WindowsImageContent.txt"
        #======================================================================================
        #	Display OS Information 18.9.13
        #======================================================================================
        Show-OSInfo $WorkingPath
        #======================================================================================
        #	Remove Mount Directory 18.9.13
        #======================================================================================
        if (Test-Path "$MountDirectory") {Remove-Item "$MountDirectory" -Force -Recurse | Out-Null}
        #======================================================================================
        #	Stop the Transcript 18.9.13
        #======================================================================================
        Stop-Transcript
        #======================================================================================
        #   Complete 18.9.13
        #======================================================================================
        Write-Host "===========================================================================" -ForegroundColor Green
        Write-Host "Complete!" -ForegroundColor Green
        Write-Host "===========================================================================" -ForegroundColor Green
        #======================================================================================
        #   Update-OSMedia 18.9.13
        #======================================================================================
        if ($UpdateOSMedia.IsPresent) {
            if ($OSMajorVersion -eq '10') {
                Update-OSMedia -ByName "$OSMediaName" -DownloadUpdates -Execute
            } else  {
                Write-Warning "Update-OSMedia is not supported by this Operating System"
            }
        }
    }
}