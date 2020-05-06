
function Install-VSCode([object]$options) {
    if (!$options -or $options.ignore -or !$options.install) {
        Write-Warning "NodeJS: installation skipped"
        return
    }

    Write-Host "VSCode: installing..."

    $url = "https://aka.ms/win32-x64-user-stable"
    Install-FromExe -Name 'code' -Url $url -Options $options
    Update-ScriptPath;
}
