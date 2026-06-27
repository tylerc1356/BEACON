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
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$drives = Get-CimInstance Win32_LogicalDisk |
    Where-Object { $_.DriveType -eq 3 } |
    Select-Object DeviceID, VolumeName, Size, FreeSpace
$network = Get-NetIPConfiguration |
    Where-Object { $_.IPv4DefaultGateway -ne $null } |
    Select-Object -First 1

$ipv4 = Get-NetIPAddress -InterfaceIndex $network.InterfaceIndex -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notlike "169.254*" -and $_.IPAddress -ne "127.0.0.1" } |
    Select-Object -First 1 -ExpandProperty IPAddress

$gateway = $network.IPv4DefaultGateway.NextHop
$dnsServers = ($network.DNSServer.ServerAddresses -join ", ")
$macAddress = $network.NetAdapter.MacAddress
$adapterName = $network.InterfaceAlias

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
    <h2>Network Information</h2>
    <table>
        <tr><th>Item</th><th>Value</th></tr>
        <tr><td>Adapter</td><td>$adapterName</td></tr>
        <tr><td>IPv4 Address</td><td>$ipv4</td></tr>
        <tr><td>Gateway</td><td>$gateway</td></tr>
        <tr><td>DNS Servers</td><td>$dnsServers</td></tr>
        <tr><td>MAC Address</td><td>$macAddress</td></tr>
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

    <h2>Health Summary</h2>
    <table>
        <tr><th>Check</th><th>Status</th></tr>
        <tr><td>Disk Space</td><td class="$diskStatus">$diskStatus</td></tr>
        <tr><td>Uptime</td><td class="$uptimeStatus">$uptimeStatus</td></tr>
    </table>
</body>
</html>
"@

$html | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host ""
Write-Host "Full report generated successfully." -ForegroundColor Green
Write-Host "Report saved to: $reportPath" -ForegroundColor Cyan

Start-Process $reportPath