function Install-Git {
    param (
        [object]$options
    )

    if (!$options -or $options.ignore -or !$options.install) {
        Write-Warning "Git: 'options' not found or section is ignored'. Skipped"
        return
    }

    $major, $minor, $patch, $build = $options.version.split('.')

    if ($build -ne '1') {
        $exePath = ('Git-{0}.{1}.{2}.{3}-64-bit.exe' -f $major, $minor, $patch, $build);
    }
    else {
        $exePath = ('Git-{0}.{1}.{2}-64-bit.exe' -f $major, $minor, $patch);
    }

    # https://github.com/git-for-windows/git/releases/download/v2.26.1.windows.1/Git-2.26.1-64-bit.exe
    $url = ('https://github.com/git-for-windows/git/releases/download/v{0}.{1}.{2}.windows.{3}/{4}' -f $major, $minor, $patch, $build, $exePath);

    $options = @(
        '/VERYSILENT',
        '/SUPPRESSMSGBOXES'
        '/NORESTART',
        '/NOCANCEL',
        # '/SP-',
        '/COMPONENTS=Cmd'
    );

    if ($options.installationPath)  {
        $options += {'/DIR="{0}"' -f $options.installationPath};
    }

    Install-FromExe -Name 'git' -Url $url -Options $options;
}
