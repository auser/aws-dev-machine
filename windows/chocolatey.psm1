function SetupChocolatey () {
    $url = ''

    $chocolateyVersion = $env:chocolateyVersion
    if (![string]::IsNullOrEmpty($chocolateyVersion)) {
        Write-Message "Downloading specific version of Chocolately: $chocolateyVersion"
        $url = "https://chocolatey.org/api/v2/package/chocolatey/$chocolateyVersion"
    }
    $chocolateyDownloadUrl = $env:chocolateyDownloadUrl
    if (![string]::IsNullOrEmpty($chocolateyDownloadUrl)) {
        Write-Message "Downloading Chocolatey from: $chocolateyDownloadUrl" -WriteToLog $True -HostConsoleAvailable $hostScreenAvailable
        $url = "$chocolateyDownloadUrl"
    }
    if ($env:TEMP -eq $null) {
        $env:TEMP = Join-Path $env:SystemDrive 'temp'
    }
    $chocoTempDir = Join-Path $env:TEMP "chocolatey"
    $tempDir = Join-Path $chocoTempDir "chocInstall"
    if (![System.IO.Directory]::Exists($tempDir)) {
        [void](System.IO.Directory)::CreateDirectory($tempDir)
    }
    $file = Join-Path $tempDir "chocolatey.zip"

    # Attempt to set highest encryption
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    } catch {
        Write-Message 'Unable to set PowerShell to use TLS 1.2. This is required for contacting Chocolatey as of 03 FEB 2020. https://chocolatey.org/blog/remove-support-for-old-tls-versions. If you see underlying connection closed or trust errors, you may need to do one or more of the following: (1) upgrade to .NET Framework 4.5+ and PowerShell v3+, (2) Call [System.Net.ServicePointManager]::SecurityProtocol = 3072; in PowerShell prior to attempting installation, (3) specify internal Chocolatey package location (set $env:chocolateyDownloadUrl prior to install or host the package internally), (4) use the Download + PowerShell method of install. See https://chocolatey.org/docs/installation for all install options.' -WriteToLog $False -HostConsoleAvailable $hostScreenAvailable
    }

    # Download chocolatey
    if ($url -eq $null -or $url -eq '') {
        Write-Message "Getting latest version of Chocolately package for download" -WriteToLog $True -HostConsoleAvailable $hostScreenAvailable
        $url = 'https://chocolatey.org/api/v2/Packages()?$filter=((Id%20eq%20%27chocolatey%27)%20and%20(not%20IsPrerelease))%20and%20IsLatestVersion'
        [xml]$result = Download-String $url
        $url = $result.feed.entry.content.src
    }

    # Download chocolatey
    Write-Message "Getting chocolatey from $url."
    Download-File $url,$file

    # Determine unzipping method
    # 7zip is the most compatible so use it by default
    $7zaExe = Join-Path $tempDir '7za.exe'
    $unzipMethod = '7zip'
    $useWindowsCompression = $env:chocolateyUseWindowsCompression

    if ($useWindowsCompression -ne $null -and $useWindowsCompression -eq 'true') {
        Write-Message 'Using built-in compression to unzip' -WriteToLog $True
        $unzipMethod = 'builtin'
    } elseif (-Not (Test-Path ($7zaExe))) {
        Write-Message "Downloading 7-Zip commandline tool prior to extraction." -WriteToLog $True
        # download 7zip
        Download-File 'https://chocolatey.org/7za.exe' "$7zaExe"
    }

    Write-Message "Extracting $file to $tempDir..."
    # unzip the package
    if ($unzipMethod -eq '7zip') {
    $params = "x -o`"$tempDir`" -bd -y `"$file`""
    # use more robust Process as compared to Start-Process -Wait (which doesn't
    # wait for the process to finish in PowerShell v3)
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = New-Object System.Diagnostics.ProcessStartInfo($7zaExe, $params)
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    $process.Start() | Out-Null
    $process.BeginOutputReadLine()
    $process.WaitForExit()
    $exitCode = $process.ExitCode
    $process.Dispose()

    $errorMessage = "Unable to unzip package using 7zip. Perhaps try setting `$env:chocolateyUseWindowsCompression = 'true' and call install again. Error:"
    switch ($exitCode) {
        0 { break }
        1 { throw "$errorMessage Some files could not be extracted" }
        2 { throw "$errorMessage 7-Zip encountered a fatal error while extracting the files" }
        7 { throw "$errorMessage 7-Zip command line error" }
        8 { throw "$errorMessage 7-Zip out of memory" }
        255 { throw "$errorMessage Extraction cancelled by the user" }
        default { throw "$errorMessage 7-Zip signalled an unknown error (code $exitCode)" }
    }
    } else {
        if ($PSVersionTable.PSVersion.Major -lt 5) {
            try {
            $shellApplication = new-object -com shell.application
            $zipPackage = $shellApplication.NameSpace($file)
            $destinationFolder = $shellApplication.NameSpace($tempDir)
            $destinationFolder.CopyHere($zipPackage.Items(),0x10)
            } catch {
            throw "Unable to unzip package using built-in compression. Set `$env:chocolateyUseWindowsCompression = 'false' and call install again to use 7zip to unzip. Error: `n $_"
            }
        } else {
            Expand-Archive -Path "$file" -DestinationPath "$tempDir" -Force
        }
    }

    Write-Message "Installing chocolatey on this machine"
    $toolsFolder = Join-Path $tempDir "tools"
    $chocoInstallPS1 = Join-Path $toolsFolder "chocolateyInstall.ps1"

    & $chocoInstallPS1

    Write-Message "Ensuring chocolatey commands are on the path"
    $chcoInstallVariableName = "ChoocoolateyInstall"
    $chocoPath = [Environment]::GetEnvironmentVariable($chcoInstallVariableName)
    if ($chocoPath -eq $null -or $chocoPath -eq '') {
        $chocoPath = "$env:ALLUSERSPROFILE\Chocolatey"
    }

    if (!(Test-Path($chocoPath))) {
        $chocoPath = "$env:SYSTEMDRIVE\ProgramData\Chocolatey"
    }

    $chocoExePath = Join-Path $chocoPath 'bin'

    if ($($env:Path).ToLower().Contains($($chocoExePath).ToLower()) -eq $false) {
        $env:Path = [Environment]::GetEnvironmentVariable('Path',[System.EnvironmentVariableTarget]::Machine);
    }

    Write-Message 'Ensuring chocolatey.nupkg is in the lib folder'
    $chocoPkgDir = Join-Path $chocoPath 'lib\chocolatey'
    $nupkg = Join-Path $chocoPkgDir 'chocolatey.nupkg'
    if (![System.IO.Directory]::Exists($chocoPkgDir)) { [System.IO.Directory]::CreateDirectory($chocoPkgDir); }
    Copy-Item "$file" "$nupkg" -Force -ErrorAction SilentlyContinue
}

function Install-Chocolatey {
    param (
        [object]$options
    )

    if (!$options -or $options.ignore -or !$options.install) {
        Write-Warning "Chocolatey: 'options' not found or section is ignored'. Skipped"
        return
    }

    Write-Host "Chocolatey: installing..."
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

function Install-ChocolateyPackages([object]$options) {
    Install-ConfigSection $options "Chocolatey" "packages"
}
