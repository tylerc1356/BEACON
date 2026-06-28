$ToolkitRoot = Split-Path $PSScriptRoot -Parent

$reportFolder = Join-Path $ToolkitRoot "Reports\FullReport"

if (-not (Test-Path $reportFolder)) {
    New-Item -ItemType Directory -Path $reportFolder -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportPath = Join-Path $reportFolder "TylerToolkit-FullReport-$timestamp.html"

$computer = Get-CimInstance Win32_ComputerSystem
$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor
     $cpuName = $cpu.Name
$cpuManufacturer = $cpu.Manufacturer
$cpuCores = $cpu.NumberOfCores
$cpuLogicalProcessors = $cpu.NumberOfLogicalProcessors
$cpuMaxClockSpeed = $cpu.MaxClockSpeed
$cpuCurrentClockSpeed = $cpu.CurrentClockSpeed
$cpuLoad = $cpu.LoadPercentage
$bios = Get-CimInstance Win32_BIOS
$baseboard = Get-CimInstance Win32_BaseBoard
$computerSystemProduct = Get-CimInstance Win32_ComputerSystemProduct

$biosManufacturer = $bios.Manufacturer
$biosVersion = $bios.SMBIOSBIOSVersion
$biosSerialNumber = $bios.SerialNumber
$biosReleaseDate = $bios.ReleaseDate

$baseboardManufacturer = $baseboard.Manufacturer
$baseboardProduct = $baseboard.Product
$baseboardVersion = $baseboard.Version
$systemUUID = $computerSystemProduct.UUID
$gpus = Get-CimInstance Win32_VideoController
$firewallProfiles = Get-NetFirewallProfile

$defenderStatus = Get-MpComputerStatus

$bitLockerStatus = try {
    Get-BitLockerVolume -MountPoint "C:" -ErrorAction Stop
} catch {
    $null
}

$secureBootStatus = try {
    Confirm-SecureBootUEFI -ErrorAction Stop
} catch {
    "Unsupported or unavailable"
}
 $importantServiceNames = @(
    "wuauserv",      # Windows Update
    "WinDefend",     # Microsoft Defender Antivirus
    "Spooler",       # Print Spooler
    "WinRM",         # Windows Remote Management
    "BITS",          # Background Intelligent Transfer Service
    "EventLog",      # Windows Event Log
    "LanmanWorkstation",
    "LanmanServer"
)

$importantServices = foreach ($serviceName in $importantServiceNames) {
    Get-Service -Name $serviceName -ErrorAction SilentlyContinue
}
$eventStartTime = (Get-Date).AddHours(-24)

$criticalEvents = Get-WinEvent -FilterHashtable @{
    LogName = "System"
    Level = 1
    StartTime = $eventStartTime
} -ErrorAction SilentlyContinue

$errorEvents = Get-WinEvent -FilterHashtable @{
    LogName = "System"
    Level = 2
    StartTime = $eventStartTime
} -ErrorAction SilentlyContinue

$recentProblemEvents = Get-WinEvent -FilterHashtable @{
    LogName = "System"
    Level = 1,2
    StartTime = $eventStartTime
} -ErrorAction SilentlyContinue |
Select-Object -First 10 TimeCreated, ProviderName, Id, LevelDisplayName, Message
$hotfixes = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 5

$lastHotfix = $hotfixes | Select-Object -First 1
  $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue

$powerPlan = powercfg /getactivescheme 2>$null
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$memoryModules = Get-CimInstance Win32_PhysicalMemory

$totalMemoryGB = [math]::Round($computer.TotalPhysicalMemory / 1GB, 2)
$freeMemoryGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedMemoryGB = [math]::Round($totalMemoryGB - $freeMemoryGB, 2)
$memoryUsedPercent = [math]::Round(($usedMemoryGB / $totalMemoryGB) * 100, 2)
$drives = Get-CimInstance Win32_LogicalDisk |
    Where-Object { $_.DriveType -eq 3 } |
    Select-Object DeviceID, VolumeName, Size, FreeSpace

$dhcpEnabled = $adapterConfig.NetAdapter.DhcpEnabled
$dnsSuffix = $adapterConfig.NetProfile.Name
$freePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)
$uptime = (Get-Date) - $os.LastBootUpTime
$installDate = $os.InstallDate
$lastboot = $os.LastBootUpTime
$uptimeDays = [math]::Round($uptime.TotalDays, 2)

$diskStatus = if ($freePercent -ge 20) { "PASS" } elseif ($freePercent -ge 10) { "WARNING" } else { "FAIL" }
$uptimeStatus = if ($uptimeDays -le 14) { "PASS" } elseif ($uptimeDays -le 30) { "WARNING" } else { "FAIL" }

$html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Tyler Toolkit Full Report</title>
    <style>
        body { font-family: Arial; margin: 40px; }
        h1 { color: #2b579a; }
        table { border-collapse: collapse; width: 80%; margin-bottom: 25px; }
        th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .PASS { color: green; font-weight: bold; }
        .WARNING { color: orange; font-weight: bold; }
        .FAIL { color: red; font-weight: bold; }
    </style>
</head>
<body>
    <h1>Tyler Toolkit Full Report</h1>
    <p><strong>Generated:</strong> $(Get-Date)</p>

    <h2>System Information</h2>
    <table>
        <tr><th>Item</th><th>Value</th></tr>
        <tr><td>Computer Name</td><td>$env:COMPUTERNAME</td></tr>
        <tr><td>User</td><td>$env:USERNAME</td></tr>
        <tr><td>Windows</td><td>$($os.Caption)</td></tr>
        <tr><td>CPU</td><td>$($cpu.Name)</td></tr>
        <tr><td>Memory</td><td>$([math]::Round($computer.TotalPhysicalMemory / 1GB, 2)) GB</td></tr>
        <tr><td>Disk Free</td><td>$freePercent%</td></tr>
        <tr><td>Uptime</td><td>$uptimeDays days</td></tr>
    </table>
   <h2>Storage Information</h2>
    <table>
        <tr>
            <th>Drive</th>
            <th>Volume Name</th>
            <th>Total Size GB</th>
            <th>Free Space GB</th>
            <th>Free %</th>
        </tr>
        $(
            foreach ($drive in $drives) {
                $totalGB = [math]::Round($drive.Size / 1GB, 2)
                $freeGB = [math]::Round($drive.FreeSpace / 1GB, 2)
                $freePct = [math]::Round(($drive.FreeSpace / $drive.Size) * 100, 2)

                "<tr><td>$($drive.DeviceID)</td><td>$($drive.VolumeName)</td><td>$totalGB</td><td>$freeGB</td><td>$freePct%</td></tr>"
            }
        )
    </table>
<h2>Windows Details</h2>
    <table>
        <tr><th>Item</th><th>Value</th></tr>
        <tr><td>Edition</td><td>$($os.Caption)</td></tr>
        <tr><td>Version</td><td>$($os.Version)</td></tr>
        <tr><td>Build Number</td><td>$($os.BuildNumber)</td></tr>
        <tr><td>Architecture</td><td>$($os.OSArchitecture)</td></tr>
        <tr><td>Install Date</td><td>$installDate</td></tr>
        <tr><td>Last Boot Time</td><td>$lastBoot</td></tr>
    </table>
<h2>Memory Information</h2>
    <table>
        <tr><th>Item</th><th>Value</th></tr>
        <tr><td>Total Memory</td><td>$totalMemoryGB GB</td></tr>
        <tr><td>Used Memory</td><td>$usedMemoryGB GB</td></tr>
        <tr><td>Free Memory</td><td>$freeMemoryGB GB</td></tr>
        <tr><td>Memory Used %</td><td>$memoryUsedPercent%</td></tr>
    </table>

    <h3>Installed Memory Modules</h3>
    <table>
        <tr>
            <th>Slot</th>
            <th>Manufacturer</th>
            <th>Capacity GB</th>
            <th>Speed MHz</th>
            <th>Part Number</th>
        </tr>
        $(
            foreach ($module in $memoryModules) {
                $capacityGB = [math]::Round($module.Capacity / 1GB, 2)
                "<tr><td>$($module.DeviceLocator)</td><td>$($module.Manufacturer)</td><td>$capacityGB</td><td>$($module.Speed)</td><td>$($module.PartNumber)</td></tr>"
            }
        )
    </table>
<h2>Processor Information</h2>
    <table>
        <tr><th>Item</th><th>Value</th></tr>
        <tr><td>Name</td><td>$cpuName</td></tr>
        <tr><td>Manufacturer</td><td>$cpuManufacturer</td></tr>
        <tr><td>Cores</td><td>$cpuCores</td></tr>
        <tr><td>Logical Processors</td><td>$cpuLogicalProcessors</td></tr>
        <tr><td>Max Clock Speed</td><td>$cpuMaxClockSpeed MHz</td></tr>
        <tr><td>Current Clock Speed</td><td>$cpuCurrentClockSpeed MHz</td></tr>
        <tr><td>Current Load</td><td>$cpuLoad%</td></tr>
    </table>
<h2>BIOS / Motherboard Information</h2>
    <table>
        <tr><th>Item</th><th>Value</th></tr>
        <tr><td>BIOS Manufacturer</td><td>$biosManufacturer</td></tr>
        <tr><td>BIOS Version</td><td>$biosVersion</td></tr>
        <tr><td>Serial Number</td><td>$biosSerialNumber</td></tr>
        <tr><td>BIOS Release Date</td><td>$biosReleaseDate</td></tr>
        <tr><td>Motherboard Manufacturer</td><td>$baseboardManufacturer</td></tr>
        <tr><td>Motherboard Product</td><td>$baseboardProduct</td></tr>
        <tr><td>Motherboard Version</td><td>$baseboardVersion</td></tr>
        <tr><td>System UUID</td><td>$systemUUID</td></tr>
    </table>
 <h2>Graphics / GPU Information</h2>
    <table>
        <tr>
            <th>Name</th>
            <th>Driver Version</th>
            <th>Driver Date</th>
            <th>Video Processor</th>
            <th>Adapter RAM GB</th>
        </tr>
        $(
            foreach ($gpu in $gpus) {
                $adapterRamGB = if ($gpu.AdapterRAM) { [math]::Round($gpu.AdapterRAM / 1GB, 2) } else { "N/A" }

                "<tr><td>$($gpu.Name)</td><td>$($gpu.DriverVersion)</td><td>$($gpu.DriverDate)</td><td>$($gpu.VideoProcessor)</td><td>$adapterRamGB</td></tr>"
            }
        )
    </table>$
<h2>Security Basics</h2>
    <table>
        <tr><th>Item</th><th>Status</th></tr>
        <tr><td>Windows Defender Enabled</td><td>$($defenderStatus.AntivirusEnabled)</td></tr>
        <tr><td>Real-Time Protection Enabled</td><td>$($defenderStatus.RealTimeProtectionEnabled)</td></tr>
        <tr><td>Defender Signature Version</td><td>$($defenderStatus.AntivirusSignatureVersion)</td></tr>
        <tr><td>Secure Boot</td><td>$secureBootStatus</td></tr>
        <tr><td>BitLocker C:</td><td>$(if ($bitLockerStatus) { $bitLockerStatus.ProtectionStatus } else { "Unavailable" })</td></tr>
    </table>

    <h3>Firewall Profiles</h3>
    <table>
        <tr><th>Profile</th><th>Enabled</th><th>Default Inbound</th><th>Default Outbound</th></tr>
        $(
            foreach ($profile in $firewallProfiles) {
                "<tr><td>$($profile.Name)</td><td>$($profile.Enabled)</td><td>$($profile.DefaultInboundAction)</td><td>$($profile.DefaultOutboundAction)</td></tr>"
            }
        )
    </table>
  <h2>Important Services</h2>
    <table>
        <tr>
            <th>Service Name</th>
            <th>Display Name</th>
            <th>Status</th>
            <th>Start Type</th>
        </tr>
        $(
            foreach ($service in $importantServices) {
                $startupType = (Get-CimInstance Win32_Service -Filter "Name='$($service.Name)'").StartMode

                "<tr><td>$($service.Name)</td><td>$($service.DisplayName)</td><td>$($service.Status)</td><td>$startupType</td></tr>"
            }
        )
    </table>
<h2>Event Log Summary - Last 24 Hours</h2>
    <table>
        <tr><th>Event Type</th><th>Count</th></tr>
        <tr><td>Critical Events</td><td>$($criticalEvents.Count)</td></tr>
        <tr><td>Error Events</td><td>$($errorEvents.Count)</td></tr>
    </table>

    <h3>Recent Critical/Error Events</h3>
    <table>
        <tr>
            <th>Time</th>
            <th>Source</th>
            <th>Event ID</th>
            <th>Level</th>
            <th>Message</th>
        </tr>
        $(
            foreach ($event in $recentProblemEvents) {
                $message = if ($event.Message) { $event.Message.Replace("<", "&lt;").Replace(">", "&gt;") } else { "" }
                "<tr><td>$($event.TimeCreated)</td><td>$($event.ProviderName)</td><td>$($event.Id)</td><td>$($event.LevelDisplayName)</td><td>$message</td></tr>"
            }
        )
    </table>
<h2>Windows Update Information</h2>
    <table>
        <tr><th>Item</th><th>Value</th></tr>
        <tr><td>Most Recent Update</td><td>$($lastHotfix.HotFixID)</td></tr>
        <tr><td>Installed On</td><td>$($lastHotfix.InstalledOn)</td></tr>
        <tr><td>Description</td><td>$($lastHotfix.Description)</td></tr>
    </table>

    <h3>Recent Installed Updates</h3>
    <table>
        <tr>
            <th>HotFix ID</th>
            <th>Description</th>
            <th>Installed On</th>
            <th>Installed By</th>
        </tr>
        $(
            foreach ($hotfix in $hotfixes) {
                "<tr><td>$($hotfix.HotFixID)</td><td>$($hotfix.Description)</td><td>$($hotfix.InstalledOn)</td><td>$($hotfix.InstalledBy)</td></tr>"
            }
        )
    </table>
<h2>Power / Battery Information</h2>
    <table>
        <tr><th>Item</th><th>Value</th></tr>
        <tr><td>Active Power Plan</td><td>$powerPlan</td></tr>
        <tr><td>Battery Present</td><td>$(if ($battery) { "Yes" } else { "No" })</td></tr>
        <tr><td>Battery Status</td><td>$(if ($battery) { $battery.BatteryStatus } else { "N/A" })</td></tr>
        <tr><td>Estimated Charge Remaining</td><td>$(if ($battery) { "$($battery.EstimatedChargeRemaining)%" } else { "N/A" })</td></tr>
        <tr><td>Estimated Runtime</td><td>$(if ($battery) { "$($battery.EstimatedRunTime) minutes" } else { "N/A" })</td></tr>
    </table>
    <h2>Health Summary</h2>
    <table>
        <tr><th>Check</th><th>Status</th></tr>
        <tr><td>Disk Space</td><td class="$diskStatus">$diskStatus</td></tr>
        <tr><td>Uptime</td><td class="$uptimeStatus">$uptimeStatus</td></tr>
    </table>
</body>
</html>
"@

$html | Set-Content -Path $reportPath -Encoding UTF8

Write-Host ""
Write-Host "Full report generated successfully." -ForegroundColor Green
Write-Host "Report saved to: $reportPath" -ForegroundColor Cyan

Start-Process $reportPath