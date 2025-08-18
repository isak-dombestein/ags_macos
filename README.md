# ags_macos

This repository contains scripts to install the Adventure Game Studio (AGS) Editor on macOS. 

# minSetup.sh:
minSetup.sh is the simplest of the two scripts. Here's what it does:
- Check if Homebrew is installed (and installs it if not)
- Check if Wine is installed (and installs it if not)
- Install .NET 4.8 into the Wine directory
- Downloads the latest portable version of the AGS Editor from adventuregamestudio.co.uk ad installs it to /Applications/ags_macos

To install AGS using this script, copy and paste the following command into your terminal:
```bash
curl -L -o ~/Downloads/minSetup.sh https://raw.githubusercontent.com/isak-dombestein/ags_macos/refs/heads/main/minSetup.sh && bash ~/Downloads/minSetup.sh
```

# advSetup.sh:
advSetup.sh is the more complex of the two scripts. It performs the same actions as minSetup.sh PLUS the following actions:
- Check if Git is installed (and installs if it not)
- Installs build dependencies to build the AGS Engine
- Clones and builds the full AGS engine from the [Official AGS Repo](https://www.github.com/adventuregamestudio/ags)
- Installs the built engine into /Applications/ags_macos/native_engine/ags

To install AGS and build the engine, copy and paste the following command into your terminal:
```bash
curl -L -o ~/Downloads/minSetup.sh https://raw.githubusercontent.com/isak-dombestein/ags_macos/refs/heads/main/minSetup.sh && bash ~/Downloads/minSetup.sh
```

# DISCLAIMER:
Running AGS on macOS through Wine is not officially supported by Adventure Game Studio. You may encounter errors or instabilities.

It is recommended that you read through the script you intend to run before running it to ensure you understand what it does.

These scripts are provided as a convenience to automate the installation of third-party software. They are offered "AS IS", without any warranty. By choosing to run one of these scripts, you understand and agree that you are doing so at your own risk. The author shall not be held liable for any potential damage to your system. It is always recommended to back up important data before running scripts that install or modify system software. 

# Issues
If you encounter any issues with running AGS after installing, or encounter issues with the scripts themselves, please open a issue in this repo.