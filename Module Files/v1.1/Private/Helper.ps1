function Get-OSMediaModule {
    if (Get-Module -ListAvailable -Name OSMedia) {
        Write-Warning "PowerShell Module OSMedia needs to be removed before using OSBuilder"
        Write-Warning "Use the following command:"
        Write-Warning "Uninstall-Module -Name OSMedia -AllVersions -Force"
    }
}

function Get-OSBuilderVersion {
    param (
        [Parameter(Position=1)]
        [switch]$HideDetails
    )
    $global:OSBuilderVersion = $(Get-Module -Name OSBuilder).Version
    if ($HideDetails -eq $false) {
        Write-Host "OSBuilder $OSBuilderVersion" -ForegroundColor Cyan
        Write-Host ""
    }
}
