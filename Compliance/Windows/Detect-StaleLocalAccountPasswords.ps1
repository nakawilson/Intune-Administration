# Password rotation detection script

$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
$isClientOS = $osInfo.ProductType -eq 1

try {
    $admingroup = Get-LocalGroup | Where-Object { $_.SID -like "*-544*" }
    $admins = Get-LocalGroupMember -Group $admingroup -ErrorAction Stop | Where-Object { $_.PrincipalSource -eq "Local" }
} catch {
    Write-Output "Could not retrieve Administrators group. Assuming no rotation needed."
    exit 0
}

$rotationReasons = @()

foreach ($admin in $admins) {
    if ($admin.ObjectClass -ne 'User') { continue }

    $localUserName = $admin.Name
    if ($localUserName -like "*\*") {
        $localUserName = $localUserName.Split('\')[1]
    }

    $user = Get-LocalUser -Name $localUserName -ErrorAction SilentlyContinue
    if ($null -eq $user) { continue }

    $defaultadmin = $user.SID -like "*-500*"
    $isDisabled = -not $user.Enabled
    $passwordAgeDays = $null

    # Check if password has ever been set
    if ($null -ne $user.PasswordLastSet) {
        $passwordAgeDays = ((Get-Date) - $user.PasswordLastSet).Days
    }

    # Only rotate if password age is greater than 50 days
    if ($passwordAgeDays -gt 50) {
        $rotationReasons += "[$($user.Name)] - Password is older than 50 days ($passwordAgeDays)."
    }
}

if ($rotationReasons.Count -gt 0) {
    Write-Output "Password rotation is needed for reason(s):"
    $rotationReasons | ForEach-Object { Write-Output $_ }
    exit 1
} else {
    Write-Output "Password rotation is not needed. All accounts have password age less than or equal to 50 days, or password has never been set.(Age:$passwordAgeDays)"
    exit 0
}
