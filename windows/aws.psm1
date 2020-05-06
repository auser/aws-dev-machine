# Push-Location $PSScriptRoot
$currentScriptPath = $PSCommandPath

function InstallAWSToolsForWindowsPowerShell () {
    $AWSPowerShellModuleSourceURL = "https://awscli.amazonaws.com/AWSCLIV2.msi"
    $DestinationFolder = "$ENV:homedrive\$env:homepath\Downloads"

    if (!(Test-Path $DestinationFolder)) {
        New-Item $DestinationFolder -ItemType Directory -Force
    }

    Write-Host "`nDownloading AWS PowerShell Module from $AWSPowerShellModuleSourceURL"

    try {
        # Invoke-WebRequest -Uri $AWSPowerShellModuleSourceURL -OutFile "$DestinationFolder\AWSToolsAndSDKForNet.msi"
        Install-FromMsi -Name 'AWSPowerShell' -Url $AWSPowerShellModuleSourceURL -Options $options;

        # $msiFile = "$DestinationFolder\AWSToolsAndSDKForNet.msi"

        # $arguments = @(
        #     "/i"
        #     "`"$msiFile`""
        #     "/qb"
        #     "/norestart"
        # )

        # Write-Host "Attempting to install $msiFile"

        # $process = Start-Process -FilePath msiexec.exe -ArgumentList $arguments -Wait -PassThru

        # if ($process.ExitCode -eq 0) {
        #     Write-Host "$msiFile has been successfull installed"
        # } else  {
        #     Write-Host "Installer script exit code $($process.ExitCode) for file $($msiFile)"
        # }
    }  catch {
        Write-Host $_.Exception.Message
    }
}
