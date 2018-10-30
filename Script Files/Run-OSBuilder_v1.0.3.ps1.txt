#requires -Version 3.0
#requires -RunAsAdministrator
<#
.DESCRIPTION
	Script used to run OSBuilder module (from David Segura) commands to build Windows 10 installation media that is patched and has only the apps and features desired.
.PARAMETER ADKSetup
	(Optional) This is the path to the Windows 10 ADK Setup Executable. Default = "C:\Downloads\ADK\adksetup.exe"
.PARAMETER WorkFolder
	(Optional) This is the path where OSBuilder will import the OS Media you are working with. Default = "C:\OSBuilder-Work"
.PARAMETER ISOPath
    (Required) This is the path to the Windows 10 ISO from Microsoft.
.PARAMETER DisableItems
    (Optional) A switch to tell the script if you want to disable features, apps, and compatibility items. Only runs if switch is specified at command line.
.PARAMETER EnableItems
    (Optional) A switch to tell the script if you want to enable windows optional features. Only runs if switch is specified at command line.
.PARAMETER EnableNETFX
    (Optional) A switch to tell the script if you want to enable .NET 3.5. Only runs if switch is specified at command line.
.EXAMPLE 1
	.\Run-OSBuilder.ps1 -Customize -BuildVer 1803 -OSArch x64 -ImageBuildName Company-Win10Ent-1803
    Runs OSBuilder for Windows 10 Enterprise, Build 1803, 64bit, runs customizations creation without NetFX3, names the build "Company-Win10Ent-1803"
.EXAMPLE 2
	.\Run-OSBuilder.ps1 -CustomizeFX -BuildVer 1803 -OSArch x64
    Runs OSBuilder for Windows 10 Enterprise, Build 1803, 64bit, runs customizations creation with NetFX3.
.EXAMPLE 3
	.\Run-OSBuilder.ps1 -EnableNETFX -BuildVer 1803 -OSArch x64
    Runs OSBuilder for Windows 10 Enterprise, Build 1803, 64bit, enables NetFX3.
.EXAMPLE 4
	.\Run-OSBuilder.ps1 -Customize -EnableNETFX -BuildVer 1803 -OSArch x64
    Runs OSBuilder for Windows 10 Enterprise, Build 1803, 64bit, runs customizations creation with NetFX3. (Same as EXAMPLE 2)
.NOTES
    AUTHOR - Phil Pritchett (Catapult Systems)
    DATE WRITTEN - 10/23/2018
    CREDITS
        David Segura - 'OSBuilder' PS Module developer. ('@SeguraOSD' on Twitter) (URL: www.osdeploy.com)
        David Stein - Assistance with browse functions and some sanity checks when crap wouldn't work for me. ('@skatterbrainzz' on Twitter) (URL: skatterbrainz.wordpress.com)
    VERSION INFORMATION -
        1.0.0 - PHP - 10/23/2018 - My first attempt to autmate the process. Subsequent versions will add more automation, logging, etc.
        1.0.1 - PHP - 10/24/2018 - Removed switches for Enable and Disable items, consolidated into a single switch called 'Customize'.
                                    Moved updateOSMedia to the build step
        1.0.2 - PHP - 10/26/2018 - Added selection of Windows 10 Enterprise from media. Thanks to David Segura for the added functionality!!
        1.0.3-Beta - PHP - 10/29/2018 - Added Browse for ISO, Browse for work folder, browse for ADKSetup if it isn't installed,
                                        incorporated filters for OSMedia Import from OSBUilder Module.
        1.0.3 - PHP - 10/29/2018 - Changed from 'beta' to full stable version after testing.
    TO DO -
        Add functions for:
            Add Logging
            Add Error Handling
            Inspect OSBuilder functions to add more automation
            Add Log File Gathering
            Get the path of the ISO that was just created
            Mount the new ISO
            Create the Package Source folder
            Copy the contents of the ISO to the Package Source folder
            Check and Import SCCM PS Module
            Connect to SCCM Site
            Create the OS Package in SCCM
            Dismount the ISO
            Copy the ISO to the library
            Rename the ISO to "<sitecode>_Win10<edition>_<arch>_v<BuildVer>.<MM>.<DD>.iso"
            Create SCCM Right-Click Installer for script operation/ run
#>

Param(
    [Parameter(Mandatory=$false)][switch]$Customize,
    [Parameter(Mandatory=$false)][switch]$CustomizeFX,
    [Parameter(Mandatory=$false)][switch]$EnableNETFX,
    [Parameter(Mandatory=$false)][string]$BuildVer = "1803",
    [Parameter(Mandatory=$false)][string]$OSArch = "x64",
    [Parameter(Mandatory=$false)][string]$ImageBuildName = "Win10-$OSArch-$BuildVer"
)

# Get and Mount Windows 10 ISO from Microsoft
Function Get-ISOPath{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.Title = "Find and Select Windows Installation ISO"
    $OpenFileDialog.initialDirectory = "C:\"
    $OpenFileDialog.filter = "Disc Image File (*.iso)| *.iso"
    $OpenFileDialog.ShowDialog() | Out-Null
    $Path = $OpenFileDialog.FileName
    return $Path
}
$ISOPath = Get-ISOPath
Mount-DiskImage -ImagePath $ISOPath -Verbose -ErrorAction Stop

# Verify NuGet Provider version is 2.8.5.201 or greater
$NuGet = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue | Select *
If ((-not($NuGet)) -or ($NuGet.Version -lt "2.8.5.201")){
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    }
Else{
    Write-Host "   NuGet provider is up to date. Current installed version is '$($NuGet.Version)'." -ForegroundColor Green
}

# Check if OSBuilder Module is installed
$ModuleName = "OSBuilder"
$Module = Get-InstalledModule -Name $ModuleName -ErrorAction SilentlyContinue
If (-not($Module)){
    Install-Module -Name OSBuilder -Force
    }
Else{
    Write-Host "   Module '$($ModuleName)' is installed." -ForegroundColor Green
}

# Check if OSBuilder Module is imported
$Imported = Get-Module -Name $ModuleName
If (-not($Imported)){
    Import-Module -Name OSBuilder
    }
Else{
    Write-Host "   Module '$($ModuleName)' is already imported." -ForegroundColor Green
}
Write-Host "Getting available cmdlets for '$($ModuleName)'..." -ForegroundColor Gray
Get-Command -Module OSBuilder

# Function to check if Windows 10 ADK is installed, install if not already
Function Get-InstalledApps{
    if ([IntPtr]::Size -eq 4) {
        $regpath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
    }
    else {
        $regpath = @(
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
            'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
        )
    }
    $Items = Get-ItemProperty $regpath | .{process{if($_.DisplayName -and $_.UninstallString) { $_ } }} `
                | Select DisplayName, Publisher, InstallDate, DisplayVersion, UninstallString |Sort DisplayName
    Foreach ($Item in $Items){
        If ($Item.DisplayName -eq "Windows Assessment and Deployment Kit - Windows 10"){
            $ADKInstalled = $true
        }
    }
    Return $ADKInstalled
}

Function Get-ADKSetup{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = "C:\"
    $OpenFileDialog.filter = "ADK Setup exe (adksetup.exe)| adksetup.exe"
    $OpenFileDialog.ShowDialog() | Out-Null
    $Path = $OpenFileDialog.FileName
    return $Path
}

If (-not(Get-InstalledApps)){
    Write-Host " "
    Write-Host "      Windows 10 Assessment and Deployment Kit is NOT installed!!" -BackgroundColor White -ForegroundColor Red
    Write-Host "          Windows 10 Assessment and Deployment Kit will be installed. Please wait..." -ForegroundColor Yellow
    $ADKSetup = Get-ADKSetup
    $ArgList = @(
        "/features",
        "OptionId.DeploymentTools",
        "OptionId.WindowsPreinstallationEnvironment",
        "OptionId.ImagingAndConfigurationDesigner",
        "OptionId.ICDConfigurationDesigner",
        "OptionId.UserStateMigrationTool",
        "/norestart",
        "/ceip off",
        "/quiet"
    )
    Start-Process -FilePath $ADKSetup -ArgumentList $ArgList -Wait
    
}

If (Get-InstalledApps){
    Write-Host " "
    Write-Host "   Windows 10 Assessment and Deployment Kit is installed..." -ForegroundColor Green
}

# Create and set OSBuilder working directories
Function Set-OSBuilderFolder {
    $Workfolder = $null
    [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $Browse = New-Object System.Windows.Forms.FolderBrowserDialog
    $Browse.SelectedPath = "C:\"
    $Browse.ShowNewFolderButton = $true
    $Browse.Description = "Select OSBuilder Working Folder"
    $Loop = $true
    While($Loop){
        If ($Browse.ShowDialog() -eq "OK"){
            $Loop = $false
		    $Folder = $browse.SelectedPath
		    }
        Else{
            $Loop = $false
        }
    }
    $Browse.Dispose()
    Return $Folder
}

$WorkFolder = Set-OSBuilderFolder
If (-not($WorkFolder)){
    Write-Host "ERROR: No folder specified." -ForegroundColor Red
    Dismount-DiskImage -ImagePath $ISOPath
    Break
}
Get-OSBuilder -SetPath "$($WorkFolder)" -CreatePaths

# Update the OSBuilder Update Catalogs, then
# Download the available MS Updates for Windows 10
Get-OSBuilderUpdates -UpdateCatalogs -FilterOS 'Windows 10' -FilterOSArch $OSArch -FilterOSBuild $BuildVer -Download

# Import the OS Media by name, apply patches and fixes, skip showing the gridview (can take up to 2 hours)
Import-OSMedia -ImageName "Windows 10 Enterprise" -UpdateOSMedia -SkipGridView

# If selected, run Customizations selections
If ($Customize){
    New-OSBuildTask -TaskName "Customizations" -BuildName "$($ImageBuildName)" `
            -RemoveAppxProvisionedPackage `
            -EnableWindowsOptionalFeature `
            -DisableWindowsOptionalFeature `
            -RemoveWindowsPackage `
            -RemoveWindowsCapability `
            -Verbose
}

# If selected, run Customizations selections, and enable .Net 3.5
If ($CustomizeFX){
    New-OSBuildTask -TaskName "CustomizationsFX" -BuildName "$($ImageBuildName)" `
            -RemoveAppxProvisionedPackage `
            -EnableWindowsOptionalFeature `
            -DisableWindowsOptionalFeature `
            -RemoveWindowsPackage `
            -RemoveWindowsCapability `
            -EnableNetFX3 `
            -Verbose
}

#If selected, enable .NET 3.5
If ($EnableNETFX){
    New-OSBuildTask -TaskName "EnableNETFX" -BuildName "$($ImageBuildName)" -EnableNetFX3
}

# Build the Image and install updates
New-OSBuild -DownloadUpdates -Execute

# Create the ISO with your image
New-MediaISO -Verbose

# Show OS Build information
#Show-OSInfo

# Dismount the Windows 10 ISO
Dismount-DiskImage -ImagePath $ISOPath