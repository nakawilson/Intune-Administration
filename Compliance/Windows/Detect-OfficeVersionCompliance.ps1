# Intune Proactive Remediation Detection Script
# Purpose: Evaluate Microsoft 365 Apps (C2R) version compliance and ClickToRun service state.
# Outputs: Plain text & JSON summary via Write-Output only (no file logging) for Intune to capture.
# Exit Codes: 0 = Compliant, 1 = Not Compliant / Error

[CmdletBinding()]
param()

# ===== Configuration =====
$RequiredVersion = '16.0.19127.20154'  # Update with required minimum version (Current Channel example)
$ServiceName     = 'ClickToRunSvc'

# ===== Helper Functions =====
function Get-OfficeVersion {
    $paths = @(
        'HKLM:SOFTWARE\Microsoft\Office\ClickToRun\Configuration',            # 64-bit on 64-bit OS or 32-bit on 32-bit OS
        'HKLM:SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration' # 32-bit Office on 64-bit OS
    )
    foreach ($p in $paths) {
        if (Test-Path -LiteralPath $p) {
            try {
                $v = (Get-ItemProperty -Path $p -ErrorAction Stop).VersionToReport
                if ($v) { return $v }
            } catch { }
        }
    }
    return $null
}

function Get-C2RServiceStatus {
    try {
        $svc = Get-Service -Name $ServiceName -ErrorAction Stop
        return $svc.Status.ToString()
    } catch {
        return 'NotFound'
    }
}

# ===== Data Collection =====
$installedVersionString = Get-OfficeVersion
$serviceStatus          = Get-C2RServiceStatus

# ===== Version Parsing =====
$versionParsed = $true
try {
    $requiredVersionObj  = [Version]$RequiredVersion
    if ($installedVersionString) {
        $installedVersionObj = [Version]$installedVersionString
    } else {
        $installedVersionObj = $null
    }
} catch {
    $versionParsed = $false
}

# ===== Compliance Logic =====
$versionCompliant = $false
$versionState     = 'Unknown'
if ($versionParsed -and $installedVersionObj) {
    if ($installedVersionObj -ge $requiredVersionObj) {
        $versionCompliant = $true
        $versionState = 'MeetsOrExceeds'
    } else {
        $versionState = 'Outdated'
    }
} elseif (-not $installedVersionString) {
    $versionState = 'NotInstalledOrUnknown'
} else {
    $versionState = 'ParseError'
}

# Service compliance: require Running
$serviceCompliant = ($serviceStatus -eq 'Running')

# Overall compliance: both version & service
$overallCompliant = ($versionCompliant -and $serviceCompliant)

# ===== Structured Result =====
$result = [PSCustomObject]@{
    RequiredVersion       = $RequiredVersion
    InstalledVersion      = $installedVersionString
    VersionState          = $versionState
    VersionCompliant      = $versionCompliant
    C2RServiceStatus      = $serviceStatus
    C2RServiceCompliant   = $serviceCompliant
    OverallCompliant      = $overallCompliant
    CheckedAtUtc          = (Get-Date).ToUniversalTime().ToString('o')
}

# ===== Human Summary =====
$summaryParts = @()
$summaryParts += "OfficeVersion=$installedVersionString"
$summaryParts += "Required=$RequiredVersion"
$summaryParts += "VersionState=$versionState"
$summaryParts += "C2RService=$serviceStatus"
$summaryParts += "OverallCompliant=$overallCompliant"
$summaryLine = $summaryParts -join ' | '

Write-Output $summaryLine
Write-Output ($result | ConvertTo-Json -Depth 3 -Compress)

if ($overallCompliant) {
    exit 0
} else {
    exit 1
}
