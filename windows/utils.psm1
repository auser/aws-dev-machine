# #region Utility Functions

function Set-PSGalleryAsTrusted([bool]$isInstallationRequired) {
  if ($isInstallationRequired) {
      Write-Warning "Powershell Gallery: is going to be set as 'trusted'"
      Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
  }
  else {
      Write-Warning "Powershell Gallery: Skipped"
  }
}

Function Install-FromMsi {
  Param(
      [Parameter(Mandatory)]
      [string] $name,
      [Parameter(Mandatory)]
      [string] $url,
      [Parameter()]
      [switch] $noVerify = $false,
      [Parameter()]
      [string[]] $options = @()
  )

  $installerPath = Join-Path ([System.IO.Path]::GetTempPath()) ('{0}.msi' -f $name);

  Write-Host ('Downloading {0} installer from {1} ..' -f $name, $url);
  Invoke-WebFileRequest -Url $url -DestinationPath $installerPath;
  Write-Host ('Downloaded {0} bytes' -f (Get-Item $installerPath).length);

  $args = @('/i', $installerPath, '/quiet', '/qn');
  $args += $options;

  Write-Host ('Installing {0} ...' -f $name);
  Write-Host ('msiexec {0}' -f ($args -Join ' '));

  Start-Process msiexec -Wait -ArgumentList $args;

  # Update path
  Update-ScriptPath;

  if (!$noVerify) {
      Write-Host ('Verifying {0} install ...' -f $name);
      $verifyCommand = ('  {0} --version' -f $name);
      Write-Host $verifyCommand;
      Invoke-Expression $verifyCommand;
  }

  Write-Host ('Removing {0} installer ...' -f $name);
  Remove-Item $installerPath -Force;
  Remove-TempFiles;

  Write-Host ('{0} install complete.' -f $name);
}

Function Install-FromExe {
  Param(
      [Parameter(Mandatory)]
      [string] $name,
      [Parameter(Mandatory)]
      [string] $url,
      [Parameter()]
      [switch] $noVerify = $false,
      [Parameter(Mandatory)]
      [string[]] $options = @()
  )

  $installerPath = Join-Path ([System.IO.Path]::GetTempPath()) ('{0}.exe' -f $name);

  Write-Host ('Downloading {0} installer from {1} ..' -f $name, $url);
  Invoke-WebFileRequest -Url $url -DestinationPath $installerPath;
  Write-Host ('Downloaded {0} bytes' -f (Get-Item $installerPath).length);

  Write-Host ('Installing {0} ...' -f $name);
  Write-Host ('{0} {1}' -f $installerPath, ($options -Join ' '));

  Start-Process $installerPath -Wait -ArgumentList $options;

  # Update path
  Update-ScriptPath;

  if (!$noVerify) {
      Write-Host ('Verifying {0} install ...' -f $name);
      $verifyCommand = ('  {0} --version' -f $name);
      Write-Host $verifyCommand;
      Invoke-Expression $verifyCommand;
  }

  Write-Host ('Removing {0} installer ...' -f $name);
  Remove-Item $installerPath -Force;
  Remove-TempFiles;

  Write-Host ('{0} install complete.' -f $name);
}

Function Invoke-WebFileRequest {
  Param(
      [Parameter(Mandatory)]
      [string] $url,
      [Parameter(Mandatory)]
      [string] $destinationPath
  )

  # See if security protocol needs to be checked
  $secure = 1;
  if ($url.StartsWith('http:')) {
      $secure = 0;
  }

  # Setup a proxy if needed
  $proxy = [System.Net.WebProxy]::GetDefaultProxy();
  $proxyServer = $proxy.Address;

  if ($proxy.Address -eq $null) {
      if ($secure) {
          if (Test-Path env:HTTPS_PROXY) {
              $proxy = New-Object System.Net.WebProxy($env:HTTPS_PROXY, $true);

              # Turn off SSL protocol check if proxy is HTTP
              if ($env:HTTPS_PROXY.StartsWith('http:')) {
                  $secure = 0;
              }
          }
      } else {
          if (Test-Path env:HTTP_PROXY) {
              $proxy = New-Object System.Net.WebProxy($env:HTTP_PROXY, $true);
          }
      }
  }

  if ($secure) {
      # Store off the security protocol
      $oldSecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol;

      # Determine the security protocol required
      $securityProtocol = 0;
      $testEndpoint = [System.Uri]$url;

      if ($proxy.Address -ne $null) {
          $testEndpoint = $proxy.Address;
      }

      foreach ($protocol in 'tls12', 'tls11', 'tls') {
          $tcpClient = New-Object Net.Sockets.TcpClient;
          $tcpClient.Connect($testEndpoint.Host, $testEndpoint.Port)

          $sslStream = New-Object Net.Security.SslStream $tcpClient.GetStream();
          $sslStream.ReadTimeout = 15000;
          $sslStream.WriteTimeout = 15000;

          try {
              $sslStream.AuthenticateAsClient($testEndpoint.Host, $null, $protocol, $false);
              $supports = $true;
          }
          catch {
              $supports = $false;
          }

          $sslStream.Dispose();
          $tcpClient.Dispose();

          if ($supports) {
              switch ($protocol) {
                  'tls12' { $securityProtocol = ($securityProtocol -bor [System.Net.SecurityProtocolType]::Tls12) }
                  'tls11' { $securityProtocol = ($securityProtocol -bor [System.Net.SecurityProtocolType]::Tls11) }
                  'tls' { $securityProtocol = ($securityProtocol -bor [System.Net.SecurityProtocolType]::Tls) }
              }
          }
      }

      [System.Net.ServicePointManager]::SecurityProtocol = $securityProtocol;
  }

  # Download the file
  $tcpClient = New-Object System.Net.WebClient;
  $tcpClient.Proxy = $proxy;
  $tcpClient.DownloadFile($url, $destinationPath);

  if ($oldSecurityProtocol) {
      # Restore the security protocol
      [System.Net.ServicePointManager]::SecurityProtocol = $oldSecurityProtocol;
  }
}

Function Update-ScriptPath {
  $env:PATH = [Environment]::GetEnvironmentVariable('PATH', [EnvironmentVariableTarget]::Machine);
}

Function Remove-TempFiles {
  $tempFolders = @($env:temp, 'C:/Windows/temp')

  Write-Host 'Removing temporary files';
  $filesRemoved = 0;

  foreach ($folder in $tempFolders) {
      $files = Get-ChildItem -Recurse -Force -ErrorAction SilentlyContinue $folder;

      foreach ($file in $files) {
          try {
              Remove-Item $file.FullName -Recurse -Force -ErrorAction Stop
              $filesRemoved++;
          }
          catch {
              Write-Host ('Could not remove file {0}' -f $file.FullName)
          }
      }
  }

  Write-Host ('Removed {0} files from temporary directories' -f $filesRemoved)
}

function Test-CommandExists {
  param (
    [string]$command
  )

  $oldPreference = $ErrorActionPreference
  $ErrorActionPreference =  'stop'
  try {
    if (Get-Command -Name  $command) {
      return $True;
    }
  } catch {
    Write-Host "$command does not exist";
    return $false;
  } finally {
    $ErrorActionPreference =  $oldPreference
  }
}
