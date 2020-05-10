<#
.SYNOPSIS
Setup your windows machine on AWS
.DESCRIPTION
Downloads and installs packages required to get going on the di-guide
.OUTPUTS
.EXAMPLE
.\setup_windows.ps1
.LINK
.NOTES
Written by: Ari Lerner <alerner@amazon.com>
#>
param($currentProfileName = $null)

Push-Location $PSScriptRoot
$currentScriptPath = $PSCommandPath

Set-ExecutionPolicy Bypass -Scope CurrentUser

Import-Module ".\windows\utils" -Force
Import-Module ".\windows\config" -Force
Import-Module ".\windows\downloader" -Force
Import-Module ".\windows\prereqs" -Force
Import-Module ".\windows\chocolatey" -Force
Import-Module ".\windows\git" -Force
Import-Module ".\windows\python" -Force
Import-Module ".\windows\node-js" -Force
Import-Module ".\windows\aws" -Force

Import-Module "SSV-Core" -Force
Grant-PowershellAsAdmin $currentScriptPath ($currentStep, $currentProfileName)

$Script:selectedProfileName = $currentProfileName

function Main {
    Write-Host "----------------------------------------------------------" -ForegroundColor Cyan
    Write-Host " Machine Setup -  Started!" -ForegroundColor Cyan
    Write-Host "----------------------------------------------------------" -ForegroundColor Cyan

    $config = Get-MergedConfig(".\windows")

    Write-Host "Config: $config"

    # Install
    Set-PSGalleryAsTrusted $config.setPSGalleryAsTrusted

    if(!(Test-CommandExists("choco")))  {
        Install-Chocolatey $config.chocolatey
    }

    if(!(Test-CommandExists("git")))  {
        Install-Git $config.git
    }

    if (!(Test-CommandExists("pip"))) {
        Install-Python $config.python
        Install-PipPackages $config.python
    }

    if(!(Test-CommandExists("node"))) {
        Install-NodeJS $config.nodeJs
        Set-NodeJsGlobalSettings $config.nodeJs
        Install-NpmPackages $config.nodeJs
    }

    # if (!(Test-CommandExists("code"))) {
    #     Install-VSCode $config.vscode
    # }

    if(!(Test-CommandExists("aws"))) {
        InstallAWSToolsForWindowsPowerShell $config.aws
    }

    Write-Host "----------------------------------------------------------" -ForegroundColor Green
    Write-Host " Machine Setup -  Complete!" -ForegroundColor Green
    Write-Host "----------------------------------------------------------" -ForegroundColor Green
    Wait-OrPressAnyKey "Press any key to close script or it will be closed in {0} seconds"
    Pop-Location;
}

Main
