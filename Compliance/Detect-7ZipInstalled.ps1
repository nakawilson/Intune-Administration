# 7-zip file paths
$exePaths = @(
    "C:\Program Files (x86)\7-Zip\7z.exe",
    "C:\Program Files\7-Zip\7z.exe"
)

# Initialize an empty variable for the version
$version = ""

# Loop through each path and check if the executable exists
foreach ($exePath in $exePaths) {
    if (Test-Path $exePath) {
        # Get the file version info
        $versionInfo = (Get-Item $exePath).VersionInfo
        $version = $versionInfo.FileVersion
        break
    }
}

# Return "No" if 7-zip is not installed
if (-not $version) {
    $version = "10000.00"
}

# Output the version as a JSON object
return @{ App7zipVersion = $version } | ConvertTo-Json -Compress