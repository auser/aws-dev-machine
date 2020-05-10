#Requires -Version 5

# remote install:
#   Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
$old_erroractionpreference = $erroractionpreference
$erroractionpreference = 'stop' # quit if anything goes wrong

if (($PSVersionTable.PSVersion.Major) -lt 5) {
    Write-Output "PowerShell 5 or later is required to run Scoop."
    Write-Output "Upgrade PowerShell: https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell"
    break
}

# show notification to change execution policy:
$allowedExecutionPolicy = @('Unrestricted', 'RemoteSigned', 'Bypass')
if ((Get-ExecutionPolicy).ToString() -notin $allowedExecutionPolicy) {
    Write-Output "PowerShell requires an execution policy in [$($allowedExecutionPolicy -join ", ")] to run."
    Write-Output "For example, to set the execution policy to 'RemoteSigned' please run :"
    Write-Output "'Set-ExecutionPolicy RemoteSigned -scope CurrentUser'"
    break
}

# get core functions
# $core_url = 'https://raw.githubusercontent.com/auser/aws-dev-machine/master/setup_windows.ps1'
# Write-Output 'Initializing...'
# Invoke-Expression (New-Object System.Net.WebClient).downloadString($core_url)

function Get-Downloader {
    param (
      [string]$url
     )

      $downloader = new-object System.Net.WebClient

      $defaultCreds = [System.Net.CredentialCache]::DefaultCredentials
      if ($defaultCreds -ne $null) {
        $downloader.Credentials = $defaultCreds
      }

      $ignoreProxy = $env:chocolateyIgnoreProxy
      if ($ignoreProxy -ne $null -and $ignoreProxy -eq 'true') {
        Write-Debug "Explicitly bypassing proxy due to user environment variable"
        $downloader.Proxy = [System.Net.GlobalProxySelection]::GetEmptyWebProxy()
      } else {
        # check if a proxy is required
        $explicitProxy = $env:chocolateyProxyLocation
        $explicitProxyUser = $env:chocolateyProxyUser
        $explicitProxyPassword = $env:chocolateyProxyPassword
        if ($explicitProxy -ne $null -and $explicitProxy -ne '') {
          # explicit proxy
          $proxy = New-Object System.Net.WebProxy($explicitProxy, $true)
          if ($explicitProxyPassword -ne $null -and $explicitProxyPassword -ne '') {
            $passwd = ConvertTo-SecureString $explicitProxyPassword -AsPlainText -Force
            $proxy.Credentials = New-Object System.Management.Automation.PSCredential ($explicitProxyUser, $passwd)
          }

          Write-Debug "Using explicit proxy server '$explicitProxy'."
          $downloader.Proxy = $proxy

        } elseif (!$downloader.Proxy.IsBypassed($url)) {
          # system proxy (pass through)
          $creds = $defaultCreds
          if ($creds -eq $null) {
            Write-Debug "Default credentials were null. Attempting backup method"
            $cred = get-credential
            $creds = $cred.GetNetworkCredential();
          }

          $proxyaddress = $downloader.Proxy.GetProxy($url).Authority
          Write-Debug "Using system proxy server '$proxyaddress'."
          $proxy = New-Object System.Net.WebProxy($proxyaddress)
          $proxy.Credentials = $creds
          $downloader.Proxy = $proxy
        }
      }

      return $downloader
    }

function Download-String {
    param (
        [string]$url
    )
    $downloader = Get-Downloader $url

    return $downloader.DownloadString($url)
}

function Download-File {
    param (
        [string]$url,
        [string]$file
    )
    #Write-Output "Downloading $url to $file"
    $downloader = Get-Downloader $url

    $downloader.DownloadFile($url, $file)
}

Write-Output "Getting latest version of the aws-dev-bootstrap."
$zipurl = 'https://github.com/auser/aws-dev-machine/archive/master.zip'

if ($env:TEMP -eq $null) {
    $env:TEMP = Join-Path $env:SystemDrive 'temp'
}
$devTempDir = Join-Path $env:TEMP "aws-dev-bootstrap"
$tempDir = Join-Path $devTempDir "bootstrapInstall"

# prep
if (![System.IO.Directory]::Exists($devTempDir)) {[void][System.IO.Directory]::CreateDirectory($devTempDir)}
if (![System.IO.Directory]::Exists($tempDir)) {[void][System.IO.Directory]::CreateDirectory($tempDir)}

Write-Output 'Downloading dev-machine...'
$zipfile = Join-Path $devTempDir "dev-machine.zip"
Download-File $zipurl $zipfile

Write-Output 'Extracting...'
Add-Type -Assembly "System.IO.Compression.FileSystem"
[IO.Compression.ZipFile]::ExtractToDirectory($zipfile, "$tempDir")
Copy-Item "$tempDir\*master\*" $devTempDir -Recurse -Force
Remove-Item "$tempDir", $zipfile -Recurse -Force

Write-Output 'Installing...'
& "$devTempDir\setup_windows.ps1"
