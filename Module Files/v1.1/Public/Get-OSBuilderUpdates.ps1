<#
.SYNOPSIS
Downloads Microsoft Updates used by OSBuilder to Content\Updates

.DESCRIPTION
Downloads Microsoft Updates used by OSBuilder to Content\Updates

.PARAMETER Catalog
Selects the Catalog JSON file containing the Updates

.PARAMETER Download
Executes the Download of files

.PARAMETER HideDetails
Hides all results

.PARAMETER IseGridView
Displays the Updates in a PowerShell GridView so Updates can be selected.

.PARAMETER RemoveSuperseded
Removes Downloaded Updated that have been Superseded

.PARAMETER ShowDownloaded
Lists Downloaded Updates

.PARAMETER UpdateCatalogs
Downloads updated Catalogs from GitHub

.EXAMPLE
Get-OSBuilderUpdates -Catalog Cumulative -Download
Downloads all Cumulative Updates for Windows 10 and Windows Server 2016

.EXAMPLE
Get-OSBuilderUpdates -Catalog Adobe -FilterOS 'Windows 10' -FilterOSArch 'x64' -FilterOSBuild '1803'
Lists all Adobe Security Updates for Windows 10 x64 1803

.EXAMPLE
Get-OSBuilderUpdates -Catalog Adobe -Download -FilterOS 'Windows 10' -FilterOSArch 'x64' -FilterOSBuild '1803'
Downloads all Adobe Security Updates for Windows 10 x64 1803
#>

function Get-OSBuilderUpdates {
    [CmdletBinding()]
    Param (
        [ValidateSet('Adobe','Component','Cumulative','FeatureOnDemand','LanguagePack','LanguageInterfacePack','LanguageFeature','Servicing','Setup')]
        [string]$Catalog,
        [switch]$Download,
        [string]$FilterCategory,
        [string]$FilterKBNumber,
        [string]$FilterKBTitle,
        [ValidateSet('ar-SA','bg-BG','zh-CN','zh-TW','hr-HR','cs-CZ','da-DK','nl-NL','en-US','en-GB','et-EE','fi-FI','fr-CA','fr-FR','de-DE','el-GR','he-IL','hu-HU','it-IT','ja-JP','ko-KR','lv-LV','lt-LT','nb-NO','pl-PL','pt-BR','pt-PT','ro-RO','ru-RU','sr-Latn-RS','sk-SK','sl-SI','es-MX','es-ES','sv-SE','th-TH','tr-TR','uk-UA')]
        [string]$FilterLP,
        [ValidateSet('af-ZA','am-ET','as-IN','az-Latn-AZ','be-BY','bn-BD','bn-IN','bs-Latn-BA','ca-ES','ca-ES-valencia','chr-CHER-US','cy-GB','eu-ES','fa-IR','fil-PH','ga-IE','gd-GB','gl-ES','gu-IN','ha-Latn-NG','hi-IN','hy-AM','id-ID','ig-NG','is-IS','ka-GE','kk-KZ','km-KH','kn-IN','kok-IN','ku-ARAB-IQ','ky-KG','lb-LU','lo-LA','mi-NZ','mk-MK','ml-IN','mn-MN','mr-IN','ms-MY','mt-MT','ne-NP','nn-NO','nso-ZA','or-IN','pa-Arab-PK','pa-IN','prs-AF','quc-Latn-GT','quz-PE','rw-RW','sd-Arab-PK','si-LK','sq-AL','sr-Cyrl-BA','sr-Cyrl-RS','sw-KE','ta-IN','te-IN','tg-Cyrl-TJ','ti-ET','tk-TM','tn-ZA','tt-RU','ug-CN','ur-PK','uz-Latn-UZ','vi-VN','wo-SN','xh-ZA','yo-NG','zu-ZA')]
        [string]$FilterLIP,
        [ValidateSet('Windows 10','Windows Server 2016','Windows Server 2019')]
        [string]$FilterOS,
        [ValidateSet('x64','x86')]
        [string]$FilterOSArch,
        [ValidateSet('1507','1511','1607','1703','1709','1803','1809')]
        [string]$FilterOSBuild,
        [switch]$HideDetails,
        #[switch]$HideOptionalUpdates,
        [switch]$IseGridView,
        [switch]$RemoveSuperseded,
        [switch]$ShowDownloaded,
        [switch]$UpdateCatalogs
    )
    #======================================================================================
    #	Reset Variables 18.10.20
    #======================================================================================



    #======================================================================================
    #	Initialize OSBuilder 18.9.13
    #======================================================================================
    Get-OSBuilder -CreatePaths -HideDetails
    #======================================================================================
    #	Get Catalogs 18.9.23
    #======================================================================================
    if (!(Test-Path "$CatalogLocal")) {$UpdateCatalogs = $true}
    if (Test-Path "$OSBuilderContent\Updates\Catalog.json") {
        Remove-Item "$OSBuilderContent\Updates\Catalog.json" -Force | Out-Null
        $UpdateCatalogs = $true
    }
    if (Test-Path "$OSBuilderContent\Updates\Catalog.xml") {
        Remove-Item "$OSBuilderContent\Updates\Catalog.xml" -Force | Out-Null
        $UpdateCatalogs = $true
    }
    #======================================================================================
    #	Update Catalogs 18.9.28
    #======================================================================================
    if ($UpdateCatalogs.IsPresent) {
        Write-Warning "Downloading $OSBuilderCatalogURL"
        $statuscode = try {(Invoke-WebRequest -Uri $OSBuilderCatalogURL -UseBasicParsing -DisableKeepAlive).StatusCode}
        catch [Net.WebException]{[int]$_.Exception.Response.StatusCode}
        if (!($statuscode -eq "200")) {
            Write-Warning "Could not connect to $OSBuilderCatalogURL (Status Code: $statuscode) ..."
        } else {
            Invoke-WebRequest -Uri "$OSBuilderCatalogURL" -OutFile "$CatalogLocal"
            if (Test-Path "$CatalogLocal") {
                $CatalogJson = Get-Content -Path "$CatalogLocal" | ConvertFrom-Json
                foreach ($item in $($CatalogJson.Catalogs)) {
                    if (!(Test-Path "$OSBuilderContent\Updates\$($item.Catalog)")){
                        New-Item "$OSBuilderContent\Updates\$($item.Catalog)" -ItemType Directory -Force | Out-Null
                    }
                    $statuscode = try {(Invoke-WebRequest -Uri $OSBuilderCatalogURL -UseBasicParsing -DisableKeepAlive).StatusCode}
                    catch [Net.WebException]{[int]$_.Exception.Response.StatusCode}
                    if ($statuscode -eq "200") {
                        Invoke-WebRequest -Uri "$($item.Url)" -OutFile "$OSBuilderContent\Updates\$($item.Catalog)\$(Split-Path "$($item.Url)" -Leaf)"
                    }
                }
            }
        }
    }
    #======================================================================================
    #	Catalog Test 18.9.23
    #======================================================================================
    if (!(Test-Path "$CatalogLocal")) {
        Write-Warning "$CatalogLocal could not be downloaded ... Exiting"
        Return
    }
    #======================================================================================
    #	Get Update Catalogs 18.9.22
    #======================================================================================
    if ($Catalog) {
        $CatalogsXmls = Get-ChildItem "$OSBuilderContent\Updates\$Catalog" Cat*.xml
        $ExistingUpdates = @(Get-ChildItem -Path "$OSBuilderContent\Updates\$Catalog\*" -Directory)
    } else {
        $CatalogsXmls = Get-ChildItem "$OSBuilderContent\Updates" Cat*.xml -Recurse
        $ExistingUpdates = @(Get-ChildItem -Path "$OSBuilderContent\Updates\*\*" -Directory)
    }
    
    #Exclude contents of the Custom directory
    $ExistingUpdates = $ExistingUpdates | Where-Object {$_.FullName -notlike "*\Custom\*"}

    foreach ($CatalogsXml in $CatalogsXmls) {
        $ImportCatalog = Import-Clixml -Path "$($CatalogsXml.FullName)"
        $CatalogDownloads += $ImportCatalog
    }

    $CatalogDownloads = $CatalogDownloads | Sort-Object KBTitle | Select-Object -Property Category, KBNumber, KBTitle, FileName, DatePosted, DateRevised, DateCreated, DateLastModified, URL
    #======================================================================================
    #	Get Downloaded and Superseded Updates 18.9.13
    #======================================================================================
    $DownloadedUpdates = @()
    $SupersededUpdates = @()
    foreach ($Update in $ExistingUpdates) {
        if ($CatalogDownloads.KBTitle -NotContains $Update.Name) {$SupersededUpdates += $Update.Name}
        else {$DownloadedUpdates += $Update.Name}
    }
    #======================================================================================
    #	Show Downloaded Updates 18.9.13
    #======================================================================================
    if ($ShowDownloaded.IsPresent) {
        if ($DownloadedUpdates) {
            Write-Host "Downloaded Updates" -ForegroundColor Yellow
            $DownloadedUpdates
            Write-Host ""
        }
    }
    #======================================================================================
    #	Show Superseded Updates 18.9.13
    #======================================================================================
    if (!($HideDetails.IsPresent)) {
        if ($SupersededUpdates) {
            Write-Host "Superseded Updates can be removed with -RemoveSuperseded" -ForegroundColor Yellow
            $SupersededUpdates
            Write-Host ""
        }
    }
    #======================================================================================
    #	Remove Superseded Updates 18.9.13
    #======================================================================================
    if ($RemoveSuperseded.IsPresent){
        foreach ($Update in $SupersededUpdates) {
            $RemoveUpdate = Get-ChildItem -Path "$OSBuilderContent\Updates\*\*" -Directory | Where-Object {$_.Name -eq $Update}
            Write-Warning "Removing $RemoveUpdate"
            Remove-Item -Path $RemoveUpdate -Recurse -Force
        }
        Write-Host ""
    }
    #======================================================================================
    #	Show Available Updates 18.9.13
    #======================================================================================
<# 	$AvailableUpdates = @()
    foreach ($Update in $CatalogDownloads) {
        if ($ExistingUpdates.Name -NotContains $Update.KBTitle) {
            $AvailableUpdates += $Update.KBTitle
        }
    }
    if ($AvailableUpdates) {
        Write-Host "Available Updates that have not been downloaded" -ForegroundColor Yellow
        $AvailableUpdates
        Write-Host ""
    } #>
    #======================================================================================
    #	Filters 18.9.22
    #======================================================================================
    #if (!($Catalog.IsPresent)) {$HideOptionalUpdates = $true}
    #if ($HideOptionalUpdates) {$CatalogDownloads = $CatalogDownloads | Where-Object {$_.Category -notlike "Language*"}}
    #if ($HideOptionalUpdates) {$CatalogDownloads = $CatalogDownloads | Where-Object {$_.Category -notlike "FeatureOnDemand"}}
    if (!($Catalog -or $FilterKBTitle)) {
        $CatalogDownloads = $CatalogDownloads | Where-Object {$_.Category -notlike "Language*"}
        $CatalogDownloads = $CatalogDownloads | Where-Object {$_.Category -notlike "FeatureOnDemand"}
        Write-Warning "Language Packs, Language Interface Packs and Features on Demand are not automatically displayed"
        Write-Warning "To view these updates, use the Catalog parameter"
        Write-Host ""
    }

    if ($FilterCategory) {$CatalogDownloads = $CatalogDownloads | Where-Object {$_.Category -like "*$FilterCategory*"}}
    if ($FilterKBNumber) {$CatalogDownloads = $CatalogDownloads | Where-Object {$_.KBNumber -like "*$FilterKBNumber*"}}
    if ($FilterKBNumber) {$CatalogDownloads = $CatalogDownloads | Where-Object {$_.KBNumber -like "*$FilterKBNumber*"}}
    if ($FilterKBTitle) {$CatalogDownloads = $CatalogDownloads | Where-Object {$_.KBTitle -like "*$FilterKBTitle*"}}
    if ($FilterLP) {$CatalogDownloads = $CatalogDownloads | Where-Object {$_.KBTitle -like "*$FilterLP*"}}
    if ($FilterLIP) {$CatalogDownloads = $CatalogDownloads | Where-Object {$_.KBTitle -like "*$FilterLIP*"}}
    if ($FilterOS) {$CatalogDownloads = $CatalogDownloads | Where-Object {$_.KBTitle -like "*$FilterOS*"}}
    if ($FilterOSArch) {$CatalogDownloads = $CatalogDownloads | Where-Object {$_.KBTitle -like "*$FilterOSArch*"}}
    if ($FilterOSBuild) {$CatalogDownloads = $CatalogDownloads | Where-Object {$_.KBTitle -like "*$FilterOSBuild*"}}
    #======================================================================================
    #	Select Updates with PowerShell ISE 18.9.13
    #======================================================================================
    if ($IseGridView.IsPresent) {$CatalogDownloads = $CatalogDownloads | Out-GridView -PassThru -Title 'Select Updates to Download and press OK'}
    #======================================================================================
    #	Filtered Updates 18.9.13
    #======================================================================================
    $FilteredUpdates = @()
    foreach ($Update in $CatalogDownloads) {
        if ($ExistingUpdates.Name -NotContains $Update.KBTitle) {
            $FilteredUpdates += $Update.KBTitle
        }
    }
    if (!($HideDetails.IsPresent)) {
        if ($FilteredUpdates) {
            Write-Host "Available Filtered Updates can be downloaded with the -Download parameter" -ForegroundColor Yellow
            $FilteredUpdates
            Write-Host ""
        }
    }
    #======================================================================================
    #   Download Updates 18.9.13
    #======================================================================================
    if ($Download.IsPresent) {
        foreach ($Update in $CatalogDownloads) {
            $DownloadPath = "$OSBuilderContent\Updates\$($Update.Category)\$($Update.KBTitle)"
            $DownloadFullPath = "$DownloadPath\$($Update.FileName)"

            if (!(Test-Path $DownloadPath)) {New-Item -Path "$DownloadPath" -ItemType Directory -Force | Out-Null}
            if (!(Test-Path $DownloadFullPath)) {
                Write-Host "Downloading: $($Update.URL)" -ForegroundColor Yellow
                Start-BitsTransfer -Source $($Update.URL) -Destination $DownloadFullPath
            } else {
                #Write-Warning "Exists: $($Update.KBTitle)"
            }
        }
        Write-Host ""
    }
    if (!($HideDetails.IsPresent)) {
        #======================================================================================
        #   Remove Variables 18.10.20
        #======================================================================================
        Remove-Variable Catalog
        Remove-Variable CatalogDownloads
        Remove-Variable CatalogsXml
        Remove-Variable CatalogsXmls
        Remove-Variable Download
        Remove-Variable DownloadedUpdates
        Remove-Variable ExistingUpdates
        Remove-Variable FilterCategory
        Remove-Variable FilteredUpdates
        Remove-Variable FilterKBNumber
        Remove-Variable FilterKBTitle
        Remove-Variable FilterLIP
        Remove-Variable FilterLP
        Remove-Variable FilterOS
        Remove-Variable FilterOSArch
        Remove-Variable FilterOSBuild
        Remove-Variable ImportCatalog
        Remove-Variable IseGridView
        Remove-Variable RemoveSuperseded
        Remove-Variable ShowDownloaded
        Remove-Variable SupersededUpdates
        Remove-Variable Update
        Remove-Variable UpdateCatalogs
        #Get-Variable | Select-Object -Property Name, Value | Format-Table
        #======================================================================================
        #   Complete 18.10.20
        #======================================================================================
        Write-Host "Complete!" -ForegroundColor Green
    }
}