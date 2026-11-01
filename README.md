# Intune Administration — Sample Scripts

Sample PowerShell scripts for administering Microsoft Intune via Microsoft Graph.

## Folders

| Folder | What goes here |
| --- | --- |
| [`Compliance/`](Compliance/) | Scripts for device compliance — compliance policies, compliance state, non-compliant devices, remediation |
| [`Management/`](Management/) | Scripts pushed to managed devices by the MDM server to deploy a custom policy or configure the device |

Each folder has its own README describing the scripts in it, their required
Graph permissions, and the Intune RBAC role needed to run them.

## Notes

- Scripts use raw Microsoft Graph REST calls where possible, so the OAuth and
  RBAC behaviour is visible — see `nakawilson/demos` for the OAuth/RBAC demo
  this pattern is based on.
- No secrets, tenant IDs, or client IDs are committed here. Bring your own
  Entra app registration, and grant admin consent for the permissions each
  script lists.
- A Graph permission alone is not enough: the user or service principal also
  needs an Intune role assignment covering the devices or policies the script
  touches.
