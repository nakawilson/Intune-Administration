function getActivationStatus {

$ComputerInfo = Get-ComputerInfo -Property "WindowsEditionId", "WindowsCurrentVersion", "OsVersion"
$WinProduct = $ComputerInfo.WindowsEditionId
if ($WinProduct -match "Enterprise") {
    $ActivationStatus = Get-CimInstance SoftwareLicensingProduct -Filter "Name like 'Windows%'" | Where-Object { $_.PartialProductKey } | Select-Object LicenseStatus 
    if ($ActivationStatus.LicenseStatus -eq 1) {
      Write-Host $WinProduct "is currently activated, activation status: " $ActivationStatus " Windows Os Version: " $ComputerInfo
      Exit 0
    }
    elseIf ($ActivationStatus.LicenseStatus -eq 0 ) {
      Write-Host "Windows is not activated, remediation is required. Activation status:" $ActivationStatus " Windows Os Version: " $ComputerInfo
      Exit 1
    }
    else { 
      Write-Host "Windows is in grace period, remediation is not required. Activation status:" $ActivationStatus " Windows Os Version: " $ComputerInfo
      Exit 0
    }
  }
  else {
    Write-Host "This is not Enterprise license: " $WinProduct
    Exit 0
  }
}


Try {
  $SystemInfo = (Get-WmiObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue).Model             
  switch ($SystemInfo) {
    "Virtual Machine" {
      $MachineType = "VM"
    }
    "VMware Virtual Platform" {
      $MachineType = "VM"
    }
    "VirtualBox" {
      $MachineType = "VM"
    }
    "HVM domU" {
      $MachineType = "VM"
    }
    default {
      $MachineType = "Physical"
    }
  }
  if (!($MachineType -like "Physical")) {
    Write-Host "System is a VM - $SystemInfo; no action required."
    exit 0
  }
  else {
    getActivationStatus
  }
}
catch {
  $errMsg = $_.Exception.Message
  Write-Error $errMsg
  Exit 0
}
