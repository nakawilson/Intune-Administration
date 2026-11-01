# Management

Scripts for Intune device management — scripts pushed to managed devices
by the MDM server to deploy a custom policy or configure the device.

This is different from [`Compliance/`](../Compliance/): Compliance scripts
detect and report a device's state (for example, whether it is activated,
or whether a password is stale), while Management scripts change something
on the device.

## Scripts by operating system

Scripts are kept separate by operating system — do not mix them in one folder.

| Folder | What goes here |
| --- | --- |
| [`Windows/`](Windows/) | Windows management scripts |
| [`macOS/`](macOS/) | macOS management scripts |

### Windows

| Script | What it does | Runs where |
| --- | --- | --- |
| [`Windows/Install-EdgeExtension.ps1`](Windows/Install-EdgeExtension.ps1) | Installs (or removes) a Microsoft Edge extension on a managed Windows device, via the Edge ExtensionInstallForcelist policy | On the device, pushed by the MDM server |
| [`Windows/Add-DefenderProcessExclusions.ps1`](Windows/Add-DefenderProcessExclusions.ps1) | Adds Windows 365 and Remote Desktop executables to Microsoft Defender process exclusions (applies to all users) | On the device, pushed by the MDM server |

### macOS

| Script | What it does | Runs where |
| --- | --- | --- |
| [`macOS/Patch-VLCMediaPlayer.zsh`](macOS/Patch-VLCMediaPlayer.zsh) | Patches VLC Media Player on a macOS device to the latest release (or the admin-designated version) | On the device, pushed by the MDM server |
| [`macOS/Check-WindowsAppVersion.sh`](macOS/Check-WindowsAppVersion.sh) | Checks the installed version of the Windows App on a macOS device | On the device, pushed by the MDM server |

See [`Windows/README.md`](Windows/README.md) and
[`macOS/README.md`](macOS/README.md) for details on these scripts.
