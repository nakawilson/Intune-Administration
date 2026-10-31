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

See [`Windows/README.md`](Windows/README.md) for details on that script.
