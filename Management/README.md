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
| `macOS/` _(when needed)_ | macOS management scripts |

### Windows

| Script | What it does | Runs where |
| --- | --- | --- |
| [`Windows/Install-EdgeExtension.ps1`](Windows/Install-EdgeExtension.ps1) | Installs (or removes) a Microsoft Edge extension on a managed Windows device, via the Edge ExtensionInstallForcelist policy | On the device, pushed by the MDM server |

See [`Windows/README.md`](Windows/README.md) for details on these scripts.
