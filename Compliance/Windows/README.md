# Compliance — Windows

Windows compliance scripts. Scripts for other operating systems live in
sibling folders (for example, `Compliance/macOS/`), not here.

## Scripts

| Script | What it does |
| --- | --- |
| [`Detect-7ZipInstalled.ps1`](Detect-7ZipInstalled.ps1) | Detects whether 7-Zip is installed on a managed Windows device and returns its version |
| [`Detect-WindowsCumulativeUpdate.ps1`](Detect-WindowsCumulativeUpdate.ps1) | Detects whether a Windows device has received the latest cumulative patch (within the last 30 days) |
| [`Detect-DeviceTrustState.ps1`](Detect-DeviceTrustState.ps1) | Detects a Windows device's trust / join state (workplace-joined, Azure AD-joined, domain-joined, hybrid-joined) |
| [`Detect-AdobeUpdatesViaRUM.ps1`](Detect-AdobeUpdatesViaRUM.ps1) | Detects installed Adobe software and whether Adobe Remote Update Manager (RUM) should be triggered to update it |
| [`Collect-PnPAndWindowsUpdateLogs.ps1`](Collect-PnPAndWindowsUpdateLogs.ps1) | Collects PnP device state and Windows Update logs from a managed Windows device |
| [`Detect-StaleLocalAccountPasswords.ps1`](Detect-StaleLocalAccountPasswords.ps1) | Detects local administrator accounts whose password is older than 50 days, so rotation can be triggered |
| [`Detect-WindowsActivation.ps1`](Detect-WindowsActivation.ps1) | Detects whether a Windows Enterprise device is activated (skips VMs and non-Enterprise editions) |
| [`Detect-OfficeVersionCompliance.ps1`](Detect-OfficeVersionCompliance.ps1) | Detects whether Microsoft 365 Apps (Office) meets the required minimum version and the ClickToRun service is running |

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

### Detect-AdobeUpdatesViaRUM.ps1

Detects installed Adobe software and whether Adobe Remote Update Manager
(RUM) should be triggered to update it, for use as an Intune detection
script (for example, in Proactive Remediation).

How it works: it lists Adobe products from the Windows registry
(64-bit and 32-bit uninstall keys), checks for RUM at
`C:\Program Files (x86)\Common Files\Adobe\OOBE_Enterprise\RemoteUpdateManager\RemoteUpdateManager.exe`,
and tracks its last run in `C:\temp\Logs\AdobeUpdate.log`.

- Exit `1` — an update should be triggered: RUM is present and the script
  has not run in the last 7 days (or has never run / its log is empty).
- Exit `0` — no action: RUM is not present, or the last update attempt
  was within the last 7 days.

It must be run with Administrator privilege. It writes to the Windows
event log `AdobeUpdate` (source `AdobeUpdate`, Event ID 60001) and to the
local log file above. The script includes the SAP codes of the Adobe
applications serviceable through RUM (Photoshop, Premiere Pro, Illustrator,
InDesign, Acrobat / After Effects, and others).

No Graph permissions are needed for the detection script itself — it runs
locally on the device.

### Collect-PnPAndWindowsUpdateLogs.ps1

Collects PnP device state and Windows Update logs from a managed Windows
device, for troubleshooting from Intune.

How it works: it exports the PnP state with `pnputil.exe` to
`C:\Windows\CCM\Logs\PNP_<computername>.log`, then downloads the Windows
Update log collector (`logcollector.exe`, via the public
`aka.ms/wucopylogsexternal` link), runs it, waits for it to collect the
logs, and moves the resulting `WindowsUpdateLogs` archive into
`C:\Windows\CCM\Logs\` as `Wu_logs.log`. A run log is written to
`C:\Windows\Temp\<computername>_CollectWULogs_<timestamp>.log`.

Notes: the log collector runs for up to 5 minutes while the script waits,
and the script cleans up the downloaded collector afterwards. It runs
locally on the device — no Graph permissions are needed.

### Detect-StaleLocalAccountPasswords.ps1

Detects local administrator accounts whose password is stale, for use as
an Intune detection script (for example, in Proactive Remediation) to
trigger password rotation.

How it works: it lists the members of the local Administrators group
(SID ending in 544), keeps the local users, and checks each one's
`PasswordLastSet` date.

- Exit `1` — rotation is needed: at least one local administrator's
  password is older than 50 days.
- Exit `0` — no rotation needed: all local administrators' passwords are
  50 days old or less, or a password has never been set; also exits `0` if
  the Administrators group cannot be retrieved.

Note: this is a detection script only — it does not change any password
itself. The actual rotation is a separate remediation step. It runs
locally on the device — no Graph permissions are needed, and it contains
no passwords or credentials.

### Detect-WindowsActivation.ps1

Detects whether a Windows device is activated, for use as an Intune
detection script (for example, in Proactive Remediation).

How it works: it first checks the computer model — virtual machines
(Hyper-V, VMware, VirtualBox, HVM domU) exit `0` with no action required.
On a physical device it checks the Windows edition; only Enterprise
editions are checked, and non-Enterprise editions exit `0`. For
Enterprise, it reads the license status via
`SoftwareLicensingProduct`:

- Exit `0` — activated (license status 1), in a grace period (status 2–6),
  a VM, a non-Enterprise edition, or an error retrieving the status.
- Exit `1` — not activated (license status 0), so remediation is required.

It runs locally on the device — no Graph permissions are needed. All
comments were removed from the published script at the user's request;
the logic is otherwise unchanged.

### Detect-OfficeVersionCompliance.ps1

Detects whether Microsoft 365 Apps (Office, Click-to-Run) is compliant,
for use as an Intune Proactive Remediation detection script.

How it works: it reads the installed Office version from the Click-to-Run
configuration registry key (`VersionToReport`, 64-bit and 32-bit paths)
and checks the `ClickToRunSvc` service status. It is compliant only when
both are true: the installed version meets or exceeds the required minimum
version, and the ClickToRun service is `Running`.

- Exit `0` — compliant.
- Exit `1` — not compliant, or an error (for example, Office not installed,
  or the version cannot be parsed).

The required minimum version is set in the script's configuration section
— currently `16.0.19127.20154` (a Current Channel example). Update
`$RequiredVersion` in the script when the required version changes. The
script outputs a plain-text summary line plus a JSON summary (required and
installed versions, version state, service status, overall compliance,
check time) via `Write-Output` only, with no file logging, so Intune can
capture it. It runs locally on the device — no Graph permissions are
needed.
