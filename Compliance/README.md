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

## Status

No scripts yet — this folder is the starting point. Add a script here and
document it in the table below.

| Script | What it does | Permissions |
| --- | --- | --- |
| _(none yet)_ | | |
