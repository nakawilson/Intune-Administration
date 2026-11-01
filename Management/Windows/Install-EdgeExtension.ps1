<#

.SYNOPSIS
Install Chrome extension to Windows via Powershell

.DESCRIPTION
The Powershell script installs Chrome extesion to Windows PC
via registry. Same script is also used to remove extension.

.PARAMETER Extension
String value of an extension ID to be installed on the Windows PC.

.PARAMETER Hive
String value of the registry hive to add registry entry.

If extension to be install on the Machine for all the use,
then this value will be 'Machine'. Also it is default value.

If extension to be installed for perticular user on the Machine,
then value will be 'User'.

.PARAMETER Remove
String value of an extension ID to be removed for the Windows PC.

.PARAMETER Path
String value of path to update.xml file. 
The values will depend on method of Extension hosting

.EXAMPLE
Install extension on Machin for all the user. (Extension hosted on the Chrome web store)
Chrome-ExtensionInstall -Extension 'ohkeehjepccedbdpohnbapepongppfcj' -Hive 'Machine'

Install extension for User on the machine. (Extension hosted on the Chrome web store)
Chrome-ExtensionInstall -Extension 'ohkeehjepccedbdpohnbapepongppfcj' -Hive 'User'

Remove extension for All user on the machine
Chrome-ExtensionInstall -Remove 'ohkeehjepccedbdpohnbapepongppfcj' -Hive 'Machine'

Remove extension for particular user on the machine
Chrome-ExtensionInstall -Remove 'ohkeehjepccedbdpohnbapepongppfcj' -Hive 'User'

Install extension hosted on local server or shared folder.
Chrome-ExtensionInstall -Extension 'ohkeehjepccedbdpohnbapepongppfcj' -Hive 'Machine' -Path <Path_to_update.xml>

#>


[cmdletBinding()]
Param(
	[String]$Extension,
	[ValidateSet('Machine', 'User')]
	[String]$Hive = 'Machine',
	[String]$Remove,
    [String]$Path = ''
)

$RegLocation = 'Software\Policies\Microsoft\Edge\ExtensionInstallForcelist'
$HKLMRegLocation = "HKLM:\$RegLocation"
$HKCURegLocation = "HKCU:\$RegLocation"

function Remove-RegisteyEntry {
    Param (
        [String]$RegPath,
        [String]$Property
    )

    $PropertyList = Get-ItemProperty -Path $RegPath
    foreach ($SingleProperty in $PropertyList.PSObject.Properties){
        if ($SingleProperty.Value -Like "*$Property*") {

            Write-Verbose -Message "Removing registry entry at localtion: $RegPath and property: $SingleProperty"

            Remove-ItemProperty -Path $RegPath -Name $SingleProperty.name

            Write-Host "Edge extension with ID: $Property removed."
        }
    }
}

function Add-RegisteyEntry {
    Param (
        [String]$RegPath,
        [String]$NewRegistryData
    )

    if (!(Test-Path -Path $RegPath)) {
        Write-Verbose -Message "Could not find registry location : $RegPath"
        Write-Verbose -Message "Creating registry entry..."

        New-Item -Path $RegPath -Force
    }

    Write-Verbose -Message "Location: $RegPath found in registry."

    $PropertiesCount = (Get-Item -Path $RegPath).ValueCount
    $NewRegistryValue = $PropertiesCount + 1

    Write-Verbose -Message "Total registry entries $PropertiesCount at location: $RegPath"

    $PropertyList = Get-ItemProperty -Path $RegPath

    while (($PropertyList) -and (Get-Member -InputObject $PropertyList -Name $NewRegistryValue)) {
        Write-Verbose -Message "Registry value $NewRegistryValue already Exists. Let's go for next value"
        $NewRegistryValue += 1
    }

    Write-Verbose -Message "New registry value is $NewRegistryValue"
    Write-Verbose -Message "Adding value: $NewRegistryValue and data: $NewRegistryData at location: $RegPath"

    New-ItemProperty -Path $RegPath -Name $NewRegistryValue -Value $NewRegistryData -PropertyType String -Force

    Write-Host "Edge Extension installed"
}

if ($PSBoundParameters.ContainsKey('Remove')) {

    Write-Verbose -Message "Uninstalling Edge Extension with ID: $Remove"

    Switch ($Hive) {
		
		'Machine' { Remove-RegisteyEntry $HKLMRegLocation $Remove }
		'User' { Remove-RegisteyEntry $HKCURegLocation $Remove }
	
	}
} else {

    Write-Verbose -Message "Installing Edge extension with ID: $Extension"

    if($path -eq ''){
        $RegistryData = "$Extension"
    }else{
        $RegistryData = "$Extension;$Path"
    }
    Switch ($Hive) {
		
		'Machine' { Add-RegisteyEntry $HKLMRegLocation $RegistryData }
		'User' { Add-RegisteyEntry $HKCURegLocation $RegistryData }
	
	}
}
