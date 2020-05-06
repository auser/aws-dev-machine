$defaultPythonVersion =  "3.7.2"
$defaultPipVersion = "20.0.2"
$defaultInstallDir = "$env:ProgramFiles\python"

Function Install-Python {
    Param(
        [Parameter(Mandatory)]
        [object]$options
    )

    $version = $defaultPythonVersion
    $pipVersion = $defaultPipVersion
    $installationPath = $defaultInstallDir

    if (Get-Member -InputObject $options -Name "version") {
        $Version = $options | Select-Object -Property "version"
    }

    if (Get-Member -InputObject $options -Name "installDir") {
        $InstallDir = $options | Select-Object -Property "installDir"
    }

    $major, $minor, $patch = $version.split('.');

    if ($major -ne '2') {
        $pythonUrl = ('https://www.python.org/ftp/python/{0}/python-{0}-amd64.exe' -f $version);

        $options = @(
            '/quiet',
            'InstallAllUsers=1',
            'PrependPath=1',
            'AssociateFiles=0'
        );

        if ($installationPath) {
            $options += ('TargetDir="{0}"' -f $installationPath)
        }

        Install-FromExe -Name 'python' -Url $pythonUrl -Options $options;
    }
    else {
        $pythonUrl = ('https://www.python.org/ftp/python/{0}/python-{0}.amd64.msi' -f $version);

        $options = @(
            'ALLUSERS=1',
            'ADDLOCAL=DefaultFeature,Extensions,TclTk,Tools,PrependPath'
        );

        if ($installationPath) {
            $options += ('TARGETDIR="{0}"' -f $installationPath);
        }

        Install-FromMsi -Name 'python' -Url $pythonUrl -Options $options;
    }

    # Install PIP
    $pipInstall = ('pip=={0} --user' -f $pipVersion);
    Write-Host ('Installing {0} ...' -f $pipInstall);

    $tempFolder = $env:temp
    $getPipFile = ("{0}/get-pip.py" -f $tempFolder);
    Invoke-WebFileRequest -Url 'https://bootstrap.pypa.io/get-pip.py' -DestinationPath $getPipFile;
    python $getPipFile $pipInstall;
    Remove-Item $getPipFile -Force;

    if ($major -eq '2') {
        # Install Visual Studio for Python 2.7
        $vcForPythonUrl = 'https://download.microsoft.com/download/7/9/6/796EF2E4-801B-4FC4-AB28-B59FBF6D907B/VCForPython27.msi';

        Install-FromMsi -Name 'VCForPython27' -Url $vcForPythonUrl -NoVerify;
    }
}

function Install-PipPackages {
    param (
        [object]$options
    )

    Install-ConfigSection  $options "python" "packages"
}
