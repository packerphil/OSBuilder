function New-MediaUSB {
    [CmdletBinding()]
    Param (
        [ValidateLength(1,11)]
        [string]$USBLabel
    )
    #======================================================================================
    #   18.10.21    Start
    #======================================================================================
    Write-Host "===========================================================================" -ForegroundColor Green
    Write-Host "New-MediaUSB" -ForegroundColor Green
    Write-Host "===========================================================================" -ForegroundColor Green
    #======================================================================================
    #   18.10.21    Validate Administrator Rights
    #======================================================================================
    if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
            [Security.Principal.WindowsBuiltInRole] "Administrator"))
    {
        Write-Host ""
        Write-Host "OSBuilder: This function needs to be run as Administrator" -ForegroundColor Yellow
        Write-Host ""
        Return
    }
    #======================================================================================
    #   18.10.21    Initialize OSBuilder
    #======================================================================================
    Get-OSBuilder -CreatePaths -HideDetails
    #======================================================================================
    #   18.10.21    Validate OSMedia OSBuilds PEBuilds has Content
    #======================================================================================
    $SelectedOSMedia = Get-ChildItem -Path ("$OSBuilderOSBuilds","$OSBuilderOSMedia","$OSBuilderPEBuilds") -Directory | Select-Object -Property Parent, Name, FullName, LastWriteTime, CreationTime | Sort-Object LastWriteTime -Descending
    if ($null -eq $SelectedOSMedia) {
        Write-Warning "OSBuilder: OSMedia or OSBuilds content not found.  Use Import-OSMedia to import an Operating System first . . . Exiting!"
        Break
    }
    #======================================================================================
    #   Validate OSMedia, OSBuilds PEBuilds has *.wim 18.10.17
    #======================================================================================
    $SelectedOSMedia = $SelectedOSMedia | Where-Object {Test-Path $(Join-Path $_.FullName (Join-Path "OS" (Join-Path "sources" "*.wim")))}
    if ($null -eq $SelectedOSMedia) {
        Write-Warning "OSBuilder: OSMedia or OSBuilds Install.wim not found.  Use Import-OSMedia to import an Operating System first . . . Exiting!"
        Break
    }
    #======================================================================================
    # Validate OSMedia was imported with Import-OSMedia
    #======================================================================================
    $SelectedOSMedia = $SelectedOSMedia | Where-Object {Test-Path $(Join-Path $_.FullName "WindowsImage.txt")}
    if ($null -eq $SelectedOSMedia) {
        Write-Warning "OSBuilder: OSMedia or OSBuilds content is invalid (missing WindowsImage.txt).  Use Import-OSMedia to import an Operating System first . . . Exiting!"
        Return
    }
    #======================================================================================
    # Select Source OSMedia
    #======================================================================================
    $SelectedOSMedia = $SelectedOSMedia | Out-GridView -Title "OSBuilder: Select an OSMedia or OSBuild to copy to the USB Drive and press OK (Cancel to Exit)" -OutputMode Single
    if($null -eq $SelectedOSMedia) {
        Write-Warning "OSBuilder: Source OSMedia or OSBuild was not selected . . . Exiting!"
        Return
    }
    #======================================================================================
    # Select USB Drive
    #======================================================================================
    $Results = Get-Disk | Where-Object {$_.Size/1GB -lt 33 -and $_.BusType -eq 'USB'} | Out-GridView -Title 'OSBuilder: Select a USB Drive to FORMAT' -OutputMode Single | Clear-Disk -RemoveData -RemoveOEM -Confirm:$false -PassThru | New-Partition -UseMaximumSize -IsActive -AssignDriveLetter | Format-Volume -FileSystem FAT32 -NewFileSystemLabel $USBLabel

    if ($null -eq $Results) {
        Write-Warning "OSBuilder: No USB Drive was Found or Selected"
        Return
    } else {
        #Make Bootable
        Set-Location -Path "$($SelectedOSMedia.FullName)\OS\boot"
        bootsect.exe /nt60 "$($Results.DriveLetter):"

        #Copy Files from ISO to USB
        Copy-Item -Path "$($SelectedOSMedia.FullName)\OS\*" -Destination "$($Results.DriveLetter):" -Recurse -Verbose
    }
    #======================================================================================
    Write-Host "===========================================================================" -ForegroundColor Green
    Write-Host "Complete!" -ForegroundColor Green
    Write-Host "===========================================================================" -ForegroundColor Green
    #======================================================================================
}