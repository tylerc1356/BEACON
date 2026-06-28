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

function New-BEStatusBadge {
    param([string]$Status)

    switch ($Status) {
        "PASS" {
            return "<span style='background-color:#d1fae5;color:#065f46;padding:4px 10px;border-radius:12px;font-weight:bold;'>PASS</span>"
        }
        "WARNING" {
            return "<span style='background-color:#fef3c7;color:#92400e;padding:4px 10px;border-radius:12px;font-weight:bold;'>WARNING</span>"
        }
        "FAIL" {
            return "<span style='background-color:#fee2e2;color:#991b1b;padding:4px 10px;border-radius:12px;font-weight:bold;'>FAIL</span>"
        }
        default {
            return "<span style='background-color:#e5e7eb;color:#374151;padding:4px 10px;border-radius:12px;font-weight:bold;'>$Status</span>"
        }
    }
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

$cDrive = $storageInfo | Where-Object { $_.DriveLetter -eq "C:" } | Select-Object -First 1

$diskStatus = if ($cDrive.FreePercent -ge 20) { "PASS" } elseif ($cDrive.FreePercent -ge 10) { "WARNING" } else { "FAIL" }
$memoryStatus = if ($memoryInfo.MemoryUsedPercent -lt 80) { "PASS" } elseif ($memoryInfo.MemoryUsedPercent -lt 90) { "WARNING" } else { "FAIL" }
$uptimeStatus = if ($windowsInfo.UptimeDays -le 14) { "PASS" } elseif ($windowsInfo.UptimeDays -le 30) { "WARNING" } else { "FAIL" }
$defenderStatus = if ($securityInfo.DefenderEnabled -eq $true) { "PASS" } else { "FAIL" }
$firewallStatus = if ($securityInfo.PrivateFirewallEnabled -eq $true -and $securityInfo.PublicFirewallEnabled -eq $true) { "PASS" } else { "WARNING" }
$eventStatus = if ($eventLogInfo.CriticalEventCount -eq 0 -and $eventLogInfo.ErrorEventCount -le 5) { "PASS" } elseif ($eventLogInfo.CriticalEventCount -eq 0) { "WARNING" } else { "FAIL" }

$healthChecks = @($diskStatus, $memoryStatus, $uptimeStatus, $defenderStatus, $firewallStatus, $eventStatus)

$healthScore = 100
foreach ($status in $healthChecks) {
    if ($status -eq "WARNING") { $healthScore -= 8 }
    if ($status -eq "FAIL") { $healthScore -= 18 }
}

if ($healthScore -lt 0) {
    $healthScore = 0
}

$overallStatus = if ($healthScore -ge 90) { "PASS" } elseif ($healthScore -ge 70) { "WARNING" } else { "FAIL" }
$overallText = if ($healthScore -ge 90) { "Healthy" } elseif ($healthScore -ge 70) { "Needs Attention" } else { "Unhealthy" }

$recommendations = @()

if ($diskStatus -ne "PASS") {
    $recommendations += "Free up disk space on C:. Current free space is $($cDrive.FreePercent)%."
}

if ($memoryStatus -ne "PASS") {
    $recommendations += "Review memory usage. Current usage is $($memoryInfo.MemoryUsedPercent)%."
}

if ($uptimeStatus -ne "PASS") {
    $recommendations += "Restart the system. Current uptime is $($windowsInfo.UptimeDays) days."
}

if ($defenderStatus -ne "PASS") {
    $recommendations += "Review Microsoft Defender status."
}

if ($firewallStatus -ne "PASS") {
    $recommendations += "Review Windows Firewall profiles."
}

if ($eventStatus -ne "PASS") {
    $recommendations += "Review recent System event log errors or critical events."
}

if ($recommendations.Count -eq 0) {
    $recommendations += "No immediate action required."
}

$recommendationRows = foreach ($item in $recommendations) {
    "<tr><td style='border:1px solid #ccc;padding:8px;'>$(ConvertTo-BEHtmlValue $item)</td></tr>"
}

$healthRows = @(
    "<tr><td style='border:1px solid #ccc;padding:8px;'>Disk Space</td><td style='border:1px solid #ccc;padding:8px;'>$(New-BEStatusBadge $diskStatus)</td></tr>"
    "<tr><td style='border:1px solid #ccc;padding:8px;'>Memory Usage</td><td style='border:1px solid #ccc;padding:8px;'>$(New-BEStatusBadge $memoryStatus)</td></tr>"
    "<tr><td style='border:1px solid #ccc;padding:8px;'>Uptime</td><td style='border:1px solid #ccc;padding:8px;'>$(New-BEStatusBadge $uptimeStatus)</td></tr>"
    "<tr><td style='border:1px solid #ccc;padding:8px;'>Microsoft Defender</td><td style='border:1px solid #ccc;padding:8px;'>$(New-BEStatusBadge $defenderStatus)</td></tr>"
    "<tr><td style='border:1px solid #ccc;padding:8px;'>Firewall</td><td style='border:1px solid #ccc;padding:8px;'>$(New-BEStatusBadge $firewallStatus)</td></tr>"
    "<tr><td style='border:1px solid #ccc;padding:8px;'>Event Logs</td><td style='border:1px solid #ccc;padding:8px;'>$(New-BEStatusBadge $eventStatus)</td></tr>"
)

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

$(New-BESectionHeader "Overall System Health")
<table style='border-collapse:collapse;width:100%;margin-bottom:24px;font-family:Arial,Helvetica,sans-serif;'>
<tr>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Health Score</th>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Overall Status</th>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Summary</th>
</tr>
<tr>
<td style='border:1px solid #ccc;padding:12px;font-size:22px;font-weight:bold;'>$healthScore / 100</td>
<td style='border:1px solid #ccc;padding:12px;'>$(New-BEStatusBadge $overallStatus)</td>
<td style='border:1px solid #ccc;padding:12px;font-weight:bold;'>$overallText</td>
</tr>
</table>

$(New-BESectionHeader "Recommendations")
<table style='border-collapse:collapse;width:100%;margin-bottom:24px;font-family:Arial,Helvetica,sans-serif;'>
<tr><th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Recommendation</th></tr>
$($recommendationRows -join "`n")
</table>

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

$(New-BESectionHeader "Health Summary")
<table style='border-collapse:collapse;width:100%;margin-bottom:24px;font-family:Arial,Helvetica,sans-serif;'>
<tr>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Check</th>
<th style='background-color:#0f4c9c;color:white;padding:8px;text-align:left;'>Status</th>
</tr>
$($healthRows -join "`n")
</table>

</body>
</html>
"@

$html | Set-Content -Path $reportPath -Encoding utf8

Write-Host ""
Write-Host "Full report generated successfully." -ForegroundColor Green
Write-Host "Report saved to: $reportPath" -ForegroundColor Cyan

Start-Process $reportPath
