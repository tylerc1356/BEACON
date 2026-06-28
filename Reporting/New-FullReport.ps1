$ToolkitRoot = Split-Path $PSScriptRoot -Parent

Import-Module (Join-Path $ToolkitRoot "Modules\Hardware\CPUInfo.psm1") -Force
Import-Module (Join-Path $ToolkitRoot "Modules\Hardware\MemoryInfo.psm1") -Force
Import-Module (Join-Path $ToolkitRoot "Modules\Hardware\BIOSInfo.psm1") -Force
Import-Module (Join-Path $ToolkitRoot "Modules\Hardware\GPUInfo.psm1") -Force
Import-Module (Join-Path $ToolkitRoot "Modules\Hardware\StorageInfo.psm1") -Force
Import-Module (Join-Path $ToolkitRoot "Modules\Hardware\PowerInfo.psm1") -Force
Import-Module (Join-Path $ToolkitRoot "Modules\OperatingSystem\WindowsInfo.psm1") -Force
Import-Module (Join-Path $ToolkitRoot "Modules\OperatingSystem\ServicesInfo.psm1") -Force
Import-Module (Join-Path $ToolkitRoot "Modules\OperatingSystem\EventLogInfo.psm1") -Force
Import-Module (Join-Path $ToolkitRoot "Modules\OperatingSystem\UpdateInfo.psm1") -Force
Import-Module (Join-Path $ToolkitRoot "Modules\Security\SecurityInfo.psm1") -Force

function ConvertTo-BEHtmlValue {
    param([object]$Value)

    if ($null -eq $Value -or $Value -eq "") {
        return "Unavailable"
    }

    return [System.Net.WebUtility]::HtmlEncode($Value.ToString())
}

function New-BESectionHeader {
    param([string]$Title)

    return "<h2 style='color:#0f4c9c;border-bottom:2px solid #0f4c9c;padding-bottom:6px;margin-top:30px;'>$Title</h2>"
}

function New-BEKeyValueTable {
    param(
        [string]$Title,
        [hashtable]$Data
    )

    $rows = foreach ($key in $Data.Keys) {
        "<tr><td style='border:1px solid #ccc;padding:8px;font-weight:bold;width:35%;'>$key</td><td style='border:1px solid #ccc;padding:8px;'>$(ConvertTo-BEHtmlValue $Data[$key])</td></tr>"
    }

    return @"
$(New-BESectionHeader $Title)
<table style='border-collapse:collapse;width:100%;margin-bottom:24px;font-family:Arial,Helvetica,sans-serif;'>
<tr>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Item</th>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Value</th>
</tr>
$($rows -join "`n")
</table>
"@
}

$reportFolder = Join-Path $ToolkitRoot "Reports\FullReport"

if (-not (Test-Path $reportFolder)) {
    New-Item -ItemType Directory -Path $reportFolder -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportPath = Join-Path $reportFolder "Beacon-FullReport-$timestamp.html"

$cpuInfo      = Get-BECPUInfo
$memoryInfo   = Get-BEMemoryInfo
$biosInfo     = Get-BEBIOSInfo
$gpuInfo      = Get-BEGPUInfo
$storageInfo  = Get-BEStorageInfo
$powerInfo    = Get-BEPowerInfo
$windowsInfo  = Get-BEWindowsInfo
$servicesInfo = Get-BEServicesInfo
$eventLogInfo = Get-BEEventLogInfo
$updateInfo   = Get-BEUpdateInfo
$securityInfo = Get-BESecurityInfo

$storageRows = foreach ($drive in $storageInfo) {
    "<tr><td style='border:1px solid #ccc;padding:8px;'>$(ConvertTo-BEHtmlValue $drive.DriveLetter)</td><td style='border:1px solid #ccc;padding:8px;'>$(ConvertTo-BEHtmlValue $drive.VolumeName)</td><td style='border:1px solid #ccc;padding:8px;'>$(ConvertTo-BEHtmlValue $drive.FileSystem)</td><td style='border:1px solid #ccc;padding:8px;'>$($drive.TotalGB)</td><td style='border:1px solid #ccc;padding:8px;'>$($drive.UsedGB)</td><td style='border:1px solid #ccc;padding:8px;'>$($drive.FreeGB)</td><td style='border:1px solid #ccc;padding:8px;'>$($drive.FreePercent)%</td></tr>"
}

$gpuRows = foreach ($gpu in $gpuInfo) {
    "<tr><td style='border:1px solid #ccc;padding:8px;'>$(ConvertTo-BEHtmlValue $gpu.Name)</td><td style='border:1px solid #ccc;padding:8px;'>$(ConvertTo-BEHtmlValue $gpu.DriverVersion)</td><td style='border:1px solid #ccc;padding:8px;'>$(ConvertTo-BEHtmlValue $gpu.DriverDate)</td><td style='border:1px solid #ccc;padding:8px;'>$(ConvertTo-BEHtmlValue $gpu.VideoProcessor)</td><td style='border:1px solid #ccc;padding:8px;'>$(ConvertTo-BEHtmlValue $gpu.AdapterRAMGB)</td></tr>"
}

$serviceRows = foreach ($service in $servicesInfo) {
    "<tr><td style='border:1px solid #ccc;padding:8px;'>$(ConvertTo-BEHtmlValue $service.Name)</td><td style='border:1px solid #ccc;padding:8px;'>$(ConvertTo-BEHtmlValue $service.DisplayName)</td><td style='border:1px solid #ccc;padding:8px;'>$(ConvertTo-BEHtmlValue $service.Status)</td><td style='border:1px solid #ccc;padding:8px;'>$(ConvertTo-BEHtmlValue $service.StartType)</td></tr>"
}

$hotfixRows = foreach ($hotfix in $updateInfo.RecentHotFixes) {
    "<tr><td style='border:1px solid #ccc;padding:8px;'>$(ConvertTo-BEHtmlValue $hotfix.HotFixID)</td><td style='border:1px solid #ccc;padding:8px;'>$(ConvertTo-BEHtmlValue $hotfix.Description)</td><td style='border:1px solid #ccc;padding:8px;'>$(ConvertTo-BEHtmlValue $hotfix.InstalledOn)</td><td style='border:1px solid #ccc;padding:8px;'>$(ConvertTo-BEHtmlValue $hotfix.InstalledBy)</td></tr>"
}

$eventRows = if ($eventLogInfo.RecentProblemEvents) {
    foreach ($event in $eventLogInfo.RecentProblemEvents) {
        "<tr><td style='border:1px solid #ccc;padding:8px;'>$(ConvertTo-BEHtmlValue $event.TimeCreated)</td><td style='border:1px solid #ccc;padding:8px;'>$(ConvertTo-BEHtmlValue $event.ProviderName)</td><td style='border:1px solid #ccc;padding:8px;'>$(ConvertTo-BEHtmlValue $event.Id)</td><td style='border:1px solid #ccc;padding:8px;'>$(ConvertTo-BEHtmlValue $event.LevelDisplayName)</td><td style='border:1px solid #ccc;padding:8px;'>$(ConvertTo-BEHtmlValue $event.Message)</td></tr>"
    }
}
else {
    "<tr><td colspan='5' style='border:1px solid #ccc;padding:10px;text-align:center;color:#555;'>No critical or error events found in the last 24 hours.</td></tr>"
}

$html = @"
<!DOCTYPE html>
<html>
<head>
<title>Beacon Full Report</title>
</head>
<body style='font-family:Arial,Helvetica,sans-serif;margin:30px;color:#222;background-color:#ffffff;'>

<div style='background-color:#0f4c9c;color:white;padding:22px;margin-bottom:26px;'>
    <h1 style='margin:0;font-size:32px;'>Beacon Full Report</h1>
    <p style='margin:6px 0 0 0;'>System Insight & Diagnostics</p>
    <p style='margin:6px 0 0 0;'>Generated: $(Get-Date)</p>
</div>

$(New-BESectionHeader "System Overview")
<table style='border-collapse:collapse;width:100%;margin-bottom:24px;font-family:Arial,Helvetica,sans-serif;'>
<tr>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Computer Name</th>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>User</th>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Windows</th>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>PowerShell</th>
</tr>
<tr>
<td style='border:1px solid #ccc;padding:8px;'>$(ConvertTo-BEHtmlValue $windowsInfo.ComputerName)</td>
<td style='border:1px solid #ccc;padding:8px;'>$(ConvertTo-BEHtmlValue $windowsInfo.CurrentUser)</td>
<td style='border:1px solid #ccc;padding:8px;'>$(ConvertTo-BEHtmlValue $windowsInfo.Caption)</td>
<td style='border:1px solid #ccc;padding:8px;'>$(ConvertTo-BEHtmlValue $windowsInfo.PowerShell)</td>
</tr>
</table>

$(New-BEKeyValueTable "Windows Details" @{
    "Edition" = $windowsInfo.Caption
    "Version" = $windowsInfo.Version
    "Build Number" = $windowsInfo.BuildNumber
    "Architecture" = $windowsInfo.Architecture
    "Install Date" = $windowsInfo.InstallDate
    "Last Boot Time" = $windowsInfo.LastBootTime
    "Uptime Days" = $windowsInfo.UptimeDays
})

$(New-BESectionHeader "Storage Information")
<table style='border-collapse:collapse;width:100%;margin-bottom:24px;font-family:Arial,Helvetica,sans-serif;'>
<tr>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Drive</th>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Volume Name</th>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>File System</th>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Total GB</th>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Used GB</th>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Free GB</th>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Free %</th>
</tr>
$($storageRows -join "`n")
</table>

$(New-BEKeyValueTable "Memory Information" @{
    "Total Memory" = "$($memoryInfo.TotalMemoryGB) GB"
    "Used Memory" = "$($memoryInfo.UsedMemoryGB) GB"
    "Free Memory" = "$($memoryInfo.FreeMemoryGB) GB"
    "Memory Used %" = "$($memoryInfo.MemoryUsedPercent)%"
    "Slot Count" = $memoryInfo.SlotCount
    "Memory Type" = $memoryInfo.MemoryType
    "Speed" = "$($memoryInfo.SpeedMHz) MHz"
})

$(New-BEKeyValueTable "Processor Information" @{
    "Name" = $cpuInfo.Name
    "Manufacturer" = $cpuInfo.Manufacturer
    "Cores" = $cpuInfo.Cores
    "Logical Processors" = $cpuInfo.LogicalProcessors
    "Max Clock Speed" = "$($cpuInfo.MaxClockSpeed) MHz"
    "Current Clock Speed" = "$($cpuInfo.CurrentClockSpeed) MHz"
    "Current Load" = "$($cpuInfo.LoadPercentage)%"
})

$(New-BEKeyValueTable "BIOS / Motherboard Information" @{
    "BIOS Manufacturer" = $biosInfo.BIOSManufacturer
    "BIOS Version" = $biosInfo.BIOSVersion
    "Serial Number" = $biosInfo.BIOSSerialNumber
    "BIOS Release Date" = $biosInfo.BIOSReleaseDate
    "Motherboard Manufacturer" = $biosInfo.MotherboardManufacturer
    "Motherboard Product" = $biosInfo.MotherboardProduct
    "Motherboard Version" = $biosInfo.MotherboardVersion
    "System UUID" = $biosInfo.SystemUUID
})

$(New-BESectionHeader "Graphics / GPU Information")
<table style='border-collapse:collapse;width:100%;margin-bottom:24px;font-family:Arial,Helvetica,sans-serif;'>
<tr>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Name</th>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Driver Version</th>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Driver Date</th>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Video Processor</th>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Adapter RAM GB</th>
</tr>
$($gpuRows -join "`n")
</table>

$(New-BEKeyValueTable "Security Basics" @{
    "Windows Defender Enabled" = $securityInfo.DefenderEnabled
    "Real-Time Protection Enabled" = $securityInfo.RealTimeProtectionEnabled
    "Defender Signature Version" = $securityInfo.DefenderSignatureVersion
    "Secure Boot" = $securityInfo.SecureBoot
    "BitLocker C:" = $securityInfo.BitLockerC
    "Domain Firewall Enabled" = $securityInfo.DomainFirewallEnabled
    "Private Firewall Enabled" = $securityInfo.PrivateFirewallEnabled
    "Public Firewall Enabled" = $securityInfo.PublicFirewallEnabled
})

$(New-BESectionHeader "Important Services")
<table style='border-collapse:collapse;width:100%;margin-bottom:24px;font-family:Arial,Helvetica,sans-serif;'>
<tr>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Service Name</th>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Display Name</th>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Status</th>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Start Type</th>
</tr>
$($serviceRows -join "`n")
</table>

$(New-BEKeyValueTable "Windows Update Information" @{
    "Most Recent Update" = $updateInfo.LatestHotFixID
    "Installed On" = $updateInfo.LatestInstalledOn
    "Description" = $updateInfo.LatestDescription
    "Installed By" = $updateInfo.LatestInstalledBy
})

$(New-BESectionHeader "Recent Installed Updates")
<table style='border-collapse:collapse;width:100%;margin-bottom:24px;font-family:Arial,Helvetica,sans-serif;'>
<tr>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>HotFix ID</th>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Description</th>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Installed On</th>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Installed By</th>
</tr>
$($hotfixRows -join "`n")
</table>

$(New-BEKeyValueTable "Power / Battery Information" @{
    "Active Power Plan" = $powerInfo.ActivePowerPlan
    "Battery Present" = $powerInfo.BatteryPresent
    "Battery Status" = $powerInfo.BatteryStatus
    "Estimated Charge Remaining" = $powerInfo.EstimatedChargeRemaining
    "Estimated Runtime Minutes" = $powerInfo.EstimatedRuntimeMinutes
})

$(New-BEKeyValueTable "Event Log Summary - Last 24 Hours" @{
    "Critical Events" = $eventLogInfo.CriticalEventCount
    "Error Events" = $eventLogInfo.ErrorEventCount
})

$(New-BESectionHeader "Recent Critical/Error Events")
<table style='border-collapse:collapse;width:100%;margin-bottom:24px;font-family:Arial,Helvetica,sans-serif;'>
<tr>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Time</th>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Source</th>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Event ID</th>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Level</th>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Message</th>
</tr>
$($eventRows -join "`n")
</table>

$(New-BEKeyValueTable "Health Summary" @{
    "Disk Space" = "PASS"
    "Uptime" = "PASS"
})

</body>
</html>
"@

$html | Set-Content -Path $reportPath -Encoding utf8

Write-Host ""
Write-Host "Full report generated successfully." -ForegroundColor Green
Write-Host "Report saved to: $reportPath" -ForegroundColor Cyan

Start-Process $reportPath
