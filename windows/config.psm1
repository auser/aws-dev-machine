function Get-MergedConfig($rootPath) {
    $path = $rootPath
    $baseConfig = "base"
    $configFileName = "config.{0}.json"
    Write-Host "Retreiving profile: '${Script:selectedProfileName}'"
    $config = Get-JsonFile ("${path}\${configFileName}" -f $baseConfig)
    return $config
  }
