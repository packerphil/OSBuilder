function New-OSBuildTask {
    [CmdletBinding(DefaultParameterSetName='Basic')]
    Param (
        [Parameter(Mandatory)]
        [string]$TaskName,
        [string]$BuildName,
        [switch]$EnableNetFX3,
        [switch]$RemoveAppxProvisionedPackage,
        [switch]$RemoveWindowsPackage,
        [switch]$RemoveWindowsCapability,
        [switch]$DisableWindowsOptionalFeature,
        [switch]$EnableWindowsOptionalFeature,
        #[ValidateSet('ar-SA','bg-BG','zh-CN','zh-TW','hr-HR','cs-CZ','da-DK','nl-NL','en-US','en-GB','et-EE','fi-FI','fr-CA','fr-FR','de-DE','el-GR','he-IL','hu-HU','it-IT','ja-JP','ko-KR','lv-LV','lt-LT','nb-NO','pl-PL','pt-BR','pt-PT','ro-RO','ru-RU','sr-Latn-RS','sk-SK','sl-SI','es-MX','es-ES','sv-SE','th-TH','tr-TR','uk-UA')]
        #[ValidateSet('af-ZA','am-ET','as-IN','az-Latn-AZ','be-BY','bn-BD','bn-IN','bs-Latn-BA','ca-ES','ca-ES-valencia','chr-CHER-US','cy-GB','eu-ES','fa-IR','fil-PH','ga-IE','gd-GB','gl-ES','gu-IN','ha-Latn-NG','hi-IN','hy-AM','id-ID','ig-NG','is-IS','ka-GE','kk-KZ','km-KH','kn-IN','kok-IN','ku-ARAB-IQ','ky-KG','lb-LU','lo-LA','mi-NZ','mk-MK','ml-IN','mn-MN','mr-IN','ms-MY','mt-MT','ne-NP','nn-NO','nso-ZA','or-IN','pa-Arab-PK','pa-IN','prs-AF','quc-Latn-GT','quz-PE','rw-RW','sd-Arab-PK','si-LK','sq-AL','sr-Cyrl-BA','sr-Cyrl-RS','sw-KE','ta-IN','te-IN','tg-Cyrl-TJ','ti-ET','tk-TM','tn-ZA','tt-RU','ug-CN','ur-PK','uz-Latn-UZ','vi-VN','wo-SN','xh-ZA','yo-NG','zu-ZA')]
        [Parameter(ParameterSetName='Language')]
        [ValidateSet('ar-SA','bg-BG','zh-CN','zh-TW','hr-HR','cs-CZ','da-DK','nl-NL','en-US','en-GB','et-EE','fi-FI','fr-CA','fr-FR','de-DE','el-GR','he-IL','hu-HU','it-IT','ja-JP','ko-KR','lv-LV','lt-LT','nb-NO','pl-PL','pt-BR','pt-PT','ro-RO','ru-RU','sr-Latn-RS','sk-SK','sl-SI','es-MX','es-ES','sv-SE','th-TH','tr-TR','uk-UA','af-ZA','am-ET','as-IN','az-Latn-AZ','be-BY','bn-BD','bn-IN','bs-Latn-BA','ca-ES','ca-ES-valencia','chr-CHER-US','cy-GB','eu-ES','fa-IR','fil-PH','ga-IE','gd-GB','gl-ES','gu-IN','ha-Latn-NG','hi-IN','hy-AM','id-ID','ig-NG','is-IS','ka-GE','kk-KZ','km-KH','kn-IN','kok-IN','ku-ARAB-IQ','ky-KG','lb-LU','lo-LA','mi-NZ','mk-MK','ml-IN','mn-MN','mr-IN','ms-MY','mt-MT','ne-NP','nn-NO','nso-ZA','or-IN','pa-Arab-PK','pa-IN','prs-AF','quc-Latn-GT','quz-PE','rw-RW','sd-Arab-PK','si-LK','sq-AL','sr-Cyrl-BA','sr-Cyrl-RS','sw-KE','ta-IN','te-IN','tg-Cyrl-TJ','ti-ET','tk-TM','tn-ZA','tt-RU','ug-CN','ur-PK','uz-Latn-UZ','vi-VN','wo-SN','xh-ZA','yo-NG','zu-ZA')]
        [string]$SetAllIntl,
        [Parameter(ParameterSetName='Language')]
        [string]$SetInputLocale,
        [Parameter(ParameterSetName='Language')]
        [ValidateSet('ar-SA','bg-BG','zh-CN','zh-TW','hr-HR','cs-CZ','da-DK','nl-NL','en-US','en-GB','et-EE','fi-FI','fr-CA','fr-FR','de-DE','el-GR','he-IL','hu-HU','it-IT','ja-JP','ko-KR','lv-LV','lt-LT','nb-NO','pl-PL','pt-BR','pt-PT','ro-RO','ru-RU','sr-Latn-RS','sk-SK','sl-SI','es-MX','es-ES','sv-SE','th-TH','tr-TR','uk-UA','af-ZA','am-ET','as-IN','az-Latn-AZ','be-BY','bn-BD','bn-IN','bs-Latn-BA','ca-ES','ca-ES-valencia','chr-CHER-US','cy-GB','eu-ES','fa-IR','fil-PH','ga-IE','gd-GB','gl-ES','gu-IN','ha-Latn-NG','hi-IN','hy-AM','id-ID','ig-NG','is-IS','ka-GE','kk-KZ','km-KH','kn-IN','kok-IN','ku-ARAB-IQ','ky-KG','lb-LU','lo-LA','mi-NZ','mk-MK','ml-IN','mn-MN','mr-IN','ms-MY','mt-MT','ne-NP','nn-NO','nso-ZA','or-IN','pa-Arab-PK','pa-IN','prs-AF','quc-Latn-GT','quz-PE','rw-RW','sd-Arab-PK','si-LK','sq-AL','sr-Cyrl-BA','sr-Cyrl-RS','sw-KE','ta-IN','te-IN','tg-Cyrl-TJ','ti-ET','tk-TM','tn-ZA','tt-RU','ug-CN','ur-PK','uz-Latn-UZ','vi-VN','wo-SN','xh-ZA','yo-NG','zu-ZA')]
        [string]$SetSKUIntlDefaults,
        [Parameter(ParameterSetName='Language')]
        [ValidateSet('ar-SA','bg-BG','zh-CN','zh-TW','hr-HR','cs-CZ','da-DK','nl-NL','en-US','en-GB','et-EE','fi-FI','fr-CA','fr-FR','de-DE','el-GR','he-IL','hu-HU','it-IT','ja-JP','ko-KR','lv-LV','lt-LT','nb-NO','pl-PL','pt-BR','pt-PT','ro-RO','ru-RU','sr-Latn-RS','sk-SK','sl-SI','es-MX','es-ES','sv-SE','th-TH','tr-TR','uk-UA','af-ZA','am-ET','as-IN','az-Latn-AZ','be-BY','bn-BD','bn-IN','bs-Latn-BA','ca-ES','ca-ES-valencia','chr-CHER-US','cy-GB','eu-ES','fa-IR','fil-PH','ga-IE','gd-GB','gl-ES','gu-IN','ha-Latn-NG','hi-IN','hy-AM','id-ID','ig-NG','is-IS','ka-GE','kk-KZ','km-KH','kn-IN','kok-IN','ku-ARAB-IQ','ky-KG','lb-LU','lo-LA','mi-NZ','mk-MK','ml-IN','mn-MN','mr-IN','ms-MY','mt-MT','ne-NP','nn-NO','nso-ZA','or-IN','pa-Arab-PK','pa-IN','prs-AF','quc-Latn-GT','quz-PE','rw-RW','sd-Arab-PK','si-LK','sq-AL','sr-Cyrl-BA','sr-Cyrl-RS','sw-KE','ta-IN','te-IN','tg-Cyrl-TJ','ti-ET','tk-TM','tn-ZA','tt-RU','ug-CN','ur-PK','uz-Latn-UZ','vi-VN','wo-SN','xh-ZA','yo-NG','zu-ZA')]
        [string]$SetSetupUILang,
        [Parameter(ParameterSetName='Language')]
        [string]$SetSysLocale,
        [Parameter(ParameterSetName='Language')]
        [ValidateSet('ar-SA','bg-BG','zh-CN','zh-TW','hr-HR','cs-CZ','da-DK','nl-NL','en-US','en-GB','et-EE','fi-FI','fr-CA','fr-FR','de-DE','el-GR','he-IL','hu-HU','it-IT','ja-JP','ko-KR','lv-LV','lt-LT','nb-NO','pl-PL','pt-BR','pt-PT','ro-RO','ru-RU','sr-Latn-RS','sk-SK','sl-SI','es-MX','es-ES','sv-SE','th-TH','tr-TR','uk-UA','af-ZA','am-ET','as-IN','az-Latn-AZ','be-BY','bn-BD','bn-IN','bs-Latn-BA','ca-ES','ca-ES-valencia','chr-CHER-US','cy-GB','eu-ES','fa-IR','fil-PH','ga-IE','gd-GB','gl-ES','gu-IN','ha-Latn-NG','hi-IN','hy-AM','id-ID','ig-NG','is-IS','ka-GE','kk-KZ','km-KH','kn-IN','kok-IN','ku-ARAB-IQ','ky-KG','lb-LU','lo-LA','mi-NZ','mk-MK','ml-IN','mn-MN','mr-IN','ms-MY','mt-MT','ne-NP','nn-NO','nso-ZA','or-IN','pa-Arab-PK','pa-IN','prs-AF','quc-Latn-GT','quz-PE','rw-RW','sd-Arab-PK','si-LK','sq-AL','sr-Cyrl-BA','sr-Cyrl-RS','sw-KE','ta-IN','te-IN','tg-Cyrl-TJ','ti-ET','tk-TM','tn-ZA','tt-RU','ug-CN','ur-PK','uz-Latn-UZ','vi-VN','wo-SN','xh-ZA','yo-NG','zu-ZA')]
        [string]$SetUILang,
        [Parameter(ParameterSetName='Language')]
        [ValidateSet('ar-SA','bg-BG','zh-CN','zh-TW','hr-HR','cs-CZ','da-DK','nl-NL','en-US','en-GB','et-EE','fi-FI','fr-CA','fr-FR','de-DE','el-GR','he-IL','hu-HU','it-IT','ja-JP','ko-KR','lv-LV','lt-LT','nb-NO','pl-PL','pt-BR','pt-PT','ro-RO','ru-RU','sr-Latn-RS','sk-SK','sl-SI','es-MX','es-ES','sv-SE','th-TH','tr-TR','uk-UA','af-ZA','am-ET','as-IN','az-Latn-AZ','be-BY','bn-BD','bn-IN','bs-Latn-BA','ca-ES','ca-ES-valencia','chr-CHER-US','cy-GB','eu-ES','fa-IR','fil-PH','ga-IE','gd-GB','gl-ES','gu-IN','ha-Latn-NG','hi-IN','hy-AM','id-ID','ig-NG','is-IS','ka-GE','kk-KZ','km-KH','kn-IN','kok-IN','ku-ARAB-IQ','ky-KG','lb-LU','lo-LA','mi-NZ','mk-MK','ml-IN','mn-MN','mr-IN','ms-MY','mt-MT','ne-NP','nn-NO','nso-ZA','or-IN','pa-Arab-PK','pa-IN','prs-AF','quc-Latn-GT','quz-PE','rw-RW','sd-Arab-PK','si-LK','sq-AL','sr-Cyrl-BA','sr-Cyrl-RS','sw-KE','ta-IN','te-IN','tg-Cyrl-TJ','ti-ET','tk-TM','tn-ZA','tt-RU','ug-CN','ur-PK','uz-Latn-UZ','vi-VN','wo-SN','xh-ZA','yo-NG','zu-ZA')]
        [string]$SetUILangFallback,
        [Parameter(ParameterSetName='Language')]
        [string]$SetUserLocale

    )
    #======================================================================================
    #   Start 18.9.27
    #======================================================================================
    Write-Host "===========================================================================" -ForegroundColor Green
    Write-Host "New-OSBuildTask" -ForegroundColor Green
    Write-Host "===========================================================================" -ForegroundColor Green
    #======================================================================================
    #	Validate Administrator Rights 18.9.27
    #======================================================================================
    if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host ""
        Write-Host "OSBuilder: This function needs to be run as Administrator" -ForegroundColor Yellow
        Write-Host ""
        Return
    }
    #======================================================================================
    # Initialize OSBuilder 18.9.27
    #======================================================================================
    Get-OSBuilder -CreatePaths -HideDetails
    #======================================================================================
    # Information
    #======================================================================================
    $TaskName = "OSBuild $TaskName"
    $TaskPath = "$OSBuilderTasks\$TaskName.json"
    Write-Host "New OSBuild Task Settings" -ForegroundColor Yellow
    Write-Host "-Task Name:             $TaskName" -ForegroundColor Cyan
    Write-Host "-Task Path:             $TaskPath" -ForegroundColor Cyan
    Write-Host "-Build Name:            $BuildName" -ForegroundColor Cyan
    Write-Host "-DotNet 3.5:            $EnableNetFX3" -ForegroundColor Cyan
    Write-Host "-SetAllIntl:            $SetAllIntl" -ForegroundColor Cyan
    Write-Host "-SetInputLocale:        $SetInputLocale" -ForegroundColor Cyan
    Write-Host "-SetSKUIntlDefaults:    $SetSKUIntlDefaults" -ForegroundColor Cyan
    Write-Host "-SetSetupUILang:        $SetSetupUILang" -ForegroundColor Cyan
    Write-Host "-SetSysLocale:          $SetSysLocale" -ForegroundColor Cyan
    Write-Host "-SetUILang:             $SetUILang" -ForegroundColor Cyan
    Write-Host "-SetUILangFallback:     $SetUILangFallback" -ForegroundColor Cyan
    Write-Host "-SetUserLocale:         $SetUserLocale" -ForegroundColor Cyan
    Write-Host ""
    #======================================================================================
    # Validate Task
    #======================================================================================
    if (Test-Path $TaskPath) {
        Write-Warning "Task already exists at $TaskPath"
        Write-Warning "Content will be overwritten!"
        Write-Host ""
    }
    #======================================================================================
    # Validate OSMedia has Content
    #======================================================================================
    $SelectedOSMedia = Get-ChildItem -Path "$OSBuilderOSMedia" -Directory | Where-Object {$_.Name -like "*.*"} | Select-Object -Property Name, FullName
    if ($null -eq $SelectedOSMedia) {
        Write-Warning "OSMedia content not found.  Use Import-OSMedia to import an Operating System first . . . Exiting!"
        Break
    }
    #======================================================================================
    # Validate OSMedia has an install.wim
    #======================================================================================
    $SelectedOSMedia = $SelectedOSMedia | Where-Object {Test-Path $(Join-Path $_.FullName (Join-Path "OS" (Join-Path "sources" "install.wim")))}
    if ($null -eq $SelectedOSMedia) {
        Write-Warning "OSMedia Install.wim not found.  Use Import-OSMedia to import an Operating System first . . . Exiting!"
        Break
    }
    #======================================================================================
    # Validate OSMedia was imported with Import-OSMedia
    #======================================================================================
    $SelectedOSMedia = $SelectedOSMedia | Where-Object {Test-Path $(Join-Path $_.FullName "WindowsImage.txt")}
    if ($null -eq $SelectedOSMedia) {
        Write-Warning "OSMedia content invalid (missing WindowsImage.txt).  Use Import-OSMedia to import an Operating System first . . . Exiting!"
        Return
    }
    #======================================================================================
    # Select Source OSMedia
    #======================================================================================
    $SelectedOSMedia = $SelectedOSMedia | Out-GridView -Title "Select a Source OSMedia to use for this OSBuild Task (Cancel to Exit)" -OutputMode Single
    if($null -eq $SelectedOSMedia) {
        Write-Warning "Source OSMedia was not selected . . . Exiting!"
        Return
    }
    #======================================================================================
    # Get Windows Image Information 18.9.24
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
    if ($RemoveAppxProvisionedPackage.IsPresent) {
        #======================================================================================
        # Remove Provisioned Appx Package
        #======================================================================================
        if ($OSImageName -notlike "*server*") {
            $GetAppxProvisionedPackage = Get-Content -Path "$OSSourcePath\info\json\Get-AppxProvisionedPackage.json"
            $GetAppxProvisionedPackage = $GetAppxProvisionedPackage | ConvertFrom-Json
            $GetAppxProvisionedPackage = $GetAppxProvisionedPackage | Select-Object -Property DisplayName, PackageName
            $GetAppxProvisionedPackage = $GetAppxProvisionedPackage | Out-GridView -Title "Select Windows InBox Apps to REMOVE and press OK (Esc or Cancel to Skip)" -PassThru
            if($null -eq $GetAppxProvisionedPackage) {
                Write-Warning "No InBox Windows App was selected to REMOVE"
            }
        }
    }
    if ($RemoveWindowsPackage.IsPresent) {
        #======================================================================================
        # Remove Windows Package
        #======================================================================================
        $GetWindowsPackage = Get-Content -Path "$OSSourcePath\info\json\Get-WindowsPackage.json"
        $GetWindowsPackage = $GetWindowsPackage | ConvertFrom-Json
        $GetWindowsPackage = $GetWindowsPackage | Select-Object -Property PackageName
        $GetWindowsPackage = $GetWindowsPackage | Out-GridView -Title "Select Windows InBox Package to REMOVE and press OK (Esc or Cancel to Skip)" -PassThru
        if($null -eq $GetWindowsPackage) {
            Write-Warning "No InBox Windows Package was selected to REMOVE"
        }
    }
    if ($RemoveWindowsCapability.IsPresent) {
        #======================================================================================
        # Remove Windows Capability
        #======================================================================================
        $GetWindowsCapability = Get-Content -Path "$OSSourcePath\info\json\Get-WindowsCapability.json"
        $GetWindowsCapability = $GetWindowsCapability | ConvertFrom-Json
        $GetWindowsCapability = $GetWindowsCapability | Select-Object -Property Name, State
        $GetWindowsCapability = $GetWindowsCapability | Out-GridView -Title "Select Windows InBox Capability to REMOVE and press OK (Esc or Cancel to Skip)" -PassThru
        if($null -eq $GetWindowsCapability) {
            Write-Warning "No InBox Windows Capability was selected to REMOVE"
        }
    }
    #======================================================================================
    $GetWindowsOptionalFeature = Get-Content -Path "$OSSourcePath\info\json\Get-WindowsOptionalFeature.json"
    $GetWindowsOptionalFeature = $GetWindowsOptionalFeature | ConvertFrom-Json

    if ($DisableWindowsOptionalFeature.IsPresent) {
        $DisableWinOptionalFeature = $GetWindowsOptionalFeature | Select-Object -Property FeatureName, State | Sort-Object -Property FeatureName | Where-Object {$_.State -eq 2}
        $DisableWinOptionalFeature = $DisableWinOptionalFeature | Select-Object -Property FeatureName
        $DisableWinOptionalFeature = $DisableWinOptionalFeature | Out-GridView -PassThru -Title "Select Enabled Windows Optional Features to DISABLE and press OK (Esc or Cancel to Skip)"
        if($null -eq $DisableWinOptionalFeature) {
            Write-Warning "No Enabled InBox Windows Optional Feature was selected to DISABLE"
        }
    }

    if ($EnableWindowsOptionalFeature.IsPresent) {
        $EnableWinOptionalFeature = $GetWindowsOptionalFeature | Select-Object -Property FeatureName, State | Sort-Object -Property FeatureName | Where-Object {$_.State -eq 0}
        $EnableWinOptionalFeature = $EnableWinOptionalFeature | Select-Object -Property FeatureName
        $EnableWinOptionalFeature = $EnableWinOptionalFeature | Out-GridView -PassThru -Title "Select Disabled Windows Optional Features to ENABLE and press OK (Esc or Cancel to Skip)"
        if($null -eq $EnableWinOptionalFeature) {
            Write-Warning "No Disabled InBox Windows Optional Feature was selected to ENABLE"
        }
    }
    #======================================================================================
    #   IsoExtract Content 18.9.26
    #======================================================================================
    $IsoExtractContent = @()
    $IsoExtractContent = Get-ChildItem -Path "$OSBuilderContent\IsoExtract" *.cab -Recurse | Select-Object -Property Name, FullName
    foreach ($IsoExtractPackage in $IsoExtractContent) {$IsoExtractPackage.FullName = $($IsoExtractPackage.FullName).replace("$OSBuilderContent\",'')}
    #======================================================================================
    #   IsoExtract Features On Demand 18.9.26
    #======================================================================================
    $IsoExtractFeaturesOnDemand =@()
    $IsoExtractFeaturesOnDemand = $IsoExtractContent
    foreach ($Pack in $IsoExtractFeaturesOnDemand) {$Pack.FullName = $($Pack.FullName).replace("$OSBuilderContent\",'')}
    $IsoExtractFeaturesOnDemand = $IsoExtractFeaturesOnDemand | Where-Object {$_.FullName -notlike "*Windows Preinstallation Environment*"}
    $IsoExtractFeaturesOnDemand = $IsoExtractFeaturesOnDemand | Where-Object {$_.Name -notlike "*lp.cab"}
    $IsoExtractFeaturesOnDemand = $IsoExtractFeaturesOnDemand | Where-Object {$_.Name -notlike "*Language-Pack*"}
    $IsoExtractFeaturesOnDemand = $IsoExtractFeaturesOnDemand | Where-Object {$_.Name -notlike "*Language-Interface-Pack*"}
    $IsoExtractFeaturesOnDemand = $IsoExtractFeaturesOnDemand | Where-Object {$_.Name -notlike "*LanguageFeatures*"}
    if ($OSArchitecture -eq 'x64') {$IsoExtractFeaturesOnDemand = $IsoExtractFeaturesOnDemand | Where-Object {$_.Name -notlike "*x86*"}}
    if ($OSArchitecture -eq 'x64') {$IsoExtractFeaturesOnDemand = $IsoExtractFeaturesOnDemand | Where-Object {$_.FullName -notlike "*W32*"}}
    if ($OSArchitecture -eq 'x86') {$IsoExtractFeaturesOnDemand = $IsoExtractFeaturesOnDemand | Where-Object {$_.Name -notlike "*x64*"}}
    if ($OSArchitecture -eq 'x86') {$IsoExtractFeaturesOnDemand = $IsoExtractFeaturesOnDemand | Where-Object {$_.Name -notlike "*amd64*"}}
    if ($OSArchitecture -eq 'x86') {$IsoExtractFeaturesOnDemand = $IsoExtractFeaturesOnDemand | Where-Object {$_.FullName -notlike "*64Bit*"}}
    if ($OSVersionNumber) {$IsoExtractFeaturesOnDemand = $IsoExtractFeaturesOnDemand | Where-Object {$_.FullName -like "*$OSVersionNumber*"}}
    #======================================================================================
    #   Select Features On Demand 18.9.26
    #======================================================================================
	$SelectedFeaturesOnDemand = @()
	$SelectedFeaturesOnDemand = $IsoExtractFeaturesOnDemand
    if($null -eq $SelectedFeaturesOnDemand) {Write-Warning "Features On Demand: No compatible Packages were found"}
    else {
        $SelectedFeaturesOnDemand = $SelectedFeaturesOnDemand | Sort-Object -Property FullName | Out-GridView -Title "Features On Demand: Select Packages to apply and press OK (Esc or Cancel to Skip)" -PassThru
        if($null -eq $SelectedFeaturesOnDemand) {Write-Warning "Features On Demand: Skipping"}
    }
    #======================================================================================
    #   IsoExtract Language Packs 18.9.26
    #======================================================================================
    $IsoExtractLanguagePacks = @()
    $IsoExtractLanguagePacks = $IsoExtractContent | Where-Object {$_.Name -eq 'lp.cab' -or $_.Name -like "*Language-Pack*"}
    $IsoExtractLanguagePacks = $IsoExtractLanguagePacks | Where-Object {$_.FullName -notlike "*Windows Preinstallation Environment*"}
    $IsoExtractLanguagePacks = $IsoExtractLanguagePacks | Where-Object {$_.Name -notlike "*arm64*"}
    $IsoExtractLanguagePacks = $IsoExtractLanguagePacks | Where-Object {$_.Name -notlike "*Server*"}
    $IsoExtractLanguagePacks = $IsoExtractLanguagePacks | Where-Object {$_.FullName -like "*\$OSArchitecture\*"}
    if ($OSVersionNumber) {$IsoExtractLanguagePacks = $IsoExtractLanguagePacks | Where-Object {$_.FullName -like "*$OSVersionNumber*"}}
    #======================================================================================
    #   Updates Language Packs 18.9.26
    #======================================================================================
    $UpdatesLanguagePacks = @()
    $UpdatesLanguagePacks = Get-ChildItem -Path "$OSBuilderContent\Updates\LanguagePack" *.cab -Recurse | Select-Object -Property Name, FullName
    $UpdatesLanguagePacks = $UpdatesLanguagePacks | Where-Object {$_.FullName -like "*$OSArchitecture*"}
    if ($OSVersionNumber) {$UpdatesLanguagePacks = $UpdatesLanguagePacks | Where-Object {$_.FullName -like "*$OSVersionNumber*"}}
    #======================================================================================
    #   Legacy Language Packs 18.9.26
    #======================================================================================
    $LegacyLanguagePacks = @()
    if (Test-Path "$OSBuilderContent\LanguagePacks") {
        $LegacyLanguagePacks = Get-ChildItem -Path "$OSBuilderContent\LanguagePacks" *.cab -Recurse | Select-Object -Property Name, FullName
        $LegacyLanguagePacks = $LegacyLanguagePacks | Where-Object {$_.FullName -like "*$OSArchitecture*"}
        if ($OSVersionNumber) {$LegacyLanguagePacks = $LegacyLanguagePacks | Where-Object {$_.FullName -like "*$OSVersionNumber*"}}
    }
    #======================================================================================
    #   Select Language Packs 18.9.26
    #======================================================================================
    $SelectedLanguagePacks = @()
    $SelectedLanguagePacks = $IsoExtractLanguagePacks + $UpdatesLanguagePacks + $LegacyLanguagePacks
    foreach ($Package in $SelectedLanguagePacks) {$Package.FullName = $($Package.FullName).replace("$OSBuilderContent\",'')}
    if($null -eq $SelectedLanguagePacks) {Write-Warning "Language Packs: No compatible Packages were found"}
    else {
        $SelectedLanguagePacks = $SelectedLanguagePacks | Sort-Object -Property FullName | Out-GridView -Title "Language Packs: Select Packages to apply and press OK (Esc or Cancel to Skip)" -PassThru
        if($null -eq $SelectedLanguagePacks) {Write-Warning "Language Packs: Skipping"}
    }
    #======================================================================================
    #   IsoExtract Language Interface Packs 18.9.26
    #======================================================================================
    $IsoExtractLanguageInterfacePacks = @()
    $IsoExtractLanguageInterfacePacks = $IsoExtractContent | Where-Object {$_.Name -like "*Language-Interface-Pack*"}
    $IsoExtractLanguageInterfacePacks = $IsoExtractLanguageInterfacePacks | Where-Object {$_.Name -notlike "*arm64*"}
    $IsoExtractLanguageInterfacePacks = $IsoExtractLanguageInterfacePacks | Where-Object {$_.Name -like "*$OSArchitecture*"}
    if ($OSVersionNumber) {$IsoExtractLanguageInterfacePacks = $IsoExtractLanguageInterfacePacks | Where-Object {$_.FullName -like "*$OSVersionNumber*"}}
    #======================================================================================
    #   Updates Language Interface Packs 18.9.24
    #======================================================================================
    $UpdatesLanguageInterfacePacks = @()
    $UpdatesLanguageInterfacePacks = Get-ChildItem -Path "$OSBuilderContent\Updates\LanguageInterfacePack" *.cab -Recurse | Select-Object -Property Name, FullName
    $UpdatesLanguageInterfacePacks = $UpdatesLanguageInterfacePacks | Where-Object {$_.FullName -like "*$OSArchitecture*"}
    if ($OSVersionNumber) {$UpdatesLanguageInterfacePacks = $UpdatesLanguageInterfacePacks | Where-Object {$_.FullName -like "*$OSVersionNumber*"}}
    #======================================================================================
    #   Select Language Interface Packs 18.9.27
    #======================================================================================
    $SelectedLanguageInterfacePacks = @()
    $SelectedLanguageInterfacePacks = $IsoExtractLanguageInterfacePacks + $UpdatesLanguageInterfacePacks
    foreach ($Package in $SelectedLanguageInterfacePacks) {$Package.FullName = $($Package.FullName).replace("$OSBuilderContent\",'')}
    if($null -eq $SelectedLanguageInterfacePacks) {Write-Warning "Language Interface Packs: No compatible Packages were found"}
    else {
        $SelectedLanguageInterfacePacks = $SelectedLanguageInterfacePacks | Sort-Object -Property FullName | Out-GridView -Title "Language Interface Packs: Select Packages to apply and press OK (Esc or Cancel to Skip)" -PassThru
        if($null -eq $SelectedLanguageInterfacePacks) {Write-Warning "Language Interface Packs: Skipping"}
    }
    #======================================================================================
    #   IsoExtract Language Features On Demand 18.9.26
    #======================================================================================
    $IsoExtractLanguageFeaturesOnDemand = @()
    $IsoExtractLanguageFeaturesOnDemand = $IsoExtractContent | Where-Object {$_.Name -like "*LanguageFeatures*"}
    if ($OSArchitecture -eq 'x86') {$IsoExtractLanguageFeaturesOnDemand = $IsoExtractLanguageFeaturesOnDemand | Where-Object {$_.Name -like "*x86*"}}
    if ($OSArchitecture -eq 'x64') {$IsoExtractLanguageFeaturesOnDemand = $IsoExtractLanguageFeaturesOnDemand | Where-Object {$_.Name -like "*x64*" -or $_.Name -like "*amd64*"}}
    if ($OSVersionNumber) {$IsoExtractLanguageFeaturesOnDemand = $IsoExtractLanguageFeaturesOnDemand | Where-Object {$_.FullName -like "*$OSVersionNumber*"}}
<#     if($null -eq $IsoExtractLanguageFeaturesOnDemand) {Write-Warning "IsoExtract Language Interface Packs: No compatible Packages were found in $OSBuilderContent\IsoExtract"}
    else {
        $IsoExtractLanguageFeaturesOnDemand = $IsoExtractLanguageFeaturesOnDemand | Out-GridView -Title "IsoExtract Language Features On Demand: Select Packages to apply and press OK (Esc or Cancel to Skip)" -PassThru
        if($null -eq $IsoExtractLanguageFeaturesOnDemand) {Write-Warning "IsoExtract Language Features On Demand: Skipping"}
    } #>
    #======================================================================================
    #   Updates Language Features On Demand 18.10.4
    #======================================================================================
    $UpdatesLanguageFeaturesOnDemand = @()
    $UpdatesLanguageFeaturesOnDemand = Get-ChildItem -Path "$OSBuilderContent\Updates\LanguageFeature" *.cab -Recurse | Select-Object -Property Name, FullName
    if ($OSArchitecture -eq 'x86') {$UpdatesLanguageFeaturesOnDemand = $UpdatesLanguageFeaturesOnDemand | Where-Object {$_.FullName -like "*x86*"}}
    if ($OSArchitecture -eq 'x64') {$UpdatesLanguageFeaturesOnDemand = $UpdatesLanguageFeaturesOnDemand | Where-Object {$_.FullName -like "*x64*" -or $_.FullName -like "*amd64*"}}
    if ($OSVersionNumber) {$UpdatesLanguageFeaturesOnDemand = $UpdatesLanguageFeaturesOnDemand | Where-Object {$_.FullName -like "*$OSVersionNumber*"}}
<#     $UpdatesLanguageFeaturesOnDemand = $UpdatesLanguageFeaturesOnDemand | Where-Object {$_.Name -ne 'lp.cab'}
    $UpdatesLanguageFeaturesOnDemand = $UpdatesLanguageFeaturesOnDemand | Where-Object {$_.Name -like "*LanguageFeatures*"} #>
    #$SelectedLanguageFeatures = $SelectedLanguageFeatures | Where-Object {$_.Name -like "*$OSArchitecture*"}
    #======================================================================================
    #   Select Language Features On Demand 18.9.28
    #======================================================================================
    $SelectedLanguageFeaturesOnDemand  = @()
    $SelectedLanguageFeaturesOnDemand = $IsoExtractLanguageFeaturesOnDemand + $UpdatesLanguageFeaturesOnDemand
    foreach ($Package in $SelectedLanguageFeaturesOnDemand) {$Package.FullName = $($Package.FullName).replace("$OSBuilderContent\",'')}
    if($null -eq $SelectedLanguageFeaturesOnDemand) {Write-Warning "Language Features On Demand: No compatible Packages were found"}
    else {
        $SelectedLanguageFeaturesOnDemand = $SelectedLanguageFeaturesOnDemand | Sort-Object -Property FullName | Out-GridView -Title "Language Features On Demand: Select Packages to apply and press OK (Esc or Cancel to Skip)" -PassThru
        if($null -eq $SelectedLanguageFeaturesOnDemand) {Write-Warning "Language Features On Demand: Skipping"}
    }
    #======================================================================================
    #   PowerShell Scripts 18.9.28
    #======================================================================================
    $SelectedScripts =@()
    $SelectedScripts = Get-ChildItem -Path "$OSBuilderContent\Scripts" *.ps1 | Select-Object -Property Name, FullName
    foreach ($Pack in $SelectedScripts) {$Pack.FullName = $($Pack.FullName).replace("$OSBuilderContent\",'')}
    $SelectedScripts = $SelectedScripts | Out-GridView -Title "Select Install WIM PowerShell Scripts to execute and press OK (Esc or Cancel to Skip)" -PassThru
    if ($null -eq $SelectedScripts) {Write-Warning "Skipping Install WIM PowerShell Scripts"}
    #======================================================================================
    #   Start Layout 18.9.28
    #======================================================================================
    $SelectedStartLayoutXML =@()
    $SelectedStartLayoutXML = Get-ChildItem -Path "$OSBuilderContent\StartLayout" *.xml | Select-Object -Property Name, FullName, Length, CreationTime | Sort-Object -Property FullName
    foreach ($Pack in $SelectedStartLayoutXML) {$Pack.FullName = $($Pack.FullName).replace("$OSBuilderContent\",'')}
    #$SelectedStartLayoutXML = $SelectedStartLayoutXML | ? {$_.FullName -like "*$OSArchitecture*"}
    $SelectedStartLayoutXML = $SelectedStartLayoutXML | Out-GridView -Title "Select a Start Layout XML to apply and press OK (Esc or Cancel to Skip)" -OutputMode Single
    if ($null -eq $SelectedStartLayoutXML) {Write-Warning "Skipping Start Layout"}
    #======================================================================================
    #   Unattend.xml 18.9.28
    #======================================================================================
    $SelectedUnattendXML =@()
    $SelectedUnattendXML = Get-ChildItem -Path "$OSBuilderContent\Unattend" *.xml | Select-Object -Property Name, FullName, Length, CreationTime | Sort-Object -Property FullName
    foreach ($Pack in $SelectedUnattendXML) {$Pack.FullName = $($Pack.FullName).replace("$OSBuilderContent\",'')}
    #$SelectedUnattendXML = $SelectedUnattendXML | ? {$_.FullName -like "*$OSArchitecture*"}
    $SelectedUnattendXML = $SelectedUnattendXML | Out-GridView -Title "Select a Windows Unattend XML File to apply and press OK (Esc or Cancel to Skip)" -OutputMode Single
    if($null -eq $SelectedUnattendXML) {Write-Warning "Skipping Unattend.xml"}
    #======================================================================================
    #   Windows Drivers 18.9.28
    #======================================================================================
    $SelectedDrivers =@()
    $SelectedDrivers = Get-ChildItem -Path "$OSBuilderContent\Drivers" -Directory | Select-Object -Property Name, FullName
    foreach ($Pack in $SelectedDrivers) {$Pack.FullName = $($Pack.FullName).replace("$OSBuilderContent\",'')}
    $SelectedDrivers = $SelectedDrivers | Out-GridView -Title "Select Driver Paths to apply and press OK (Esc or Cancel to Skip)" -PassThru
    if($null -eq $SelectedDrivers) {Write-Warning "Skipping Drivers"}
    #======================================================================================
    #   Extra Files 18.9.28
    #======================================================================================
    $SelectedExtraFiles =@()
    $SelectedExtraFiles = Get-ChildItem -Path "$OSBuilderContent\ExtraFiles" -Directory | Select-Object -Property Name, FullName
    $SelectedExtraFiles = $SelectedExtraFiles | Where-Object {(Get-ChildItem $_.FullName | Measure-Object).Count -gt 0}
    foreach ($Pack in $SelectedExtraFiles) {$Pack.FullName = $($Pack.FullName).replace("$OSBuilderContent\",'')}
    $SelectedExtraFiles = $SelectedExtraFiles | Out-GridView -Title "Select Extra Files to apply and press OK (Esc or Cancel to Skip)" -PassThru
    if($null -eq $SelectedExtraFiles) {Write-Warning "Skipping Extra Files"}
    #======================================================================================
    #   Windows Packages 18.9.28
    #======================================================================================
    $SelectedPackages =@()
    $SelectedPackages = Get-ChildItem -Path "$OSBuilderContent\Packages" *.cab -Recurse | Select-Object -Property Name, FullName
    foreach ($Pack in $SelectedPackages) {$Pack.FullName = $($Pack.FullName).replace("$OSBuilderContent\",'')}
    $SelectedPackages = $SelectedPackages | Where-Object {$_.FullName -like "*$OSArchitecture*"}
    $SelectedPackages = $SelectedPackages | Out-GridView -Title "Select Packages to apply and press OK (Esc or Cancel to Skip)" -PassThru
    if($null -eq $SelectedPackages) {Write-Warning "Skipping Packages"}
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
    #   Setup WIM Scripts 18.9.28
    #======================================================================================
    $SelectedWinPEScriptsSetup =@()
    $SelectedWinPEScriptsSetup = Get-ChildItem -Path "$OSBuilderContent\WinPE\Scripts" *.ps1 | Select-Object -Property Name, FullName
    foreach ($Pack in $SelectedWinPEScriptsSetup) {$Pack.FullName = $($Pack.FullName).replace("$OSBuilderContent\",'')}
    $SelectedWinPEScriptsSetup = $SelectedWinPEScriptsSetup | Out-GridView -Title "Select Setup WIM PowerShell Scripts to execute and press OK (Esc or Cancel to Skip)" -PassThru
    if($null -eq $SelectedWinPEScriptsSetup) {Write-Warning "Skipping Setup WIM PowerShell Scripts"}
    #======================================================================================
    #   WinPE WIM Scripts 18.9.28
    #======================================================================================
    $SelectedWinPEScriptsPE =@()
    $SelectedWinPEScriptsPE = Get-ChildItem -Path "$OSBuilderContent\WinPE\Scripts" *.ps1 | Select-Object -Property Name, FullName
    foreach ($Pack in $SelectedWinPEScriptsPE) {$Pack.FullName = $($Pack.FullName).replace("$OSBuilderContent\",'')}
    $SelectedWinPEScriptsPE = $SelectedWinPEScriptsPE | Out-GridView -Title "Select WinPE WIM PowerShell Scripts to execute and press OK (Esc or Cancel to Skip)" -PassThru
    if($null -eq $SelectedWinPEScriptsPE) {Write-Warning "Skipping WinPE WIM PowerShell Scripts"}
    #======================================================================================
    #   WinRE WIM Scripts 18.9.28
    #======================================================================================
    $SelectedWinPEScriptsRE =@()
    $SelectedWinPEScriptsRE = Get-ChildItem -Path "$OSBuilderContent\WinPE\Scripts" *.ps1 | Select-Object -Property Name, FullName
    foreach ($Pack in $SelectedWinPEScriptsRE) {$Pack.FullName = $($Pack.FullName).replace("$OSBuilderContent\",'')}
    $SelectedWinPEScriptsRE = $SelectedWinPEScriptsRE | Out-GridView -Title "Select WinRE WIM PowerShell Scripts to execute and press OK (Esc or Cancel to Skip)" -PassThru
    if($null -eq $SelectedWinPEScriptsRE) {Write-Warning "Skipping WinRE WIM PowerShell Scripts"}
    #======================================================================================
    #   Setup WIM Extra Files 18.9.28
    #======================================================================================
    $SelectedWinPEExtraFilesSetup =@()
    $SelectedWinPEExtraFilesSetup = Get-ChildItem -Path "$OSBuilderContent\WinPE\ExtraFiles" -Directory | Select-Object -Property Name, FullName
    $SelectedWinPEExtraFilesSetup = $SelectedWinPEExtraFilesSetup | Where-Object {(Get-ChildItem $_.FullName | Measure-Object).Count -gt 0}
    foreach ($Pack in $SelectedWinPEExtraFilesSetup) {$Pack.FullName = $($Pack.FullName).replace("$OSBuilderContent\",'')}
    $SelectedWinPEExtraFilesSetup = $SelectedWinPEExtraFilesSetup | Out-GridView -Title "Select Setup WIM Extra Files to apply and press OK (Esc or Cancel to Skip)" -PassThru
    if($null -eq $SelectedWinPEExtraFilesSetup) {Write-Warning "Skipping Setup WIM Extra Files"}
    #======================================================================================
    #   WinPE WIM Extra Files 18.9.28
    #======================================================================================
    $SelectedWinPEExtraFilesPE =@()
    $SelectedWinPEExtraFilesPE = Get-ChildItem -Path "$OSBuilderContent\WinPE\ExtraFiles" -Directory | Select-Object -Property Name, FullName
    $SelectedWinPEExtraFilesPE = $SelectedWinPEExtraFilesPE | Where-Object {(Get-ChildItem $_.FullName | Measure-Object).Count -gt 0}
    foreach ($Pack in $SelectedWinPEExtraFilesPE) {$Pack.FullName = $($Pack.FullName).replace("$OSBuilderContent\",'')}
    $SelectedWinPEExtraFilesPE = $SelectedWinPEExtraFilesPE | Out-GridView -Title "Select WinPE WIM Extra Files to apply and press OK (Esc or Cancel to Skip)" -PassThru
    if($null -eq $SelectedWinPEExtraFilesPE) {Write-Warning "Skipping WinPE WIM Extra Files"}
    #======================================================================================
    #   WinRE WIM Extra Files 18.9.28
    #======================================================================================
    $SelectedWinPEExtraFilesRE =@()
    $SelectedWinPEExtraFilesRE = Get-ChildItem -Path "$OSBuilderContent\WinPE\ExtraFiles" -Directory | Select-Object -Property Name, FullName
    $SelectedWinPEExtraFilesRE = $SelectedWinPEExtraFilesRE | Where-Object {(Get-ChildItem $_.FullName | Measure-Object).Count -gt 0}
    foreach ($Pack in $SelectedWinPEExtraFilesRE) {$Pack.FullName = $($Pack.FullName).replace("$OSBuilderContent\",'')}
    $SelectedWinPEExtraFilesRE = $SelectedWinPEExtraFilesRE | Out-GridView -Title "Select WinRE WIM Extra Files to apply and press OK (Esc or Cancel to Skip)" -PassThru
    if($null -eq $SelectedWinPEExtraFilesRE) {Write-Warning "Skipping WinRE WIM Extra Files"}
    #======================================================================================
    #   Setup WIM ADK Packages 18.9.28
    #======================================================================================
    $SelectedWinPEADKSetupPkgs =@()
    $SelectedWinPEADKSetupPkgs = Get-ChildItem -Path "$OSBuilderContent\WinPE\ADK" *.cab -Recurse | Select-Object -Property Name, FullName
    foreach ($Pack in $SelectedWinPEADKSetupPkgs) {$Pack.FullName = $($Pack.FullName).replace("$OSBuilderContent\",'')}
    $SelectedWinPEADKSetupPkgs = $SelectedWinPEADKSetupPkgs | Where-Object {$_.FullName -like "*$OSArchitecture*"}
    $SelectedWinPEADKSetupPkgs = $SelectedWinPEADKSetupPkgs | Where-Object {$_.FullName -like "*$OSVersionNumber*"}
    $SelectedWinPEADKSetupPkgs = $SelectedWinPEADKSetupPkgs | Where-Object {$_.Name -notlike "WinPE-EnhancedStorage*"}
    $SelectedWinPEADKSetupPkgs = $SelectedWinPEADKSetupPkgs | Where-Object {$_.Name -notlike "WinPE-Font*"}
    $SelectedWinPEADKSetupPkgs = $SelectedWinPEADKSetupPkgs | Where-Object {$_.Name -notlike "WinPE-LegacySetup*"}
    $SelectedWinPEADKSetupPkgs = $SelectedWinPEADKSetupPkgs | Where-Object {$_.Name -notlike "WinPE-SRT*"}
    $SelectedWinPEADKSetupPkgs = $SelectedWinPEADKSetupPkgs | Where-Object {$_.Name -notlike "WinPE-Scripting*"}
    $SelectedWinPEADKSetupPkgs = $SelectedWinPEADKSetupPkgs | Where-Object {$_.Name -notlike "WinPE-SecureStartup*"}
    $SelectedWinPEADKSetupPkgs = $SelectedWinPEADKSetupPkgs | Where-Object {$_.Name -notlike "WinPE-Setup*"}
    $SelectedWinPEADKSetupPkgs = $SelectedWinPEADKSetupPkgs | Where-Object {$_.Name -notlike "WinPE-WDS*"}
    $SelectedWinPEADKSetupPkgs = $SelectedWinPEADKSetupPkgs | Where-Object {$_.Name -notlike "WinPE-WMI*"}
    $SelectedWinPEADKSetupPkgs = $SelectedWinPEADKSetupPkgs | Out-GridView -Title "Select Setup WIM ADK Packages to apply and press OK (Esc or Cancel to Skip)" -PassThru
    if($null -eq $SelectedWinPEADKSetupPkgs) {Write-Warning "Skipping Setup WIM ADK Packages"}
    #======================================================================================
    # WinPE WIM ADK Packages 18.9.28
    #======================================================================================
    $SelectedWinPEADKPEPkgs = Get-ChildItem -Path "$OSBuilderContent\WinPE\ADK" *.cab -Recurse | Select-Object -Property Name, FullName
    foreach ($Pack in $SelectedWinPEADKPEPkgs) {$Pack.FullName = $($Pack.FullName).replace("$OSBuilderContent\",'')}
    $SelectedWinPEADKPEPkgs = $SelectedWinPEADKPEPkgs | Where-Object {$_.FullName -like "*$OSArchitecture*"}
    $SelectedWinPEADKPEPkgs = $SelectedWinPEADKPEPkgs | Where-Object {$_.FullName -like "*$OSVersionNumber*"}
    $SelectedWinPEADKPEPkgs = $SelectedWinPEADKPEPkgs | Where-Object {$_.Name -notlike "WinPE-EnhancedStorage*"}
    $SelectedWinPEADKPEPkgs = $SelectedWinPEADKPEPkgs | Where-Object {$_.Name -notlike "WinPE-Font*"}
    $SelectedWinPEADKPEPkgs = $SelectedWinPEADKPEPkgs | Where-Object {$_.Name -notlike "WinPE-LegacySetup*"}
    $SelectedWinPEADKPEPkgs = $SelectedWinPEADKPEPkgs | Where-Object {$_.Name -notlike "WinPE-SRT*"}
    $SelectedWinPEADKPEPkgs = $SelectedWinPEADKPEPkgs | Where-Object {$_.Name -notlike "WinPE-Scripting*"}
    $SelectedWinPEADKPEPkgs = $SelectedWinPEADKPEPkgs | Where-Object {$_.Name -notlike "WinPE-SecureStartup*"}
    $SelectedWinPEADKPEPkgs = $SelectedWinPEADKPEPkgs | Where-Object {$_.Name -notlike "WinPE-Setup*"}
    $SelectedWinPEADKPEPkgs = $SelectedWinPEADKPEPkgs | Where-Object {$_.Name -notlike "WinPE-WDS*"}
    $SelectedWinPEADKPEPkgs = $SelectedWinPEADKPEPkgs | Where-Object {$_.Name -notlike "WinPE-WMI*"}
    $SelectedWinPEADKPEPkgs = $SelectedWinPEADKPEPkgs | Out-GridView -Title "Select WinPE WIM ADK Packages to apply and press OK (Esc or Cancel to Skip)" -PassThru
    if($null -eq $SelectedWinPEADKPEPkgs) {Write-Warning "Skipping WinPE WIM ADK Packages"}
    #======================================================================================
    # WinRE WIM ADK Packages 18.9.28
    #======================================================================================
    $SelectedWinPEADKREPkgs = Get-ChildItem -Path "$OSBuilderContent\WinPE\ADK" *.cab -Recurse | Select-Object -Property Name, FullName
    foreach ($Pack in $SelectedWinPEADKREPkgs) {$Pack.FullName = $($Pack.FullName).replace("$OSBuilderContent\",'')}
    $SelectedWinPEADKREPkgs = $SelectedWinPEADKREPkgs | Where-Object {$_.FullName -like "*$OSArchitecture*"}
    $SelectedWinPEADKREPkgs = $SelectedWinPEADKREPkgs | Where-Object {$_.FullName -like "*$OSVersionNumber*"}
    $SelectedWinPEADKREPkgs = $SelectedWinPEADKREPkgs | Where-Object {$_.Name -notlike "WinPE-EnhancedStorage*"}
    $SelectedWinPEADKREPkgs = $SelectedWinPEADKREPkgs | Where-Object {$_.Name -notlike "WinPE-FMAPI*"}
    $SelectedWinPEADKREPkgs = $SelectedWinPEADKREPkgs | Where-Object {$_.Name -notlike "WinPE-Font*"}
    $SelectedWinPEADKREPkgs = $SelectedWinPEADKREPkgs | Where-Object {$_.Name -notlike "WinPE-HTA*"}
    $SelectedWinPEADKREPkgs = $SelectedWinPEADKREPkgs | Where-Object {$_.Name -notlike "WinPE-LegacySetup*"}
    $SelectedWinPEADKREPkgs = $SelectedWinPEADKREPkgs | Where-Object {$_.Name -notlike "WinPE-Rejuv*"}
    $SelectedWinPEADKREPkgs = $SelectedWinPEADKREPkgs | Where-Object {$_.Name -notlike "WinPE-SRT*"}
    $SelectedWinPEADKREPkgs = $SelectedWinPEADKREPkgs | Where-Object {$_.Name -notlike "WinPE-Scripting*"}
    $SelectedWinPEADKREPkgs = $SelectedWinPEADKREPkgs | Where-Object {$_.Name -notlike "WinPE-SecureStartup*"}
    $SelectedWinPEADKREPkgs = $SelectedWinPEADKREPkgs | Where-Object {$_.Name -notlike "WinPE-Setup*"}
    $SelectedWinPEADKREPkgs = $SelectedWinPEADKREPkgs | Where-Object {$_.Name -notlike "WinPE-StorageWMI*"}
    $SelectedWinPEADKREPkgs = $SelectedWinPEADKREPkgs | Where-Object {$_.Name -notlike "WinPE-WDS*"}
    $SelectedWinPEADKREPkgs = $SelectedWinPEADKREPkgs | Where-Object {$_.Name -notlike "WinPE-WMI*"}
    $SelectedWinPEADKREPkgs = $SelectedWinPEADKREPkgs | Out-GridView -Title "Select WinRE WIM ADK Packages to apply and press OK (Esc or Cancel to Skip)" -PassThru
    if($null -eq $SelectedWinPEADKREPkgs) {
        Write-Warning "Skipping WinRE WIM ADK Packages"
    } else {
        Write-Warning "If you add too many ADK Packages to WinRE, like .Net and PowerShell"
        Write-Warning "You run a risk of your WinRE size increasing considerably"
        Write-Warning "If your MBR System or UEFI Recovery Partition are 500MB,"
        Write-Warning "your WinRE.wim should not be more than 400MB (100MB Free)"
        Write-Warning "Consider changing your Task Sequences to have a 984MB"
        Write-Warning "MBR System or UEFI Recovery Partition"
    }
    #======================================================================================
    # Build Task 18.9.28
    #======================================================================================
    $Task = [ordered]@{
    "TaskName" = [string]$TaskName;
    "TaskVersion" = [string]$($(Get-Module -Name OSBuilder).Version);
    "TaskType" = [string]"OSBuild";
    "MediaName" = [string]$SelectedOSMedia.Name;
    "BuildName" = [string]$BuildName;
    "AddFeatureOnDemand" = [string[]]$SelectedFeaturesOnDemand.FullName;
    "AddLanguageFeature" = [string[]]$SelectedLanguageFeaturesOnDemand.FullName;
    "AddLanguageInterfacePack" = [string[]]$SelectedLanguageInterfacePacks.FullName;
    "AddLanguagePack" = [string[]]$SelectedLanguagePacks.FullName;
    "AddWindowsDriver" = [string[]]$SelectedDrivers.FullName;
    "AddWindowsPackage" = [string[]]$SelectedPackages.FullName;
    "DisableWindowsOptionalFeature" = [string[]]$DisableWinOptionalFeature.FeatureName;
    "EnableNetFX3" = [string]$EnableNetFX3;
    "EnableWindowsOptionalFeature" = [string[]]$EnableWinOptionalFeature.FeatureName;
    "ImportStartLayout" = [string]$SelectedStartLayoutXML.FullName;
    "InvokeScript" = [string[]]$SelectedScripts.FullName;
    "LangSetAllIntl" = [string]$SetAllIntl;
    "LangSetInputLocale" = [string]$SetInputLocale;
    "LangSetSKUIntlDefaults" = [string]$SetSKUIntlDefaults;
    "LangSetSetupUILang" = [string]$SetSetupUILang;
    "LangSetSysLocale" = [string]$SetSysLocale;
    "LangSetUILang" = [string]$SetUILang;
    "LangSetUILangFallback" = [string]$SetUILangFallback;
    "LangSetUserLocale" = [string]$SetUserLocale;
    "RemoveAppxProvisionedPackage" = [string[]]$GetAppxProvisionedPackage.PackageName;
    "RemoveWindowsCapability" = [string[]]$GetWindowsCapability.Name;
    "RemoveWindowsPackage" = [string[]]$GetWindowsPackage.PackageName;
    "RobocopyExtraFiles" = [string[]]$SelectedExtraFiles.FullName;
    "UseWindowsUnattend" = [string]$SelectedUnattendXML.FullName;
    "WinPEAddADKPE" = [string[]]$SelectedWinPEADKPEPkgs.FullName;
    "WinPEAddADKRE" = [string[]]$SelectedWinPEADKREPkgs.FullName;
    "WinPEAddADKSetup" = [string[]]$SelectedWinPEADKSetupPkgs.FullName;
    "WinPEAddDaRT" = [string]$SelectedWinPEDaRT.FullName;
    "WinPEAddWindowsDriver" = [string[]]$SelectedWinPEDrivers.FullName;
    "WinPEInvokeScriptPE" = [string[]]$SelectedWinPEScriptsPE.FullName;
    "WinPEInvokeScriptRE" = [string[]]$SelectedWinPEScriptsRE.FullName;
    "WinPEInvokeScriptSetup" = [string[]]$SelectedWinPEScriptsSetup.FullName
    "WinPERobocopyExtraFilesPE" = [string[]]$SelectedWinPEExtraFilesPE.FullName;
    "WinPERobocopyExtraFilesRE" = [string[]]$SelectedWinPEExtraFilesRE.FullName;
    "WinPERobocopyExtraFilesSetup" = [string[]]$SelectedWinPEExtraFilesSetup.FullName;
    }
    #======================================================================================
    Write-Host "===========================================================================" -ForegroundColor Green
    Write-Host "OSBuild Task: $TaskName" -ForegroundColor Green
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