function New-MediaISO {
    [CmdletBinding()]
    Param ()

    #======================================================================================
    #   18.10.21    Start
    #======================================================================================
    Write-Host "===========================================================================" -ForegroundColor Green
    Write-Host "New-MediaISO" -ForegroundColor Green
    Write-Host "===========================================================================" -ForegroundColor Green
    #======================================================================================
    #   18.10.21    Initialize OSBuilder
    #======================================================================================
    Get-OSBuilder -CreatePaths -HideDetails
    #======================================================================================
    #   18.10.21    Locate OSCDIMG
    #======================================================================================
    Write-Host "===========================================================================" -ForegroundColor Yellow
    Write-Host "Locating OSCDIMG" -ForegroundColor Yellow
    if (Test-Path "$OSBuilderContent\Tools\$env:PROCESSOR_ARCHITECTURE\Oscdimg\oscdimg.exe") {
        $oscdimg = "$OSBuilderContent\Tools\$env:PROCESSOR_ARCHITECTURE\Oscdimg\oscdimg.exe"
    } elseif (Test-Path "C:\Program Files\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\$env:PROCESSOR_ARCHITECTURE\Oscdimg\oscdimg.exe") {
        $oscdimg = "C:\Program Files\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\$env:PROCESSOR_ARCHITECTURE\Oscdimg\oscdimg.exe"
    } elseif (Test-Path "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\$env:PROCESSOR_ARCHITECTURE\Oscdimg\oscdimg.exe") {
        $oscdimg = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\$env:PROCESSOR_ARCHITECTURE\Oscdimg\oscdimg.exe"
    } else {
        Write-Warning "Could not locate OSCDIMG in Windows ADK at:"
        Write-Warning "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
        Write-Warning "You can optionally copy OSCDIMG to:"
        Write-Warning "$OSBuilderContent\Tools\$env:PROCESSOR_ARCHITECTURE\Oscdimg\oscdimg.exe"
        Return
    }
    Write-Host "$oscdimg"
    #======================================================================================
    #   18.10.21    Validate OSMedia OSBuilds PEBuilds has Content
    #======================================================================================
    $SelectedOSMedia = Get-ChildItem -Path ("$OSBuilderOSBuilds","$OSBuilderOSMedia","$OSBuilderPEBuilds") -Directory | Select-Object -Property Parent, Name, FullName, LastWriteTime, CreationTime | Sort-Object LastWriteTime -Descending
    if ($null -eq $SelectedOSMedia) {
        Write-Warning "OSMedia or OSBuilds  content not found.  Use Import-OSMedia to import an Operating System first . . . Exiting!"
        Break
    }
    #======================================================================================
    #   Validate OSMedia, OSBuilds PEBuilds has *.wim 18.10.17
    #======================================================================================
    $SelectedOSMedia = $SelectedOSMedia | Where-Object {Test-Path $(Join-Path $_.FullName (Join-Path "OS" (Join-Path "sources" "*.wim")))}
    #$SelectedOSMedia = $SelectedOSMedia | Where-Object {Test-Path $(Join-Path $_.FullName (Join-Path "OS" (Join-Path "sources" "install.wim")))}
    if ($null -eq $SelectedOSMedia) {
        Write-Warning "OSMedia or OSBuilds Install.wim not found.  Use Import-OSMedia to import an Operating System first . . . Exiting!"
        Break
    }
    #======================================================================================
    # Validate OSMedia was imported with Import-OSMedia
    #======================================================================================
    $SelectedOSMedia = $SelectedOSMedia | Where-Object {Test-Path $(Join-Path $_.FullName "WindowsImage.txt")}
    if ($null -eq $SelectedOSMedia) {
        Write-Warning "OSMedia or OSBuilds content invalid (missing WindowsImage.txt).  Use Import-OSMedia to import an Operating System first . . . Exiting!"
        Return
    }
    #======================================================================================
    # Select Source OSMedia
    #======================================================================================
    $SelectedOSMedia = $SelectedOSMedia | Out-GridView -Title "Select one or more OSMedia or OSBuilds to create an ISO's and press OK (Cancel to Exit)" -PassThru
    if($null -eq $SelectedOSMedia) {
        Write-Warning "Source OSMedia or OSBuild was not selected . . . Exiting!"
        Return
    }

    foreach ($Media in $SelectedOSMedia) {
        $ISOSourceFolder = "$($Media.FullName)\OS"
        $ISODestinationFolder = "$($Media.FullName)\ISO"
        if (!(Test-Path $ISODestinationFolder)) {New-Item $ISODestinationFolder -ItemType Directory -Force | Out-Null}
        $ISOFile = "$ISODestinationFolder\$($Media.Name).iso"
        $WindowsImage = Get-Content -Path "$($Media.FullName)\info\json\Get-WindowsImage.json"
        $WindowsImage = $WindowsImage | ConvertFrom-Json

        $OSImageDescription = $($WindowsImage.ImageName)
        $OSArchitecture = $($WindowsImage.Architecture)
        if ($OSArchitecture -eq 0) {$OSArchitecture = 'x86'}
        elseif ($OSArchitecture -eq 1) {$OSArchitecture = 'MIPS'}
        elseif ($OSArchitecture -eq 2) {$OSArchitecture = 'Alpha'}
        elseif ($OSArchitecture -eq 3) {$OSArchitecture = 'PowerPC'}
        elseif ($OSArchitecture -eq 6) {$OSArchitecture = 'ia64'}
        elseif ($OSArchitecture -eq 9) {$OSArchitecture = 'x64'}
        $UBR = $($WindowsImage.UBR)

        $OSImageName = $OSImageDescription
    
        $OSImageName = $OSImageName -replace "Microsoft Windows Recovery Environment", "WinPE"
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

        # 32 character limit for a Label
        # 23 = Win10 Edu x64 17134.112
        # 25 = Win10 Edu N x64 17134.112
        # 23 = Win10 Ent x64 17134.112
        # 25 = Win10 Ent N x64 17134.112
        # 23 = Win10 Pro x64 17134.112
        # 27 = Win10 Pro Edu x64 17134.112
        # 29 = Win10 Pro EduN x64 17134.112
        # 27 = Win10 Pro Wks x64 17134.112
        # 26 = Win10 Pro N x64 17134.112
        # 29 = Win10 Pro N Wks x64 17134.112
        $ISOLabel = '-l"{0}"' -f $OSImageName
        $ISOFolder = "$($Media.FullName)\ISO"
        if (!(Test-Path $ISOFolder)) {New-Item -Path $ISOFolder -ItemType Directory -Force | Out-Null}

        if (!(Test-Path $ISOSourceFolder)) {
            Write-Warning "Could not locate $ISOSourceFolder"
            Write-Warning "Make sure you have proper OS before using New-MediaISO"
            Return
        }
        $etfsboot = "$ISOSourceFolder\boot\etfsboot.com"
        if (!(Test-Path $etfsboot)) {
            Write-Warning "Could not locate $etfsboot"
            Write-Warning "Make sure you have proper OS before using New-MediaISO"
            Return
        }
        $efisys = "$ISOSourceFolder\efi\microsoft\boot\efisys.bin"
        if (!(Test-Path $efisys)) {
            Write-Warning "Could not locate $efisys"
            Write-Warning "Make sure you have proper OS before using New-MediaISO"
            Return
        }
        Write-Host "Label: $OSImageName" -ForegroundColor Yellow
        Write-Host "Creating: $ISOFile" -ForegroundColor Yellow
        $data = '2#p0,e,b"{0}"#pEF,e,b"{1}"' -f $etfsboot, $efisys
        start-process $oscdimg -args @("-m","-o","-u2","-bootdata:$data",'-u2','-udfver102',$ISOLabel,"`"$ISOSourceFolder`"", "`"$ISOFile`"") -Wait
    }
    #======================================================================================
    Write-Host "===========================================================================" -ForegroundColor Green
    Write-Host "Complete!" -ForegroundColor Green
    Write-Host "===========================================================================" -ForegroundColor Green
    #======================================================================================
}