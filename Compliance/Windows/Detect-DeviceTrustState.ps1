$output = dsregcmd /status
$dsregcmd = New-Object psobject
$counter = 1
$tempProps = @{}

foreach ($line in $output)
{
    if($line.contains("| "))
    {
        $property = $line -replace "\W"
    }
    if($line.Contains(" : "))
    {
        $key = $line.Substring(0, $line.IndexOf(":")).Trim()
        $value = $line.Substring($line.IndexOf(":") + 1).Trim()
        $tempProps.Add($key, $value)
        $lastPropLineNo = $counter
    }
    if ($line -eq "")
    {
        $markerEmptyLine = $counter
    }
    if($line.Contains("+-") -and $counter-1 -eq $markerEmptyLine -and $counter-2 -eq $lastPropLineNo -or $line.Contains("For more"))
    {
        $dsregcmd | Add-Member -MemberType NoteProperty -Name $property -Value $tempProps
        $tempProps = @{}
    }
    $counter++
}


if($dsregcmd.DeviceState.DomainJoined -eq "NO" -and $dsregcmd.DeviceState.AzureAdJoined -eq "NO")
{
    $WPJState = "YES"
}
else
{
    $WPJState = "NO"
}

$properties = @{ 
    WPJ = $WPJState
    AADJ = $dsregcmd.DeviceState.AzureAdJoined; 
    DJ = $dsregcmd.DeviceState.DomainJoined;
    HAADJ = $dsregcmd.DeviceState.EnterpriseJoined
}

return $properties | ConvertTo-Json -Compress
