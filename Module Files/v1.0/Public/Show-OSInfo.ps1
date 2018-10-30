function Show-OSInfo {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$False,Position=1)]
        [string]$FullPath
    )
    #======================================================================================
    #   Initialize OSBuilder 18.9.12
    #======================================================================================
    Get-OSBuilder -CreatePaths -HideDetails
    Write-Host ""
    #======================================================================================
    #   Evaluate OSMediaFullPath 18.9.12
    #======================================================================================
    if ($FullPath) {
        if (!(Test-Path $(Join-Path $FullPath (Join-Path "info" (Join-Path "json" "Get-WindowsImage.json"))))) {
            Write-Warning "Could not find an Operating System at this location to evaluate"
            Write-Warning "$FullPath"
            Break
        } else {
            $OSMediaInfo = Get-Item $FullPath
        }
    } else {
        #======================================================================================
        # Validate OSMedia and OSBuilds has content
        #======================================================================================
        $OSMediaInfo = Get-ChildItem -Path ("$OSBuilderOSMedia","$OSBuilderOSBuilds") -Directory | Select-Object -Property Name, FullName
        if ($null -eq $OSMediaInfo) {
            Write-Warning "OSMedia or OSBuilds content not found.  Use Import-OSMedia to import an Operating System first . . . Exiting!"
            Break
        }
        #======================================================================================
        # Validate that Media has Get-WindowsImage.json
        #======================================================================================
        $OSMediaInfo = $OSMediaInfo | Where-Object {Test-Path $(Join-Path $_.FullName (Join-Path "info" (Join-Path "json" "Get-WindowsImage.json")))}
        if ($null -eq $OSMediaInfo) {
            Write-Warning "Get-WindowsImage.json not found.  Use Import-OSMedia to import an Operating System first . . . Exiting!"
            Break
        }
        #======================================================================================
        # Select Source Media
        #======================================================================================
        $OSMediaInfo = $OSMediaInfo | Out-GridView -Title "Select an OSMedia or an OSBuild to get more information about it (Cancel to Exit)" -OutputMode Single
        if($null -eq $OSMediaInfo) {
            Write-Warning "Source OSMedia or OSBuild was not selected . . . Exiting!"
            Return
        }
    }

    #======================================================================================
    # Enabled Appx Provisioned Packages
    #======================================================================================
    Write-Host "===========================================================================" -ForegroundColor Green
    Write-Host "Enabled Appx Provisioned Packages" -ForegroundColor Green
    Write-Host "===========================================================================" -ForegroundColor Green
    $GetAppxProvisionedPackageJson = Join-Path $($OSMediaInfo.FullName) (Join-Path "info" (Join-Path "json" "Get-AppxProvisionedPackage.json"))
    if ($OSMediaInfo.Name -like "*server*") {Write-Warning "Appx Provisioned Packages are not present in Windows Server"}
    if (Test-Path $GetAppxProvisionedPackageJson) {
        $GetAppxProvisionedPackage = Get-Content -Raw -Path $GetAppxProvisionedPackageJson | ConvertFrom-Json
        foreach ($Item in $GetAppxProvisionedPackage) {Write-Host "$($Item.DisplayName)"}
    }
    Write-Host ""
    #======================================================================================
    # Windows Packages
    #======================================================================================
    Write-Host "===========================================================================" -ForegroundColor Green
    Write-Host "Windows Packages" -ForegroundColor Green
    Write-Host "===========================================================================" -ForegroundColor Green
    $GetWindowsPackageJson = Join-Path $($OSMediaInfo.FullName) (Join-Path "info" (Join-Path "json" "Get-WindowsPackage.json"))
    if (Test-Path $GetWindowsPackageJson) {
        $GetWindowsPackage = Get-Content -Raw -Path $GetWindowsPackageJson | ConvertFrom-Json
        $GetWindowsPackage = $GetWindowsPackage | Where-Object {$_.PackageName -notlike "*Package_for*"}
        $GetWindowsPackage = $GetWindowsPackage | Where-Object {$_.PackageName -notlike "*LanguageFeatures-Basic*"}
        foreach ($Item in $GetWindowsPackage) {Write-Host "$($Item.PackageName)"}
    }
    Write-Host ""
    #======================================================================================
    # Windows Packages (Language Features Basic)
    #======================================================================================
    Write-Host "===========================================================================" -ForegroundColor Green
    Write-Host "Windows Packages (Language Features Basic)" -ForegroundColor Green
    Write-Host "===========================================================================" -ForegroundColor Green
    $GetWindowsPackageJson = Join-Path $($OSMediaInfo.FullName) (Join-Path "info" (Join-Path "json" "Get-WindowsPackage.json"))
    if (Test-Path $GetWindowsPackageJson) {
        $GetWindowsPackage = Get-Content -Raw -Path $GetWindowsPackageJson | ConvertFrom-Json
        $GetWindowsPackage = $GetWindowsPackage | Where-Object {$_.PackageName -like "*LanguageFeatures-Basic*"}
        foreach ($Item in $GetWindowsPackage) {Write-Host "$($Item.PackageName)"}
    }
    Write-Host ""
    #======================================================================================
    # Windows Capabilities
    #======================================================================================
    Write-Host "===========================================================================" -ForegroundColor Green
    Write-Host "Windows Capabilities" -ForegroundColor Green
    Write-Host "===========================================================================" -ForegroundColor Green
    $GetWindowsCapabilityJson = Join-Path $($OSMediaInfo.FullName) (Join-Path "info" (Join-Path "json" "Get-WindowsCapability.json"))
    if (Test-Path $GetWindowsCapabilityJson) {
        $GetWindowsCapability = Get-Content -Raw -Path $GetWindowsCapabilityJson | ConvertFrom-Json
        $GetWindowsCapability = $GetWindowsCapability | Where-Object {$_.Name -notlike "*Language.Basic*"}
        foreach ($Item in $GetWindowsCapability) {Write-Host "$($Item.Name)"}
    }
    Write-Host ""
    #======================================================================================
    # Windows Capabilities (Language.Basic)
    #======================================================================================
    Write-Host "===========================================================================" -ForegroundColor Green
    Write-Host "Windows Capabilities (Language.Basic)" -ForegroundColor Green
    Write-Host "===========================================================================" -ForegroundColor Green
    $GetWindowsCapabilityJson = Join-Path $($OSMediaInfo.FullName) (Join-Path "info" (Join-Path "json" "Get-WindowsCapability.json"))
    if (Test-Path $GetWindowsCapabilityJson) {
        $GetWindowsCapability = Get-Content -Raw -Path $GetWindowsCapabilityJson | ConvertFrom-Json
        $GetWindowsCapability = $GetWindowsCapability | Where-Object {$_.Name -like "*Language.Basic*"}
        foreach ($Item in $GetWindowsCapability) {Write-Host "$($Item.Name)"}
    }
    Write-Host ""
    #======================================================================================
    # Windows Optional Features (Enabled)
    #======================================================================================
    Write-Host "===========================================================================" -ForegroundColor Green
    Write-Host "Windows Optional Features (Enabled)" -ForegroundColor Green
    Write-Host "===========================================================================" -ForegroundColor Green
    $WindowsOptionalFeatureJson = Join-Path $($OSMediaInfo.FullName) (Join-Path "info" (Join-Path "json" "Get-WindowsOptionalFeature.json"))
    if (Test-Path $WindowsOptionalFeatureJson) {
        $WindowsOptionalFeature = Get-Content -Raw -Path $WindowsOptionalFeatureJson | ConvertFrom-Json
        $WindowsOptionalFeature = $WindowsOptionalFeature | Where-Object {$_.State -eq 2}
        foreach ($Item in $WindowsOptionalFeature) {Write-Host "$($Item.FeatureName)"}
    }
    Write-Host ""
    #======================================================================================
    # Windows Optional Features (EnablePending)
    #======================================================================================
    Write-Host "===========================================================================" -ForegroundColor Green
    Write-Host "Windows Optional Features (EnablePending)" -ForegroundColor Green
    Write-Host "===========================================================================" -ForegroundColor Green
    $WindowsOptionalFeatureJson = Join-Path $($OSMediaInfo.FullName) (Join-Path "info" (Join-Path "json" "Get-WindowsOptionalFeature.json"))
    if (Test-Path $WindowsOptionalFeatureJson) {
        $WindowsOptionalFeature = Get-Content -Raw -Path $WindowsOptionalFeatureJson | ConvertFrom-Json
        $WindowsOptionalFeature = $WindowsOptionalFeature | Where-Object {$_.State -eq 3}
        foreach ($Item in $WindowsOptionalFeature) {Write-Host "$($Item.FeatureName)"}
    }
    Write-Host ""
    #======================================================================================
    # Windows Optional Features (Disabled)
    #======================================================================================
    Write-Host "===========================================================================" -ForegroundColor Green
    Write-Host "Windows Optional Features (Disabled)" -ForegroundColor Green
    Write-Host "===========================================================================" -ForegroundColor Green
    $WindowsOptionalFeatureJson = Join-Path $($OSMediaInfo.FullName) (Join-Path "info" (Join-Path "json" "Get-WindowsOptionalFeature.json"))
    if (Test-Path $WindowsOptionalFeatureJson) {
        $WindowsOptionalFeature = Get-Content -Raw -Path $WindowsOptionalFeatureJson | ConvertFrom-Json
        $WindowsOptionalFeature = $WindowsOptionalFeature | Where-Object {$_.State -eq 0}
        foreach ($Item in $WindowsOptionalFeature) {Write-Host "$($Item.FeatureName)"}
    }
    Write-Host ""
    #======================================================================================
    # Windows Optional Features (Disabled with Payload Removed)
    #======================================================================================
    Write-Host "===========================================================================" -ForegroundColor Green
    Write-Host "Windows Optional Features (Disabled with Payload Removed)" -ForegroundColor Green
    Write-Host "===========================================================================" -ForegroundColor Green
    $WindowsOptionalFeatureJson = Join-Path $($OSMediaInfo.FullName) (Join-Path "info" (Join-Path "json" "Get-WindowsOptionalFeature.json"))
    if (Test-Path $WindowsOptionalFeatureJson) {
        $WindowsOptionalFeature = Get-Content -Raw -Path $WindowsOptionalFeatureJson | ConvertFrom-Json
        $WindowsOptionalFeature = $WindowsOptionalFeature | Where-Object {$_.State -eq 6}
        foreach ($Item in $WindowsOptionalFeature) {Write-Host "$($Item.FeatureName)"}
    }
    Write-Host ""
    #======================================================================================
    # Windows Image Information
    #======================================================================================
    Write-Host "===========================================================================" -ForegroundColor Green
    Write-Host "Windows Image Information" -ForegroundColor Green
    Write-Host "===========================================================================" -ForegroundColor Green
    $GetWindowsImageJson = Join-Path $($OSMediaInfo.FullName) (Join-Path "info" (Join-Path "json" "Get-WindowsImage.json"))
    if (Test-Path $GetWindowsPackageJson) {
        $GetWindowsImage = Get-Content -Raw -Path $GetWindowsImageJson | ConvertFrom-Json
        if ($GetWindowsImage.Architecture -eq 0) {$GetWindowsImage.Architecture = 'x86'}
        elseif ($GetWindowsImage.Architecture -eq 1) {$GetWindowsImage.Architecture = 'MIPS'}
        elseif ($GetWindowsImage.Architecture -eq 2) {$GetWindowsImage.Architecture = 'Alpha'}
        elseif ($GetWindowsImage.Architecture -eq 3) {$GetWindowsImage.Architecture = 'PowerPC'}
        elseif ($GetWindowsImage.Architecture -eq 6) {$GetWindowsImage.Architecture = 'ia64'}
        elseif ($GetWindowsImage.Architecture -eq 9) {$GetWindowsImage.Architecture = 'x64'}
        $GetWindowsImage
    }
    Write-Host ""
    #======================================================================================
    # Windows Update Packages
    #======================================================================================
    Write-Host "===========================================================================" -ForegroundColor Green
    Write-Host "Windows Update Packages" -ForegroundColor Green
    Write-Host "===========================================================================" -ForegroundColor Green
    $GetWindowsPackageJson = Join-Path $($OSMediaInfo.FullName) (Join-Path "info" (Join-Path "json" "Get-WindowsPackage.json"))
    if (Test-Path $GetWindowsPackageJson) {
        $GetWindowsPackage = Get-Content -Raw -Path $GetWindowsPackageJson | ConvertFrom-Json
        $GetWindowsPackage = $GetWindowsPackage | Where-Object {$_.PackageName -like "*Package_for*"}
        foreach ($Item in $GetWindowsPackage) {Write-Host "$($Item.PackageName)"}
    }
    Write-Host ""
}