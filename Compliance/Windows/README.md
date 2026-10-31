# Compliance — Windows

Windows compliance scripts. Scripts for other operating systems live in
sibling folders (for example, `Compliance/macOS/`), not here.

## Scripts

| Script | What it does |
| --- | --- |
| [`Detect-7ZipInstalled.ps1`](Detect-7ZipInstalled.ps1) | Detects whether 7-Zip is installed on a managed Windows device and returns its version |
| [`Detect-WindowsCumulativeUpdate.ps1`](Detect-WindowsCumulativeUpdate.ps1) | Detects whether a Windows device has received the latest cumulative patch (within the last 30 days) |
| [`Detect-DeviceTrustState.ps1`](Detect-DeviceTrustState.ps1) | Detects a Windows device's trust / join state (workplace-joined, Azure AD-joined, domain-joined, hybrid-joined) |

### Detect-7ZipInstalled.ps1

Checks for `7z.exe` in both locations:

- `C:\Program Files\7-Zip\7z.exe`
- `C:\Program Files (x86)\7-Zip\7z.exe`

Returns the file version as JSON:

```json
{"App7zipVersion":"24.09"}
```

If 7-Zip is not found, it returns `{"App7zipVersion":"10000.00"}` — a
sentinel value, so a custom compliance rule can treat a missing install as
non-compliant (for example, a rule requiring `App7zipVersion` to be less
than a given version, or not equal to `10000.00`).

Use in Intune as a custom compliance policy (Windows): upload this script
as the discovery script, add a JSON rule for `App7zipVersion`, and assign
the policy to the target devices. No Graph permissions are needed for the
detection script itself — it runs locally on the device.

### Detect-WindowsCumulativeUpdate.ps1

Detects whether a Windows device has received the latest cumulative patch
within the last 30 days, for use as an Intune custom compliance discovery
script.

How it works: it calculates the current month's Patch Tuesday (the second
Tuesday), then uses the Windows Update Agent (`Microsoft.Update.Session`)
to search for assigned, non-hidden, not-installed updates whose title
contains "cumulative". If no such cumulative update is pending, it returns:

```json
{"WindowsVersionState":"Up-to-date"}
```

If a cumulative update is pending, it returns
`{"WindowsVersionState":"Not up-to-date"}`.

Note: during the Patch Tuesday grace week the script returns
`{"Update status":"Up-to-date"}` instead (a different JSON key) — keep
that in mind when writing the custom compliance rule for
`WindowsVersionState`.

Use in Intune as a custom compliance policy (Windows): upload this script
as the discovery script, add a JSON rule for `WindowsVersionState`, and
assign the policy to the target devices. No Graph permissions are needed
for the detection script itself — it runs locally on the device.

### Detect-DeviceTrustState.ps1

Detects a Windows device's trust / join state, for use as an Intune
custom compliance discovery script.

How it works: it runs `dsregcmd /status` on the device and parses its
`DeviceState` section, then returns the join state as JSON:

```json
{"WPJ":"NO","AADJ":"YES","DJ":"NO","HAADJ":"NO"}
```

| Property | Meaning |
| --- | --- |
| `WPJ` | Workplace-joined — `YES` when the device is neither domain-joined nor Azure AD-joined, otherwise `NO` |
| `AADJ` | Azure AD-joined (`DeviceState.AzureAdJoined`) |
| `DJ` | Domain-joined (`DeviceState.DomainJoined`) |
| `HAADJ` | Hybrid Azure AD-joined (`DeviceState.EnterpriseJoined`) |

Use in Intune as a custom compliance policy (Windows): upload this script
as the discovery script, add JSON rules for the properties you need
(for example, `AADJ` equals `YES`), and assign the policy to the target
devices. No Graph permissions are needed for the detection script itself
— it runs locally on the device.
