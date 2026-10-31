[datetime]$dtToday = [datetime]::NOW
$strCurrentMonth = $dtToday.Month.ToString()
$strCurrentYear = $dtToday.Year.ToString()
[datetime]$dtMonth = $strCurrentMonth + '/1/' + $strCurrentYear

while ($dtMonth.DayofWeek -ne 'Tuesday') { 
      $dtMonth = $dtMonth.AddDays(1) 
}

$strPatchTuesday = $dtMonth.AddDays(7)
$intOffSet = 7

if ([datetime]::NOW -lt $strPatchTuesday -or [datetime]::NOW -ge $strPatchTuesday.AddDays($intOffSet)) {
    $objUpdateSession = New-Object -ComObject Microsoft.Update.Session
    $objUpdateSearcher = $objUpdateSession.CreateupdateSearcher()
    $arrAvailableUpdates = @($objUpdateSearcher.Search("IsAssigned=1 and IsHidden=0 and IsInstalled=0").Updates)
    $strAvailableCumulativeUpdates = $arrAvailableUpdates | Where-Object {$_.title -like "*cumulative*"}

    if ($strAvailableCumulativeUpdates -eq $null) {
        $strUpdateStatus = @{"WindowsVersionState" = "Up-to-date"}
    } 
    else {
        $strUpdateStatus = @{"WindowsVersionState" = "Not up-to-date"}
    }
} 
else {
    $strUpdateStatus = @{"Update status" = "Up-to-date"}
}

return $strUpdateStatus | ConvertTo-Json -Compress
