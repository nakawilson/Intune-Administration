$ErrorActionPreference = 'SilentlyContinue'

# Define the URLs and file paths
$destinationPath = "$env:windir\ccm\logs\Wu_logs.log"

#Collect PnP Log
$logPath = "C:\Windows\Temp"
$clientMachineName = $env:computername
$pnpcommand = "pnputil.exe"
$pnpArgs = "/export-pnpstate C:\Windows\CCM\Logs\PNP_$clientMachineName.log"
$process = Start-Process -FilePath $pnpCommand -ArgumentList $pnpArgs -WindowStyle Hidden -Wait 
Start-Sleep -Seconds 5

#Collect WU Logs 
$logFile = $logPath + "\$clientMachineName" + "_CollectWULogs_{0}.log" -f (Get-Date -Format "yyyyMMddhhmmss")

Function WriteLog
{
    Param ([string]$logstring)
    
    Add-content $Logfile -value $logstring
    Write-Verbose $logstring
}


try {
    # Download logcollector.exe from aka.ms/wucopylogsexternal
    WriteLog "Calling aka.ms/wucopylogsexternal"
    $logCollectorUrl = "https://aka.ms/wucopylogsexternal"
    $logCollectorPage = Invoke-WebRequest -Uri $logCollectorUrl -UseBasicParsing
    WriteLog "Webpage links"
    $logCollectorPage.Links | ForEach-Object {WriteLog $_.href}
    $logCollectorLink = $logCollectorPage.Links | Where-Object { $_.href -like "*logcollector.exe*" }
    $logCollectorDownloadUrl = $logCollectorLink.href
    writelog "Downloading logcollector.exe from $logCollectorDownloadUrl"
    Invoke-WebRequest -Uri $logCollectorDownloadUrl -OutFile "$logPath\logcollector.exe" -usebasicparsing

    if (-not (Test-Path "$logPath\logcollector.exe"))
    {
        WriteLog "Failed to download logcollector.exe"
        Throw "Failed to download logcollector.exe"
    }
    # Run logcollector.exe
    $logCollectorOutput = Start-Process -FilePath "$logPath\logcollector.exe" -NoNewWindow -PassThru
    if (-not $logCollectorOutput)
    {
        WriteLog "Failed to run logcollector.exe"
        Writelog $logCollectorOutput
        Throw "Failed to run logcollector.exe"
    }
    else {
        WriteLog "Logcollector.exe started correctly"
    }

    #cannot redirect output to external as pid still has lock on file
    #calling system.diag.process has some risks and not needed for now
    writelog "Starting sleep"
    Start-Sleep -Seconds 300
    writelog "Done with sleep"

    #kill the process as logcollector.exe will not exit on its own
    writelog "Stopping log collector"
    Stop-Process -Name logcollector -Force

    #find latest WindowsUpdateLogs.zip file in %windir%\systemtemp
    $files = Get-ChildItem -Path $env:windir\SystemTemp -Filter WindowsUpdateLogs*.zip -Recurse 
    foreach ($file in $files) {
        if ($file.LastWriteTime -gt (Get-Date).AddMinutes(-7)) {
            $zipFilePath = $file.FullName
            break
        }
    }   
    if (-not $zipFilePath)
    {
        WriteLog "Failed to find WindowsUpdateLogs.zip file in %windir%\systemtemp"
        Throw "Failed to find WindowsUpdateLogs.zip file in %windir%\systemtemp"
    } 
    #move to ccm\logs folder
    Move-Item -Path $zipFilePath -Destination $destinationPath

    # Rename the file with .log extension
    Rename-Item -Path $destinationPath -NewName ($destinationPath -replace '\.zip$', '.log')

   #cleanup
    remove-item -Path "$logPath\logcollector.exe" -Force

}
catch {
    Write-Host "$_.Exception.Message"
}
