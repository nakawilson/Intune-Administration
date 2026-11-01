# Management — Windows

Windows management scripts. Scripts for other operating systems live in
sibling folders (for example, `Management/macOS/`), not here.

## Scripts

| Script | What it does |
| --- | --- |
| [`Install-EdgeExtension.ps1`](Install-EdgeExtension.ps1) | Installs (or removes) a Microsoft Edge extension on a managed Windows device, via the Edge ExtensionInstallForcelist policy |
| [`Add-DefenderProcessExclusions.ps1`](Add-DefenderProcessExclusions.ps1) | Adds Windows 365 and Remote Desktop executables to Microsoft Defender process exclusions (applies to all users) |

### Install-EdgeExtension.ps1

Installs a Microsoft Edge extension on a managed Windows device, for
deployment as a management script pushed by the MDM server.

How it works: it writes the extension ID into the Edge
`ExtensionInstallForcelist` policy in the registry:

- Machine (all users, the default): `HKLM:\Software\Policies\Microsoft\Edge\ExtensionInstallForcelist`
- User (one user): `HKCU:\Software\Policies\Microsoft\Edge\ExtensionInstallForcelist`

It adds the ID as the next numbered value in that list, so existing
forced extensions are kept.

Parameters:

| Parameter | What it does |
| --- | --- |
| `-Extension <id>` | Extension ID to install |
| `-Hive 'Machine'` (default) or `'User'` | Whether to install for all users or one user |
| `-Remove <id>` | Extension ID to remove, instead of installing |
| `-Path <path to update.xml>` | Optional path to an `update.xml` file, for an extension hosted on a local server or shared folder rather than the Edge Add-ons store; the registry value becomes `<id>;<path>` |

Examples:

```powershell
.\Install-EdgeExtension.ps1 -Extension 'ohkeehjepccedbdpohnbapepongppfcj' -Hive 'Machine'
.\Install-EdgeExtension.ps1 -Remove 'ohkeehjepccedbdpohnbapepongppfcj' -Hive 'Machine'
```

Note: the script's help text refers to Chrome, but the registry location
it writes is Microsoft Edge's `ExtensionInstallForcelist` policy, so it
installs an Edge extension. The examples in the help text also call the
command `Chrome-ExtensionInstall`, but there is no function by that name
in the script — run the script directly with its parameters, as above.

It runs locally on the device — no Graph permissions are needed.

### Add-DefenderProcessExclusions.ps1

Adds executables to Microsoft Defender process exclusions, for deployment
as a management script pushed by the MDM server. Defender exclusions are
machine-wide, so they apply to all users on the device.

How it works: it reads the current process exclusions with
`Get-MpPreference`, then adds each of these with `Add-MpPreference
-ExclusionProcess` if it is not already excluded, and prints the final
exclusion list:

- `ShellAppRuntime.exe`
- `Windows365.exe`
- `MsTeamsVdi.exe`
- `msrdc.exe`
- `msrdcw.exe`

These are the Windows 365 and Remote Desktop (MSRDC) executables. If an
exclusion already exists it is skipped, and a failure to add one is
reported as a warning rather than stopping the script. To exclude
different processes, edit the `$processesToExclude` list at the top of
the script.

It must be run as Administrator. It runs locally on the device — no Graph
permissions are needed.
