# Management — macOS

macOS management scripts. Scripts for other operating systems live in
sibling folders (for example, `Management/Windows/`), not here.

## Scripts

| Script | What it does |
| --- | --- |
| [`Patch-VLCMediaPlayer.zsh`](Patch-VLCMediaPlayer.zsh) | Patches VLC Media Player on a macOS device to the latest release (or the admin-designated version) |
| [`Check-WindowsAppVersion.sh`](Check-WindowsAppVersion.sh) | Checks the installed version of the Windows App on a macOS device |

### Patch-VLCMediaPlayer.zsh

Patches VLC Media Player on a macOS device, for deployment as a
management script pushed by the MDM server. It runs silently, in the
system context, for normal (non-Homebrew) installations.

How it works: it checks whether `VLC.app` exists under `/Applications`,
reads its installed version, then fetches the latest release version from
videolan.org. If the installed version is already at least that version,
it does nothing. Otherwise it:

1. Skips the device if VLC was installed through Homebrew (those are
   handled separately).
2. Detects the architecture (arm64 for Apple silicon, x64 for Intel,
   universal otherwise) and downloads the matching `.dmg` from
   videolan.org.
3. Removes the quarantine attribute, mounts the image, terminates any
   running VLC process (waiting up to 10 minutes first, unless forced),
   removes the old `/Applications/VLC.app`, and copies the new one in.
4. Unmounts the image, removes the quarantine attribute from the
   installed app, cleans up the installer, and verifies the installed
   version matches the expected version.

If the latest version cannot be fetched from videolan.org, it falls back
to the admin-designated version set in the script — currently `3.0.19`.
Update `designated_version` in the script when that changes.

Logs are written to
`/Library/Logs/Microsoft/ClientPatching/videolan-vlc_media_player.log`
(kept to the last 50 lines once it passes 300 lines).

It runs locally on the device — no Graph permissions are needed. All
comments were removed from the published script at the user's request;
the logic is otherwise unchanged. The `#!/bin/zsh` first line was kept,
as it is the interpreter directive, not a comment.

### Check-WindowsAppVersion.sh

Checks the installed version of the Windows App on a macOS device.

How it works: it looks for `/Applications/Windows App.app` and, if
present, reads its `CFBundleShortVersionString` from `Info.plist` with
`/usr/libexec/PlistBuddy`, and prints `Windows App version: <version>`.
If the app is not installed, it prints `Windows App is not installed.`

The app name is set in the script (`app_name="Windows App"`) — change
that line to check a different app, for example
`app_name="Microsoft Edge"`. It runs locally on the device — no Graph
permissions are needed.
