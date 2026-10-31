# Compliance — Windows

Windows compliance scripts. Scripts for other operating systems live in
sibling folders (for example, `Compliance/macOS/`), not here.

## Scripts

| Script | What it does |
| --- | --- |
| [`Detect-7ZipInstalled.ps1`](Detect-7ZipInstalled.ps1) | Detects whether 7-Zip is installed on a managed Windows device and returns its version |

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
