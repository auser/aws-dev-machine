# Dev Machine Bootstrapper

This bootstrapper is intended on making it easy to build a machine ready to build with light-weight, but relevant developer tooling.

The bootstrapper is a set of scripts intended on adding the following tools, if they are not already installed:

## Features

⌘ Supports Mac and Windows
📦️Idempotent
⚙️Automated
🏆️Fast
😃Open-source

## Tools

🧳Git
🧳Homebrew (mac only)
📄NodeJS
💎Ruby
🐍Python (and pip!)
ℑ AWS cli tools
🧑🏾‍💻git-remote-codecommit

## Getting it running

First, clone the repository or download the zip file and open it on your Desktop. These scripts are intended on being run inside a terminal window.

In order to use git at the command-line, open a terminal window. To open a terminal window on your machine, follow these instructions for your OS:

### Mac

The `Terminal.app` is located in your `/System/Applications/Utilities/Terminal.app`. You can open a `Finder` window and navigate to the `/Applications/Utilities/` window. From there, double click the `Terminal.app` icon and a terminal will open up.

![OSX Terminal](static/readme/finder.png)

### Windows

Press the `Windows` key and the `R` key at the same time: `Windows+R` then search for "cmd". A command-prompt will open up and you're ready to go.

![Windows Terminal](https://devblogs.microsoft.com/commandline/wp-content/uploads/sites/33/2019/05/terminal-screenshot.png)

> The terminal window for windows is a screenshot of their new terminal application called located at [https://github.com/Microsoft/Terminal](https://github.com/Microsoft/Terminal), but you can use the method above if you don't want to install the new terminal.

### Mac

In the terminal window, navigate to the directory where you downloaded the zip file or cloned the repository and run:

```BASH
./install_mac.sh
```

### Windows

In the PowerShell window, type the following command:

```bash
iex setup_windows.ps1
iex (new-object net.webclient).downloadstring('https://get.scoop.sh')
```
