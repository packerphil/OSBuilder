function New-PEBuildTask {
    [CmdletBinding(DefaultParameterSetName='Recovery')]
    Param (
        [Parameter(Mandatory,ParameterSetName='WinPE')]
        [Parameter(Mandatory,ParameterSetName='MDT')]
        [ValidateSet('WinRE','WinPE')]
        [string]$SourceWim,
        [Parameter(Mandatory)]
        [string]$TaskName,
        [Parameter(Mandatory,ParameterSetName='MDT')]
        [string]$DeploymentShare,
        [switch]$AutoExtraFiles,
        [ValidateSet('64','128','256','512')]
        [string]$ScratchSpace = '128'
    )
    #======================================================================================
    #   Start 18.10.13
    #======================================================================================
    Write-Host "===========================================================================" -ForegroundColor Green
    Write-Host "Start New-PEBuildTask" -ForegroundColor Green
    #======================================================================================
    #   Validate Administrator Rights 18.10.13
    #======================================================================================
    if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "===========================================================================" -ForegroundColor Green
        Write-Warning "OSBuilder: This function needs to be run as Administrator"
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
    #   Information 18.10.12
    #======================================================================================
    $PEOutput = $($PsCmdlet.ParameterSetName)
    if ($PEOutput -eq 'Recovery') {$SourceWim = 'WinRE'}

    $TaskName = "$PEOutput $TaskName"
    $TaskPath = "$OSBuilderTasks\$TaskName.json"
    Write-Host "New OSBuild Task Settings" -ForegroundColor Yellow
    Write-Host "-Task Name:             $TaskName" -ForegroundColor Cyan
    Write-Host "-Task Path:             $TaskPath" -ForegroundColor Cyan
    Write-Host "-PEOutput:              $PEOutput" -ForegroundColor Cyan
    Write-Host "-Wim File:              $SourceWim" -ForegroundColor Cyan
    Write-Host "-Deployment Share:      $DeploymentShare" -ForegroundColor Cyan
    Write-Host "-Scratch Space:         $ScratchSpace" -ForegroundColor Cyan
    Write-Host ""
    #======================================================================================
    #   Validate Task 18.10.10
    #======================================================================================
    if (Test-Path $TaskPath) {
        Write-Warning "Task already exists at $TaskPath"
        Write-Warning "Content will be overwritten!"
        Write-Host ""
    }
    #======================================================================================
    #   Validate OSMedia has Content 18.10.10
    #======================================================================================
    #$SelectedOS = Get-ChildItem -Path ("$OSBuilderOSBuilds","$OSBuilderOSMedia") -Directory | Where-Object {$_.Name -like "*.*"} | Select-Object -Property Name, FullName
    $SelectedOS = Get-ChildItem -Path "$OSBuilderOSMedia" -Directory | Where-Object {$_.Name -like "*.*"} | Select-Object -Property Name, FullName
    if ($null -eq $SelectedOS) {
        Write-Warning "WinPE content not found.  Use Import-OSMedia to import an Operating System first . . . Exiting!"
        Break
    }
    #======================================================================================
    #   Validate OSMedia has an install.wim 18.10.10
    #======================================================================================
    $SelectedOS = $SelectedOS | Where-Object {Test-Path $(Join-Path $_.FullName (Join-Path "WinPE" "$SourceWim.wim"))}
    if ($null -eq $SelectedOS) {
        Write-Warning "$SourceWim.wim not found.  Use Import-OSMedia to import an Operating System first . . . Exiting!"
        Break
    }
    #======================================================================================
    #   SelectedOS Logic 18.10.13
    #======================================================================================
    if ($TaskName -like "*x64*") {$SelectedOS = $SelectedOS | Where-Object {$_.Name -like "*x64*"}}
    if ($TaskName -like "*x86*") {$SelectedOS = $SelectedOS | Where-Object {$_.Name -like "*x86*"}}
    if ($TaskName -like "*1511*") {$SelectedOS = $SelectedOS | Where-Object {$_.Name -like "*1511*"}}
    if ($TaskName -like "*1607*") {$SelectedOS = $SelectedOS | Where-Object {$_.Name -like "*1607*"}}
    if ($TaskName -like "*1703*") {$SelectedOS = $SelectedOS | Where-Object {$_.Name -like "*1703*"}}
    if ($TaskName -like "*1709*") {$SelectedOS = $SelectedOS | Where-Object {$_.Name -like "*1709*"}}
    if ($TaskName -like "*1803*") {$SelectedOS = $SelectedOS | Where-Object {$_.Name -like "*1803*"}}
    if ($TaskName -like "*1809*") {$SelectedOS = $SelectedOS | Where-Object {$_.Name -like "*1809*"}}
    #======================================================================================
    #   Select Source OSMedia 18.10.10
    #======================================================================================
    $SelectedOS = $SelectedOS | Out-GridView -Title "Select a Source OSMedia to use for this PEBuild Task (Cancel to Exit)" -OutputMode Single
    if($null -eq $SelectedOS) {
        Write-Warning "Source OSMedia was not selected . . . Exiting!"
        Return
    }
    #======================================================================================
    # Get Windows Image Information 18.9.24
    #======================================================================================
    $OSSourcePath = "$($SelectedOS.FullName)"
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
    #   WinPE DaRT 18.9.28
    #======================================================================================
    $SelectedWinPEDaRT =@()
    $SelectedWinPEDaRT = Get-ChildItem -Path "$OSBuilderContent\WinPE\DaRT" *.cab -Recurse | Select-Object -Property Name, FullName
    foreach ($Pack in $SelectedWinPEDaRT) {$Pack.FullName = $($Pack.FullName).replace("$OSBuilderContent\",'')}
    $SelectedWinPEDaRT = $SelectedWinPEDaRT | Where-Object {$_.FullName -like "*$OSArchitecture*"}
    $SelectedWinPEDaRT = $SelectedWinPEDaRT | Out-GridView -Title "Select a WinPE DaRT Package to apply and press OK (Esc or Cancel to Skip)" -OutputMode Single
    if($null -eq $SelectedWinPEDaRT) {Write-Warning "Skipping WinPE DaRT"}
    #======================================================================================
    #   WinPE Drivers 18.9.28
    #======================================================================================
    $SelectedWinPEDrivers =@()
    $SelectedWinPEDrivers = Get-ChildItem -Path "$OSBuilderContent\WinPE\Drivers" -Directory | Select-Object -Property Name, FullName
    $SelectedWinPEDrivers = $SelectedWinPEDrivers | Where-Object {(Get-ChildItem $_.FullName | Measure-Object).Count -gt 0}
    foreach ($Pack in $SelectedWinPEDrivers) {$Pack.FullName = $($Pack.FullName).replace("$OSBuilderContent\",'')}
    $SelectedWinPEDrivers = $SelectedWinPEDrivers | Out-GridView -Title "Select WinPE Drivers to apply and press OK (Esc or Cancel to Skip)" -PassThru
    if($null -eq $SelectedWinPEDrivers) {Write-Warning "Skipping WinPE Drivers"}
    #======================================================================================
    #   WinPE Scripts 18.10.10
    #======================================================================================
    $SelectedWinPEScripts =@()
    $SelectedWinPEScripts = Get-ChildItem -Path "$OSBuilderContent\WinPE\Scripts" *.ps1 | Select-Object -Property Name, FullName
    foreach ($Pack in $SelectedWinPEScripts) {$Pack.FullName = $($Pack.FullName).replace("$OSBuilderContent\",'')}
    $SelectedWinPEScripts = $SelectedWinPEScripts | Out-GridView -Title "Select WinPE PowerShell Scripts to execute and press OK (Esc or Cancel to Skip)" -PassThru
    if($null -eq $SelectedWinPEScripts) {Write-Warning "Skipping WinPE PowerShell Scripts"}
    #======================================================================================
    #   WinPE Extra Files 18.10.10
    #======================================================================================
    $SelectedWinPEExtraFiles =@()
    $SelectedWinPEExtraFiles = Get-ChildItem -Path "$OSBuilderContent\WinPE\ExtraFiles" -Directory | Select-Object -Property Name, FullName
    $SelectedWinPEExtraFiles = $SelectedWinPEExtraFiles | Where-Object {(Get-ChildItem $_.FullName | Measure-Object).Count -gt 0}
    foreach ($Pack in $SelectedWinPEExtraFiles) {$Pack.FullName = $($Pack.FullName).replace("$OSBuilderContent\",'')}
    $SelectedWinPEExtraFiles = $SelectedWinPEExtraFiles | Out-GridView -Title "Select WinPE Extra Files to apply and press OK (Esc or Cancel to Skip)" -PassThru
    if($null -eq $SelectedWinPEExtraFiles) {Write-Warning "Skipping WinPE Extra Files"}
    #======================================================================================
    #   WinPE Wallpaper 18.10.14
    #======================================================================================
<#     $SelectedWinPEWallpaper =@()
    $SelectedWinPEWallpaper = Get-ChildItem -Path "$OSBuilderContent\WinPE\Wallpaper" *.jpg | Select-Object -Property Name, FullName
    foreach ($JPG in $SelectedWinPEWallpaper) {$JPG.FullName = $($JPG.FullName).replace("$OSBuilderContent\",'')}
    $SelectedWinPEWallpaper = $SelectedWinPEWallpaper | Out-GridView -Title "Select WinPE Wallpaper to apply and press OK (Esc or Cancel to Skip)" -OutputMode Single
    if($null -eq $SelectedWinPEWallpaper) {Write-Warning "Skipping WinPE Wallpaper"} #>
    #======================================================================================
    #   Setup WIM ADK Packages 18.9.28
    #======================================================================================
    $SelectedWinPEADKPkgs =@()
    $SelectedWinPEADKPkgs = Get-ChildItem -Path "$OSBuilderContent\WinPE\ADK" *.cab -Recurse | Select-Object -Property Name, FullName
    foreach ($Pack in $SelectedWinPEADKPkgs) {$Pack.FullName = $($Pack.FullName).replace("$OSBuilderContent\",'')}
    $SelectedWinPEADKPkgs = $SelectedWinPEADKPkgs | Where-Object {$_.FullName -like "*$OSArchitecture*"}
    $SelectedWinPEADKPkgs = $SelectedWinPEADKPkgs | Where-Object {$_.FullName -like "*$OSVersionNumber*"}
<#     $SelectedWinPEADKPkgs = $SelectedWinPEADKPkgs | Where-Object {$_.Name -notlike "WinPE-EnhancedStorage*"}
    $SelectedWinPEADKPkgs = $SelectedWinPEADKPkgs | Where-Object {$_.Name -notlike "WinPE-Font*"}
    $SelectedWinPEADKPkgs = $SelectedWinPEADKPkgs | Where-Object {$_.Name -notlike "WinPE-LegacySetup*"}
    $SelectedWinPEADKPkgs = $SelectedWinPEADKPkgs | Where-Object {$_.Name -notlike "WinPE-SRT*"}
    $SelectedWinPEADKPkgs = $SelectedWinPEADKPkgs | Where-Object {$_.Name -notlike "WinPE-Scripting*"}
    $SelectedWinPEADKPkgs = $SelectedWinPEADKPkgs | Where-Object {$_.Name -notlike "WinPE-SecureStartup*"}
    $SelectedWinPEADKPkgs = $SelectedWinPEADKPkgs | Where-Object {$_.Name -notlike "WinPE-Setup*"}
    $SelectedWinPEADKPkgs = $SelectedWinPEADKPkgs | Where-Object {$_.Name -notlike "WinPE-WDS*"}
    $SelectedWinPEADKPkgs = $SelectedWinPEADKPkgs | Where-Object {$_.Name -notlike "WinPE-WMI*"} #>
    $SelectedWinPEADKPkgs = $SelectedWinPEADKPkgs | Out-GridView -Title "Select WinPE ADK Packages to apply and press OK (Esc or Cancel to Skip)" -PassThru
    if($null -eq $SelectedWinPEADKPkgs) {Write-Warning "Skipping WinPE ADK Packages"}
    #======================================================================================
    # Build Task 18.9.28
    #======================================================================================
    $Task = [ordered]@{
    "TaskName" = [string]$TaskName;
    "TaskVersion" = [string]$($(Get-Module -Name OSBuilder).Version);
    "TaskType" = "PEBuild";
    "AutoExtraFiles" = [string]"$AutoExtraFiles";
    "DeploymentShare" = [string]"$DeploymentShare";
    "MediaName" = [string]$SelectedOS.Name;
    "PEOutput" = [string]"$PEOutput";
	"ScratchSpace" = [string]"$ScratchSpace";
    "SourceWim" = [string]"$SourceWim";
    "WinPEAddADK" = [string[]]$SelectedWinPEADKPkgs.FullName;
    "WinPEAddDaRT" = [string]$SelectedWinPEDaRT.FullName;
    "WinPEAddWindowsDriver" = [string[]]$SelectedWinPEDrivers.FullName;
    "WinPEInvokeScript" = [string[]]$SelectedWinPEScripts.FullName;
    "WinPERobocopyExtraFiles" = [string[]]$SelectedWinPEExtraFiles.FullName;
    #"WinPEWallpaper" = [string]"$SelectedWinPEWallpaper";
    }
    #======================================================================================
    Write-Host "===========================================================================" -ForegroundColor Green
    Write-Host "PEBuild Task: $TaskName" -ForegroundColor Green
    Write-Host "===========================================================================" -ForegroundColor Green
    #======================================================================================
    $Task | ConvertTo-Json | Out-File "$OSBuilderTasks\$TaskName.json"
    $Task
    #======================================================================================
    Write-Host "===========================================================================" -ForegroundColor Green
    Write-Host "Complete!" -ForegroundColor Green
    Write-Host "===========================================================================" -ForegroundColor Green
    #======================================================================================
}