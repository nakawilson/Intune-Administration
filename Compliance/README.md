# Compliance

Scripts for Intune device compliance.

## Planned scripts

Add compliance scripts to this folder, for example:

- List device compliance policies
  (`GET /deviceManagement/deviceCompliancePolicies`)
- List managed devices by compliance state
  (`GET /deviceManagement/managedDevices` with `$filter=complianceState`)
- Report non-compliant devices, with owner, OS, and last sync
- Export compliance state to CSV

## Permissions

Typical Graph permissions for read-only compliance scripts:

- `DeviceManagementManagedDevices.Read.All`
- `DeviceManagementConfiguration.Read.All`

Plus an Intune role assignment that can read devices and compliance policies,
e.g. Read Only Operator to start.

## Scripts by operating system

Scripts are kept separate by operating system — do not mix them in one folder.

| Folder | What goes here |
| --- | --- |
| [`Windows/`](Windows/) | Windows compliance scripts |
| `macOS/` _(when needed)_ | macOS compliance scripts |

### Windows

| Script | What it does | Runs where |
| --- | --- | --- |
| [`Windows/Detect-7ZipInstalled.ps1`](Windows/Detect-7ZipInstalled.ps1) | Detects whether 7-Zip is installed on a managed Windows device and returns its version | On the device, as an Intune custom compliance detection script |
| [`Windows/Detect-WindowsCumulativeUpdate.ps1`](Windows/Detect-WindowsCumulativeUpdate.ps1) | Detects whether a Windows device has received the latest cumulative patch (within the last 30 days) | On the device, as an Intune custom compliance detection script |
| [`Windows/Detect-DeviceTrustState.ps1`](Windows/Detect-DeviceTrustState.ps1) | Detects a Windows device's trust / join state (workplace-joined, Azure AD-joined, domain-joined, hybrid-joined) | On the device, as an Intune custom compliance detection script |
| [`Windows/Detect-AdobeUpdatesViaRUM.ps1`](Windows/Detect-AdobeUpdatesViaRUM.ps1) | Detects installed Adobe software and whether Adobe Remote Update Manager (RUM) should be triggered to update it | On the device, as an Intune detection script (for example, in Proactive Remediation) |
| [`Windows/Collect-PnPAndWindowsUpdateLogs.ps1`](Windows/Collect-PnPAndWindowsUpdateLogs.ps1) | Collects PnP device state and Windows Update logs from a managed Windows device | On the device, for troubleshooting from Intune |
| [`Windows/Detect-StaleLocalAccountPasswords.ps1`](Windows/Detect-StaleLocalAccountPasswords.ps1) | Detects local administrator accounts whose password is older than 50 days, so rotation can be triggered | On the device, as an Intune detection script (for example, in Proactive Remediation) |
| [`Windows/Detect-WindowsActivation.ps1`](Windows/Detect-WindowsActivation.ps1) | Detects whether a Windows Enterprise device is activated (skips VMs and non-Enterprise editions) | On the device, as an Intune detection script (for example, in Proactive Remediation) |
| [`Windows/Detect-OfficeVersionCompliance.ps1`](Windows/Detect-OfficeVersionCompliance.ps1) | Detects whether Microsoft 365 Apps (Office) meets the required minimum version and the ClickToRun service is running | On the device, as an Intune detection script (for example, in Proactive Remediation) |

See [`Windows/README.md`](Windows/README.md) for details on these scripts.
