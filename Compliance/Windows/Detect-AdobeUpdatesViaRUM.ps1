# ------------------- Variables -----------------
# Pre-defined RUM path (default location of a Software Centre/Company Portal installation)
$AdobeRUMPath = "C:\Program Files (x86)\Common Files\Adobe\OOBE_Enterprise\RemoteUpdateManager\RemoteUpdateManager.exe"
$LogFile = "C:\temp\Logs\AdobeUpdate.log"

# -----------------------------------------------


# ======================================== FUNCTIONS =======================================================
# ----------------------------------------------------------------------------------------------------------
function Log-Event
{
    <# -----------------------------------------------------------------------------------------------------
        .SYNOPSIS
            Create a log within the Adobe Patching event log
        .DESCRIPTION
            This Function will initiate a logging event that will write to the the designated
            logfile. using the Event ID, Source and include the required message.
        .PARAMETER Source
            This will call out which operation is causing the log to be written
        .PARAMETER EventID
            What ID should the Log be given
        .PARAMETER Message
            Quick/Concise message about what was logged
        .PARAMETER Type
            Specifies the entry type of the event. The acceptable values for this parameter are: Error, Warning,
            Information, SuccessAudit, and FailureAudit. If no Type is identified Information is the default
        .EXAMPLE
            Log-Event -Source "Offboarding" -EventID 86 -EntryType "Information" -Message "Workspace ID has been Unregistered"

    --------------------------------------------------------------------------------------------------------
    #>

    param
    (
        [Parameter(Mandatory = $True)]
        [string] $Source,

        [Parameter(Mandatory = $True)]
        [int32] $EventID,

        [Parameter(Mandatory = $True)]
        [ValidateSet("Error", "Warning", "Information", "SuccessAudit", "FailureAudit")]
        [string] $EntryType,

        [Parameter(Mandatory = $True)]
        [string] $Message
    )

    # ------------------- Variables -----------------

    # Do not touch, this is the patching Logname
    $LogName = "AdobeUpdate"

    # -----------------------------------------------

    if ([System.Diagnostics.EventLog]::Exists($LogName) -and [system.diagnostics.eventlog]::SourceExists($Source))
    {
        Write-Verbose "logging $LogName, $Source, with $EventID and $Message"
        Write-EventLog -LogName $LogName -Source $Source -EventID $EventID -EntryType $EntryType -Message $Message
    }
    else
    {
        New-EventLog -Source $Source -LogName $LogName -ErrorAction SilentlyContinue
        Limit-EventLog -LogName $LogName -MaximumSize 15360kb
        Write-Verbose "Created Eventlog"
        Write-EventLog -LogName $LogName -Source $Source -EventID $EventID -EntryType $EntryType -Message $Message
    }
} 
# End of Log-Event Function
# ----------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------
Function Log-LocalLog
{
    <# -----------------------------------------------------------------------------------------------------
        .SYNOPSIS
            Create a local log file for event detection
        .DESCRIPTION
            This Function will generate/modify a log file that indicates whether RUM exist on the machine
        .PARAMETER LogStr
            Message to be logged
        .EXAMPLE
            Log-LocalLog -LogStr "RUM: true"

    --------------------------------------------------------------------------------------------------------
    #>
	param 
	(
		[string] $LogStr
	)

    if (Test-Path $LogFile -ErrorAction SilentlyContinue)
	{
	    Add-content $LogFile -value "[$(Get-Date)] $LogStr"
    }
}
# End of Log-LocalLog Function
# ----------------------------------------------------------------------------------------------------------


# List of SAP code of applications serviceable through RUM
$SAPCodeList = @(
	"AEFT"	#After Effects
	"FLPR"	#Animate and Mobile Device Packaging
	"AUDT"	#Audition
	"KBRG"	#Bridge
	"CHAR"	#Character Animator
	"ESHR"	#Dimension
	"DRWV"	#Dreamweaver
	"FRSC"	#Fresco
	"ILST"	#Illustrator
	"AICY"	#InCopy
	"IDSN"	#InDesign
	"LRCC"	#Lightroom
	"LTRM"	#Lightroom Classic
	"AME"	#Media Encoder
	"PHSP"	#Photoshop
	"PRLD"	#Prelude
	"PPRO"	#Premiere Pro
	"RUSH"	#Premiere Rush
	"SBSTD"	#Substance Designer
	"SHPR"	#Substance Modeler
	"SBSTP"	#Substance Painter
	"SBSTA"	#Substance Sampler
	"STGR"	#Substance Stager
	"SPRK"	#XD

)

#======================= MAIN =======================

# ------------------- Variables -----------------
# Pre-defined RUM path (default location of a Software Centre/Company Portal installation)
$AdobeRUMPath = "C:\Program Files (x86)\Common Files\Adobe\OOBE_Enterprise\RemoteUpdateManager\RemoteUpdateManager.exe"
$AdobeUpdateCount = 0
$ActionFlag = 0
# -----------------------------------------------


# get product list from registry
$AdobeProducts64 = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion | Where-Object {$_.DisplayName -like "*Adobe*"} | Out-String
$AdobeProducts32 = Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion | Where-Object {$_.DisplayName -like "*Adobe*"} | Out-String

# search for Adobe product(s)
if ($AdobeProducts64 -or $AdobeProducts32)
{
    Write-Host "Adobe Products (64bits) found installed: $AdobeProducts64"
	Write-Host "Adobe Products (32bits) found installed: $AdobeProducts32" 
	Log-Event -Source "AdobeUpdate" -EventID 60001 -EntryType "Information" -Message "Adobe Products detected: $AdobeProducts64 $AdobeProducts32"
}
else
{
    Write-Host "Adobe products not found in system registry."
}


# check Adobe RUM presence
if(Test-Path $AdobeRUMPath -ErrorAction SilentlyContinue)
{
	# --- RUM is present on the machine ---
	Write-Host "RUM is found on the device"
	
	# check log file prescence
	if (Test-Path $LogFile -ErrorAction SilentlyContinue)
	{
		
		# ----- RUM exists and log file is present on the machine -----
		$Content = Get-Content -Path $LogFile -raw
		
        # if file content is removed
        if ($Content -eq $null)
        {
            $ActionFlag = 1
        }
        else
        {
		    # find last match of log entry "[datetime] RUM: true/false"
		    $RegexMatches = [regex]::Matches($Content, '\[([^\]]*)\] Adobe RUM presence: [^\[]*')
		
		    # extract the timestamp of the entry (last checked time)
		    $RunTime = $RegexMatches | ForEach-Object {
			    $_.Groups[1].Value
		    }

            # check if any matched entry found
            if ($RunTime -eq $null)
            {
                $ActionFlag = 1
            }
            else
            {
                # get latest entry if there are multiple matched lines
                if (($RunTime | Measure-Object -line).Lines -gt 1)
                {
                    $LastRunTime = $RunTime[-1]
		        }
                else
                {
                    $LastRunTime = $RunTime
                }

		        # if the script was last run more than 7 days ago
		        if ($LastRunTime -le (Get-Date).AddDays(-7))
		        {
                    $ActionFlag = 1
                }
            }
        }

        if ($ActionFlag -eq 1)
        {
			Write-Host "update local logs and trigger update"
			Log-LocalLog -LogStr "Adobe RUM presence: true"
			Log-LocalLog -LogStr "Adobe Products (64bits) found installed: $AdobeProducts64"
			Log-LocalLog -LogStr "Adobe Products (32bits) found installed: $AdobeProducts32"
			
			# run remediate script
			Log-Event -Source "AdobeUpdate" -EventID 60001 -EntryType "Information" -Message "Trigger Adobe RUM to attempt update"
			exit 1
		}
		else
		{
			Write-Host "no action taken as last update attempt was within 7 days"
			# no action required as the script was last run within a 7-day timeframe
			exit 0
		}
	}
	else
	{
		# ----- RUM exists and log file hasn't been created on the machine -----
		Write-Host "create local logs and trigger update"

        New-Item -Path $LogFile -ItemType File -Force
		Log-LocalLog -LogStr "Adobe RUM presence: true"
		Log-LocalLog -LogStr "Adobe Products (64bits) found installed: $AdobeProducts64"
		Log-LocalLog -LogStr "Adobe Products (32bits) found installed: $AdobeProducts32" 
		
		# run remediate script
		exit 1
	}
}
else
{
	# --- RUM is NOT present on the machine ---
	Write-Host "RUM is not found on the device."

	# if log file has been created
	if (Test-Path $LogFile -ErrorAction SilentlyContinue)
	{
		# ----- RUM not found and log file is present on the machine -----
		$Content = Get-Content -Path $LogFile -raw

        # if file content is removed
        if ($Content -eq $null)
        {
            $ActionFlag = 1
        }
        else
        {
		    # find last match of log entry "[datetime] RUM: true/false"
		    $RegexMatches = [regex]::Matches($Content, '\[([^\]]*)\] Adobe RUM presence: [^\[]*')
		
		    # extract the timestamp of the entry (last checked time)
		    $RunTime = $RegexMatches | ForEach-Object {
			    $_.Groups[1].Value
		    }

            # check if any matched entry found
            if ($RunTime -eq $null)
            {
                $ActionFlag = 1
            }
            else
            {
                # get latest entry if there are multiple matched lines
                if (($RunTime | Measure-Object -line).Lines -gt 1)
                {
                    $LastRunTime = $RunTime[-1]
		        }
                else
                {
                    $LastRunTime = $RunTime
                }

		        # if the script was last run more than 7 days ago
		        if ($LastRunTime -le (Get-Date).AddDays(-7))
		        {
                    $ActionFlag = 1
                }
            }
        }

        if ($ActionFlag -eq 1)
        {
			Write-Host "update local logs and trigger update"
			Log-LocalLog -LogStr "Adobe RUM presence: false"
			Log-LocalLog -LogStr "Adobe Products (64bits) found installed: $AdobeProducts64"
			Log-LocalLog -LogStr "Adobe Products (32bits) found installed: $AdobeProducts32"
		}
		else
		{
			Write-Host "no action taken as last check was within 7 days"
			# no action required as the script was last run within a 7-day timeframe
		}

		# no action can be taken as RUM does not exist
		exit 0
	}
	else
	{
		Write-Host "create local logs"
        New-Item -Path $LogFile -ItemType File -Force
		Log-LocalLog -LogStr "Adobe RUM presence: false"
		Log-LocalLog -LogStr "Adobe Products (64bits) found installed: $AdobeProducts64"
		Log-LocalLog -LogStr "Adobe Products (32bits) found installed: $AdobeProducts32"
		
		# no action can be taken as RUM does not exist
		exit 0
	}
}
