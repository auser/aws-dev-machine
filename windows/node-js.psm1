$nodePath = "$env:ProgramFiles\nodejs"
$nodeModulesPath = "$nodePath\node_modules"

$defaultNodeVersion = "13.12.0"
$defaultInstallDir = $nodePath

function Install-NodeJS([object]$options) {
    if (!$options -or $options.ignore -or !$options.install) {
        Write-Warning "NodeJS: installation skipped"
        return
    }

    Write-Host "NodeJS: installing..."

    $Version = $defaultNodeVersion
    $InstallDir = $defaultInstallDir

    if (Get-Member -InputObject $options -Name "version") {
        $Version = $options | Select-Object -Property "version"
    }

    if (Get-Member -InputObject $options -Name "installDir") {
        $InstallDir = $options | Select-Object -Property "installDir"
    }

    $nodeFile="node-v$Version-x64"
    $url="http://nodejs.org/dist/v$Version/$nodeFile.msi"

    $options = @(
        '/qn',
        '/passive',
        '/norestart'
    );

    Install-FromMsi -Name 'node' -Url $url -Options $options
    Update-ScriptPath;
}

function Install-NpmPackages {
    param (
        [object]$options
    )

    Install-ConfigSection  $options "NodeJs" "packages"
}

function Set-NodeJsGlobalSettings([object]$options) {
    if (!$options -or $options.ignore -or !$options.setGlobalSettings) {
        Write-Warning "NodeJs Global Settings: Skipped"
        return
    }
    Write-Host "----------------------------------------------------------" -ForegroundColor Cyan
    Write-Host " NodeJs: Setting global default configuration -  Started!" -ForegroundColor Cyan
    Write-Host "----------------------------------------------------------" -ForegroundColor Cyan

    Set-FolderStructure
    Set-EnvironmentVariables
    Set-NodeGlobalConfig

    Write-Host "----------------------------------------------------------" -ForegroundColor Green
    Write-Host " NodeJs: Setting global default configuration -  Complete!" -ForegroundColor Green
    Write-Host "----------------------------------------------------------" -ForegroundColor Green
}

function Set-FolderStructure() {
    $folderName = "$nodePath\npm-cache"
    New-Folder $folderName

    $folderName = "$nodePath\etc"
    New-Folder $folderName
}

function Set-EnvironmentVariables() {
    $regValueName = "NODE"
    $regValue = $nodePath
    Set-EnvironmentVar $regValueName $regValue

    #CLA: Check if this can be changed to 'NODE_MODULES_PATH'
    $regValueName = "NODE_PATH"
    $regValue = $nodeModulesPath
    Set-EnvironmentVar $regValueName $regValue
}

function Set-NodeGlobalConfig () {
    New-Item "$nodeModulesPath\npm\npmrc" -type file -force -value "prefix=$nodePath"
    New-Item "$nodePath\etc\npmrc" -type file -force -value "prefix=$nodePath `r`ncache=$nodePath\npm-cache"
}
