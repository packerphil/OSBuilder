#requires -Version 3.0
#requires -RunAsAdministrator
<#
	.DESCRIPTION
		Wrapper script used to run OSBuilder module v10.10.26.0 (from David Segura) commands to build Windows 10 installation media that is patched and has only the apps and features desired.
		Only works with Windows 10 Enterprise at this time.
	
	.PARAMETER BuildVer
		(REQUIRED) - Microsoft Windows 10 Build Number
		Valid values are:
		'1511'
		'1607'
		'1703'
		'1709'
		'1803'
		'1809'
	
	.PARAMETER SiteCode
		(OPTIONAL) - Specifies the Configuration Manager Site Code
	
	.PARAMETER OSArch
		(REQUIRED) - Specifies the processor architecture of the OS Media you are building.
		Valid values are
		'x64'
		'x86'
	
	.PARAMETER ImageBuildName
		(OPTIONAL) - Specifies the Build Name of the OS Media you are building. Default is 'Win10-x64-1803'
	
	.PARAMETER SaveNewISO
		(OPTIONAL) - Specifies to save the new ISO to a specific folder.
	
	.PARAMETER CustomOptions
		(OPTIONAL) - If specified, a new build task will be created with the options chosen.
		Values are comma separated (EXAMPLE - 'RemAppx,AddNetFX3')
		Minimum options = 1
		Maximum options = 6
		Valid values are:
		'RemAppx' = RemoveAppxProvisionedPackage
		'AddWinOpt' = EnableWindowsOptionalFeature
		'RemWinOpt' = DisableWindowsOptionalFeature
		'RemWinPkg' = RemoveWindowsPackage
		'RemWinCap' = RemoveWindowsCapability
		'AddNetFX3' = EnableNetFX3
	
	.EXAMPLE 1
		Runs OSBuilder for Windows 10 Enterprise, Build 1803, 64bit, adds customization job for enabling .NET35 and removal of Appx Packages, specified SCCM Site Code 'LAB'
		.\Run-OSBuilder.ps1 -CustomOptions AddNetFX3,RemAppx -BuildVer 1803 -OSArch x64 -SiteCode LAB
	
	.EXAMPLE 2
		Runs OSBuilder for Windows 10 Enterprise, Build 1709, 64bit, names the build 'LAB-WIn10Ent-x64-1709'
		.\Run-OSBuilder.ps1 -BuildVer 1709 -OSArch x64 -ImageBuildName "LAB-WIn10Ent-x64-1709"
	
	.NOTES
		AUTHOR - Phil Pritchett
		DATE WRITTEN - 10/23/2018
		TWITTER: @PhilPritchett
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
		1.0.4 - PHP - 10/30/2018 - Added setting for SCCM Site Code to name the new ISO file, added Save dialog for saving the ISO to network or local folder.
		1.0.5 - PHP - 10/31/2018 - Brought all functions to top of script, formatted script, updated parameter descriptions/ defaults, added script breaks if folder or file browse dialogs are cancelled
		1.0.6 - PHP - 11/05/2018 - Consolidated customization variables into a single array parameter/variable('CustomOptions) with validation and a function call. Made 'BuildVer' and 'OSArch' required parameters added value validation, and removed default values. Made installation of 'NuGet' provider silent.
		TO DO -
		Add functions for:
		Add Logging
		Add Error Handling
		Inspect OSBuilder functions to add more automation
		Add Log File Gathering
		Mount the new ISO
		Create the Package Source folder
		Copy the contents of the ISO to the Package Source folder
		Check and Import SCCM PS Module
		Connect to SCCM Site
		Create the OS Package in SCCM
		Dismount the ISO
		Copy the ISO to the library
		Create SCCM Right-Click Installer for script operation/ run
#>
[CmdletBinding(supportsshouldprocess=$true)]
param
(
	[Parameter(ParameterSetName = 'AddOptions',
	           Mandatory = $false,
	           ValueFromPipeline = $true,
	           ValueFromPipelineByPropertyName = $true)]
	[ValidateCount(1, 6)]
	[ValidateSet('AddWinOpt', 'AddNetFX3', 'RemAppx', 'RemWinOpt', 'RemWinPkg', 'RemWinCap')]
	[array]
	$CustomOptions,
	[Parameter(Mandatory = $true)]
	[ValidateSet('1507', '1511', '1607', '1703', '1709', '1803', '1809')]
	[string]
	$BuildVer,
	[Parameter(Mandatory = $true)]
	[ValidateSet('x86', 'x64')]
	[string]
	$OSArch,
	[Parameter(Mandatory = $false)]
	[string]
	$SiteCode,
	[Parameter(Mandatory = $false)]
	[string]
	$ImageBuildName = "Win10-x64-1803",
	[Parameter(Mandatory = $false)]
	[switch]
	$SaveNewISO
)

# **************************************************************
# BEGIN - Load functions into memory for use within the script
# **************************************************************
# Function to browse for ISO file to mount, import, and extract.
Function Get-ISOPath
{
	[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
	$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
	$OpenFileDialog.Title = "Find and Select Windows Installation ISO"
	$OpenFileDialog.initialDirectory = "C:\"
	$OpenFileDialog.filter = "Disc Image File (*.iso)| *.iso"
	$OpenFileDialog.ShowDialog() | Out-Null
	$Path = $OpenFileDialog.FileName
	return $Path
}

# Function to check if Windows 10 ADK is installed, install if not already
Function Get-ADKInstalled
{
	if ([IntPtr]::Size -eq 4)
	{
		$regpath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
	}
	else
	{
		$regpath = @(
			'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
			'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
		)
	}
	$Items = Get-ItemProperty $regpath | .{process { if ($_.DisplayName -and $_.UninstallString) { $_ } } } `
	| Select DisplayName, Publisher, InstallDate, DisplayVersion, UninstallString | Sort DisplayName
	Foreach ($Item in $Items)
	{
		If ($Item.DisplayName -eq "Windows Assessment and Deployment Kit - Windows 10")
		{
			$ADKInstalled = $true
		}
	}
	Return $ADKInstalled
}

# Function to browse for 'ADKsetup.exe' if the Windows ADK is not installed
Function Get-ADKSetup
{
	[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
	$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
	$OpenFileDialog.Title = "Select 'adksteup.exe'"
	$OpenFileDialog.initialDirectory = "C:\"
	$OpenFileDialog.filter = "ADK Setup exe (adksetup.exe)| adksetup.exe"
	$OpenFileDialog.ShowDialog() | Out-Null
	$ADKSetupPath = $OpenFileDialog.FileName
	return $ADKSetupPath
}

# Function to browse for 'OSBuilder' working directory
Function Set-OSBuilderFolder
{
	$Workfolder = $null
	[Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$Browse = New-Object System.Windows.Forms.FolderBrowserDialog
	$Browse.SelectedPath = "C:\"
	$Browse.ShowNewFolderButton = $true
	$Browse.Description = "Select OSBuilder Working Folder"
	$Loop = $true
	While ($Loop)
	{
		If ($Browse.ShowDialog() -eq "OK")
		{
			$Loop = $false
			$Folder = $browse.SelectedPath
		}
		Else
		{
			$Loop = $false
		}
	}
	$Browse.Dispose()
	Return $Folder
}

# Function to browse for location to save the new OS Media ISO after it is built (can be local or UNC path)
Function Set-BuildISOPath
{
	[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
	$SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
	$SaveFileDialog.Title = "Select Path to Save New Build ISO"
	$SaveFileDialog.initialDirectory = "C:\"
	$SaveFileDialog.FileName = "$($NewName)"
	$SaveFileDialog.filter = "Disc Image File (*.iso)| *.iso"
	$SaveFileDialog.ShowDialog() | Out-Null
	$SavePath = $SaveFileDialog.FileName
	$SaveFileDialog.Dispose()
	return $SavePath
}

# Function to parse array of customization options specified by the 'CustomOptions' parameter
Function Get-CustomOptions ($CustomOptions)
{
	$Customs = $CustomOptions -split ","
	$arraylist = New-Object System.Collections.Arraylist
	foreach ($Custom in $CustomOptions)
	{
		switch ($Custom)
		{
			'RemAppx'	{ $CParam = "-RemoveAppxProvisionedPackage" ; break}
			'AddWinOpt'	{ $CParam = "-EnableWindowsOptionalFeature" ; break}
			'RemWinOpt'	{ $CParam = "-DisableWindowsOptionalFeature" ; break}
			'RemWinPkg'	{ $CParam = "-RemoveWindowsPackage" ; break}
			'RemWinCap'	{ $CParam = "-RemoveWindowsCapability" ; break}
			'AddNetFX3'	{ $CParam = "-EnableNetFX3" ; break}
		}
		$results = $arraylist.Add($CParam)
	}
	$CustomActions = $arraylist -join " "
	return $CustomActions
}

# Function used to verify the 'NuGet' Package Provider version '2.8.5.201' or greater is installed
Function Get-NuGetProvider{

    $PkgProviders = (Get-PackageProvider -ListAvailable).Name
    If ($PkgProviders -contains "NuGet"){
        $NuGet = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue | Select *
        If (-not($NuGet.Version -ge "2.8.5.201")){
            Write-Host "ERROR: 'NuGet' provider version '2.8.5.201' or higher is NOT INSTALLED." -ForegroundColor Red -BackgroundColor White
            Write-Host "   Please wait while 'NuGet' provider is updated..." -ForegroundColor Yellow
            $InstNuGet = Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Confirm:$false -Force
            Get-NuGetProvider
        }
        Else{
            Write-Host "      NuGet provider is up to date. Current installed version is '$($NuGet.Version)'." -ForegroundColor Green
        }
    }

    If (-not($PkgProviders -contains "NuGet")){
        Write-Host "ERROR: 'NuGet' provider is NOT INSTALLED." -ForegroundColor Red -BackgroundColor White
        Write-Host "   Please wait while 'NuGet' provider is installed..." -ForegroundColor Yellow
        $InstNuGet = Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Confirm:$false -Force
        Get-NuGetProvider
    }

}
# **************************************************************
# END - Load functions into memory for use within the script
# **************************************************************

# Get and Mount Windows 10 ISO from Microsoft
$ISOPath = Get-ISOPath
If (-not ($ISOPath))
{
	Write-Host "   ERROR - Windows installation ISO was NOT selected!!" -ForegroundColor Red
	Break
}
Else
{
	Mount-DiskImage -ImagePath $ISOPath -Verbose -ErrorAction Stop
}

# Call function to verify NuGet Provider version is 2.8.5.201 or greater is installed
Get-NuGetProvider

# Check if OSBuilder Module is installed
$ModuleName = "OSBuilder"
$Module = Get-InstalledModule -Name $ModuleName -ErrorAction SilentlyContinue
If (-not ($Module))
{
	Install-Module -Name OSBuilder -Force
}
Else
{
	Write-Host "   Module '$($ModuleName)' is installed." -ForegroundColor Green
}

# Check if OSBuilder Module is imported
$Imported = Get-Module -Name $ModuleName
If (-not ($Imported))
{
	Import-Module -Name OSBuilder
}
Else
{
	Write-Host "   Module '$($ModuleName)' is already imported." -ForegroundColor Green
}
Write-Host "Getting available cmdlets for '$($ModuleName)'..." -ForegroundColor Gray
Get-Command -Module OSBuilder

# Check if the Windows ADK is installed. Install it if it is not.
$ADKPresent = Get-ADKInstalled
If (-not ($ADKPresent))
{
	Write-Host " "
	Write-Host "      Windows 10 Assessment and Deployment Kit is NOT installed!!" -BackgroundColor White -ForegroundColor Red
	Write-Host "          Windows 10 Assessment and Deployment Kit will be installed. Please wait..." -ForegroundColor Yellow
	$ADKSetup = Get-ADKSetup
	If (-not ($ADKSetup))
	{
		Write-Host "   'adksetup.exe' NOT selected!" -ForegroundColor Red
		Break
	}
	Else
	{
		#$ADKSetup = Get-ADKSetup
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
	
}

# Check if Windows ADK is installed, report if it is.
If ($ADKPresent)
{
	Write-Host " "
	Write-Host "   Windows 10 Assessment and Deployment Kit is installed..." -ForegroundColor Green
}

# Create and set OSBuilder working directories
$WorkFolder = Set-OSBuilderFolder
If (-not ($WorkFolder))
{
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

# If 'CustomOptions' are specified at the command-line, create the Build Task
If ($CustomOptions)
{
	$CustomActions = Get-CustomOptions $CustomOptions
	Write-Verbose $CustomActions
	If ($SiteCode)
	{
		# Run the 'New-OSBuildTask' powershell command with ConfigMgr SiteCode in 'TaskName'
		$Command = "New-OSBuildTask -TaskName `"$($SiteCode)-Customizations`" -BuildName $ImageBuildName $CustomActions"
	}
	Else
	{
		# Run the 'New-OSBuildTask' powershell command
		$Command = "New-OSBuildTask -TaskName `"Customizations`" -BuildName $ImageBuildName $CustomActions"
	}
	Invoke-Expression $Command
}

# Build the Image and install updates
New-OSBuild -DownloadUpdates -Execute

# Create the ISO with your image
New-MediaISO -Verbose

# Show OS Build information
#Show-OSInfo

# Dismount the Windows 10 ISO
Dismount-DiskImage -ImagePath $ISOPath

# Code to save the new ISO and validate it's successful copy to that location
If ($SaveNewISO)
{
	$BuildDate = Get-Date -Format "MM.dd.HHmm"
	$NewISO = Get-ChildItem -Path $WorkFolder -Recurse | ? { $_.Name -like "*.iso" }
	If ($SiteCode)
	{
		$NewName = "$SiteCode - Win10 Ent $OSArch $BuildVer OSBuilder - v$BuildDate.iso"
	}
	Else
	{
		$NewName = "Win10 Ent $OSArch $BuildVer OSBuilder - v$BuildDate.iso"
	}
	$Destination = Set-BuildISOPath
	If (-not ($Destination))
	{
		Write-Host "ERROR: No save location or filename specified." -ForegroundColor Red
		Break
	}
	$CopyISO = Copy-Item -Path $NewISO.FullName -Destination $Destination -Force # -Verbose
	If (Get-Item -Path "$($Destination)")
	{
		Write-Host "New Installation ISO has ben copied to: '$($Destination)'" -ForegroundColor Green
	}
}
