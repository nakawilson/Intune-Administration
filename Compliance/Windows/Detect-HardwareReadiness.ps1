$exitCode = 0

$outObject = @{ returnCode = 0; returnResult = ""; returnReason = ""; logging = "" }

[int]$MinOSDiskSizeGB = 64
[int]$MinMemoryGB = 4
[Uint32]$MinClockSpeedMHz = 1000
[Uint32]$MinCores = 2
[Uint16]$RequiredAddressWidth = 64

$PASS_STRING = "PASS"
$FAIL_STRING = "FAIL"
$UNDETERMINED_CAPS_STRING = "UNDETERMINED"
$UNDETERMINED_STRING = "Undetermined"
$CAPABLE_STRING = "Capable"
$NOT_CAPABLE_STRING = "Not capable"
$CAPABLE_CAPS_STRING = "CAPABLE"
$NOT_CAPABLE_CAPS_STRING = "NOT CAPABLE"
$STORAGE_STRING = "Storage"
$OS_DISK_SIZE_STRING = "OSDiskSize"
$MEMORY_STRING = "Memory"
$SYSTEM_MEMORY_STRING = "System_Memory"
$GB_UNIT_STRING = "GB"
$TPM_STRING = "TPM"
$TPM_VERSION_STRING = "TPMVersion"
$PROCESSOR_STRING = "Processor"
$SECUREBOOT_STRING = "SecureBoot"

$logFormat = '{0}: {1}={2}. {3}; '

$logFormatWithUnit = '{0}: {1}={2}{3}. {4}; '

$logFormatReturnReason = '{0}, '

$logFormatException = '{0}; '

$logFormatWithBlob = '{0}: {1}. {2}; '

function Private:UpdateReturnCode{
    param(
        [Parameter(Mandatory=$true)]
        [ValidateRange(-1,1)]
        [int] $ReturnCode
    )
    if ($outObject.returnCode -ne 1 -or $ReturnCode -ne -1){
        $outObject.returnCode = $ReturnCode
    }
}

$Source = @"
using System;
using System.Runtime.InteropServices;

    public class CpuFamilyResult
    {
        public bool IsValid { get; set; }
        public string Message { get; set; }
    }

    public class CpuFamily
    {
        [StructLayout(LayoutKind.Sequential)]
        public struct SYSTEM_INFO
        {
            public ushort ProcessorArchitecture;
            ushort Reserved;
            public uint PageSize;
            public IntPtr MinimumApplicationAddress;
            public IntPtr MaximumApplicationAddress;
            public IntPtr ActiveProcessorMask;
            public uint NumberOfProcessors;
            public uint ProcessorType;
            public uint AllocationGranularity;
            public ushort ProcessorLevel;
            public ushort ProcessorRevision;
        }

        [DllImport("kernel32.dll")]
        internal static extern void GetNativeSystemInfo(ref SYSTEM_INFO lpSystemInfo);

        public enum ProcessorFeature : uint
        {
            PF_ARM_V81_ATOMIC_INSTRUCTIONS_AVAILABLE = 34
        }

        [DllImport("kernel32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        static extern bool IsProcessorFeaturePresent(ProcessorFeature processorFeature);

        private const ushort PROCESSOR_ARCHITECTURE_X86 = 0;
        private const ushort PROCESSOR_ARCHITECTURE_ARM = 5;
        private const ushort PROCESSOR_ARCHITECTURE_X64 = 9;
        
        private const string INTEL_MANUFACTURER = "GenuineIntel";
        private const string AMD_MANUFACTURER = "AuthenticAMD";

        public static CpuFamilyResult Validate(string manufacturer)
        {
            CpuFamilyResult cpuFamilyResult = new CpuFamilyResult();

            if (string.IsNullOrWhiteSpace(manufacturer))
            {
                cpuFamilyResult.IsValid = false;
                cpuFamilyResult.Message = "Manufacturer is null or empty";
                return cpuFamilyResult;
            }

            SYSTEM_INFO sysInfo = new SYSTEM_INFO();
            GetNativeSystemInfo(ref sysInfo);

            switch (sysInfo.ProcessorArchitecture)
            {
                case PROCESSOR_ARCHITECTURE_ARM:
                    bool isArmv81Supported = IsProcessorFeaturePresent(ProcessorFeature.PF_ARM_V81_ATOMIC_INSTRUCTIONS_AVAILABLE);
                    cpuFamilyResult.IsValid = isArmv81Supported;
                    cpuFamilyResult.Message = isArmv81Supported ? "Success" : "Processor does not implement ARM v8.1 atomic instruction";
                    break;

                case PROCESSOR_ARCHITECTURE_X64:
                case PROCESSOR_ARCHITECTURE_X86:

                    int cpuFamily = sysInfo.ProcessorLevel;
                    int cpuModel = (sysInfo.ProcessorRevision >> 8) & 0xFF;
                    int cpuStepping = sysInfo.ProcessorRevision & 0xFF;

                    if (manufacturer.Equals(INTEL_MANUFACTURER, StringComparison.OrdinalIgnoreCase))
                    {
                        if ((cpuFamily == 6 && (cpuModel == 142 || cpuModel == 158) && cpuStepping == 9) || (cpuFamily == 6 && cpuModel <= 95 && cpuModel != 85))
                        {
                            cpuFamilyResult.IsValid = false;
                            cpuFamilyResult.Message = "Intel CPU Family " + cpuFamily + ", Model " + cpuModel + ", Stepping " + cpuStepping + " not supported";
                        }
                        else
                        {
                            cpuFamilyResult.IsValid = true;
                            cpuFamilyResult.Message = "Intel family Success";
                        }
                    }
                    else if (manufacturer.Equals(AMD_MANUFACTURER, StringComparison.OrdinalIgnoreCase))
                    {
                        if (cpuFamily < 23 || cpuModel == 1 || cpuModel == 17)
                        {
                            cpuFamilyResult.IsValid = false;
                            cpuFamilyResult.Message = "AMD CPU Family " + cpuFamily + " , Model " + cpuModel + ", Stepping " + cpuStepping + " not supported";
                        }
                        else
                        {
                            cpuFamilyResult.IsValid = true;
                            cpuFamilyResult.Message = "AMD family Success";
                        }
                    }
                    else
                    {
                        cpuFamilyResult.IsValid = false;
                        cpuFamilyResult.Message = "Unsupported Manufacturer - '" + manufacturer + "'. Architecture: " + sysInfo.ProcessorArchitecture + ", CPUFamily: " + sysInfo.ProcessorLevel + ", ProcessorRevision: " + sysInfo.ProcessorRevision;
                    }

                    break;

                default:
                    cpuFamilyResult.IsValid = false;
                    cpuFamilyResult.Message = "Unsupported CPU category. Architecture: " + sysInfo.ProcessorArchitecture + ", CPUFamily: " + sysInfo.ProcessorLevel + ", ProcessorRevision: " + sysInfo.ProcessorRevision;
                    break;
            }
            return cpuFamilyResult;
        }
    }
"@

try {
    $osDrive = Get-WmiObject -Class Win32_OperatingSystem | Select-Object -Property SystemDrive
    $osDriveSize = Get-WmiObject -Class Win32_LogicalDisk -filter "DeviceID='$($osDrive.SystemDrive)'" | Select-Object @{Name = "SizeGB"; Expression = { $_.Size / 1GB -as [int] } }  

    if ($osDriveSize.SizeGB -lt $MinOSDiskSizeGB) {
        UpdateReturnCode -ReturnCode 1
        $outObject.returnReason += $logFormatReturnReason -f $STORAGE_STRING
        $outObject.logging += $logFormatWithUnit -f $STORAGE_STRING, $OS_DISK_SIZE_STRING, ($osDriveSize.SizeGB), $GB_UNIT_STRING, $FAIL_STRING
        $exitCode = 1
    }
    else {
        $outObject.logging += $logFormatWithUnit -f $STORAGE_STRING, $OS_DISK_SIZE_STRING, ($osDriveSize.SizeGB), $GB_UNIT_STRING, $PASS_STRING
    }
}
catch {
    UpdateReturnCode -ReturnCode -1
    $outObject.logging += $logFormat -f $STORAGE_STRING, $OS_DISK_SIZE_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
    $outObject.logging += $logFormatException -f ($_.Exception)
    $exitCode = 1
}

try {
    $memory = Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum | Select-Object @{Name = "SizeGB"; Expression = { $_.Sum / 1GB -as [int] } }
    
    if ($memory.SizeGB -lt $MinMemoryGB) {
        UpdateReturnCode -ReturnCode 1
        $outObject.returnReason += $logFormatReturnReason -f $MEMORY_STRING
        $outObject.logging += $logFormatWithUnit -f $MEMORY_STRING, $SYSTEM_MEMORY_STRING, ($memory.SizeGB), $GB_UNIT_STRING, $FAIL_STRING
        $exitCode = 1
    }
    else {
        $outObject.logging += $logFormatWithUnit -f $MEMORY_STRING, $SYSTEM_MEMORY_STRING, ($memory.SizeGB), $GB_UNIT_STRING, $PASS_STRING
    }
}
catch {
    UpdateReturnCode -ReturnCode -1
    $outObject.logging += $logFormat -f $MEMORY_STRING, $SYSTEM_MEMORY_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
    $outObject.logging += $logFormatException -f ($_.Exception)
    $exitCode = 1
}
    
try {
    $tpm = Get-Tpm

    if ($tpm.TpmPresent) {
        $tpmVersion = Get-WmiObject -Class Win32_Tpm -Namespace root\CIMV2\Security\MicrosoftTpm | Select-Object -Property SpecVersion
        
        if (!$tpmVersion.SpecVersion.StartsWith("1.2") -and !$tpmVersion.SpecVersion.StartsWith("2.0")) {
            UpdateReturnCode -ReturnCode 1
            $outObject.returnReason += $logFormatReturnReason -f $TPM_STRING
            $outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, ($tpmVersion.SpecVersion), $FAIL_STRING
            $exitCode = 1
        }
        else {
            $outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, ($tpmVersion.SpecVersion), $PASS_STRING
        }
    }
    else {
        if ($tpm.GetType().Name -eq "String") {
            UpdateReturnCode -ReturnCode -1
            $outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
            $outObject.logging += $logFormatException -f $tpm
        }
        else {
            UpdateReturnCode -ReturnCode  1
            $outObject.returnReason += $logFormatReturnReason -f $TPM_STRING
            $outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, ($tpm.TpmPresent), $FAIL_STRING
        }
        $exitCode = 1
    }
}
catch {
    UpdateReturnCode -ReturnCode -1
    $outObject.logging += $logFormat -f $TPM_STRING, $TPM_VERSION_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
    $outObject.logging += $logFormatException -f ($_.Exception)
    $exitCode = 1
}

try {
    $cpuDetails = Get-WmiObject -Class Win32_Processor | Select-Object -Property AddressWidth, MaxClockSpeed, NumberOfCores, Manufacturer, Caption
    $cpuDetailsLog = "{AddressWidth=$($cpuDetails.AddressWidth); MaxClockSpeed=$($cpuDetails.MaxClockSpeed); NumberOfCores=$($cpuDetails.NumberOfCores); Manufacturer=$($cpuDetails.Manufacturer); Caption=$($cpuDetails.Caption)}"

    $processorCheckFailed = $false

    if ($cpuDetails.AddressWidth -ne $RequiredAddressWidth) {
        UpdateReturnCode -ReturnCode 1
        $processorCheckFailed = $true
        $exitCode = 1
    }
        
    if ($cpuDetails.MaxClockSpeed -le $MinClockSpeedMHz) {
        UpdateReturnCode -ReturnCode 1;
        $processorCheckFailed = $true
        $exitCode = 1
    }
    
    if ($cpuDetails.NumberOfCores -lt $MinCores) {
        UpdateReturnCode -ReturnCode 1
        $processorCheckFailed = $true
        $exitCode = 1
    }

    Add-Type -TypeDefinition $Source
    $cpuFamilyResult = [CpuFamily]::Validate([String]$cpuDetails.Manufacturer)

    if (!$cpuFamilyResult.IsValid) {
        UpdateReturnCode -ReturnCode 1
        $processorCheckFailed = $true
        $exitCode = 1
    }

    if ($processorCheckFailed) {
        $outObject.returnReason += $logFormatReturnReason -f $PROCESSOR_STRING
        $outObject.logging += $logFormatWithBlob -f $PROCESSOR_STRING, ($cpuDetailsLog), $FAIL_STRING

    }
    else {
        $outObject.logging += $logFormatWithBlob -f $PROCESSOR_STRING, ($cpuDetailsLog), $PASS_STRING
    }
}
catch {
    UpdateReturnCode -ReturnCode -1
    $outObject.logging += $logFormat -f $PROCESSOR_STRING, $PROCESSOR_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
    $outObject.logging += $logFormatException -f ($_.Exception)
    $exitCode = 1
}

try {
    $isSecureBootEnabled = Confirm-SecureBootUEFI
    $outObject.logging += $logFormatWithBlob -f $SECUREBOOT_STRING, $CAPABLE_STRING, $PASS_STRING
}
catch [System.PlatformNotSupportedException] {
    UpdateReturnCode -ReturnCode 1
    $outObject.returnReason += $logFormatReturnReason -f $SECUREBOOT_STRING
    $outObject.logging += $logFormatWithBlob -f $SECUREBOOT_STRING, $NOT_CAPABLE_STRING, $FAIL_STRING
    $exitCode = 1
}
catch [System.UnauthorizedAccessException] {
    UpdateReturnCode -ReturnCode -1
    $outObject.logging += $logFormatWithBlob -f $SECUREBOOT_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
    $outObject.logging += $logFormatException -f ($_.Exception)
    $exitCode = 1
}
catch {
    UpdateReturnCode -ReturnCode -1
    $outObject.logging += $logFormatWithBlob -f $SECUREBOOT_STRING, $UNDETERMINED_STRING, $UNDETERMINED_CAPS_STRING
    $outObject.logging += $logFormatException -f ($_.Exception)
    $exitCode = 1
}

Switch ($outObject.returnCode) {

    0 { $outObject.returnResult = $CAPABLE_CAPS_STRING }
    1 { $outObject.returnResult = $NOT_CAPABLE_CAPS_STRING }
    -1 { $outObject.returnResult = $UNDETERMINED_CAPS_STRING }
}

$outObject | ConvertTo-Json -Compress
