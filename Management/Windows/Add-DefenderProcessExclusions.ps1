$processesToExclude = @("ShellAppRuntime.exe", "Windows365.exe", "MsTeamsVdi.exe", "msrdc.exe", "msrdcw.exe")

$currentExclusions = (Get-MpPreference).ExclusionProcess

foreach ($proc in $processesToExclude) {
    if ($currentExclusions -notcontains $proc) {
        try {
            Add-MpPreference -ExclusionProcess $proc
            Write-Host "Added Defender exclusion for $proc"
        }
        catch {
            Write-Warning ("Failed to add exclusion for {0}. Error: {1}" -f $proc, $_.Exception.Message)
        }
    }
    else {
        Write-Host "Exclusion for $proc already exists. Skipping."
    }
}

Write-Host "`nFinal Defender Exclusion Processes:"
(Get-MpPreference).ExclusionProcess
