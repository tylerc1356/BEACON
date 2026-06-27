$ToolkitRoot = Split-Path $PSScriptRoot -Parent

Import-Module (Join-Path $ToolkitRoot "Modules\Logging.psm1") -Force

$logFolder = Join-Path $ToolkitRoot "Logs"
$logFile = Join-Path $logFolder "Health.log"

if (-not (Test-Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
}

Write-Log -Message "System health check started for $env:COMPUTERNAME" -LogFile $logFile

$disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
$freePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)

$os = Get-CimInstance -ClassName Win32_OperatingSystem
$uptime = (Get-Date) - $os.LastBootUpTime
$uptimeDays = [math]::Round($uptime.TotalDays, 2)

$internetTest = Test-Connection -ComputerName "8.8.8.8" -Count 2 -Quiet

$healthResults = [PSCustomObject]@{
    ComputerName      = $env:COMPUTERNAME
    CheckDate         = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    DiskFreePercent   = $freePercent
    DiskStatus        = if ($freePercent -ge 20) { "PASS" } elseif ($freePercent -ge 10) { "WARNING" } else { "FAIL" }
    UptimeDays        = $uptimeDays
    UptimeStatus      = if ($uptimeDays -le 14) { "PASS" } elseif ($uptimeDays -le 30) { "WARNING" } else { "FAIL" }
    InternetConnected = $internetTest
    InternetStatus    = if ($internetTest) { "PASS" } else { "FAIL" }
}

$healthResults | Format-List

Write-Log -Message "System health check completed for $env:COMPUTERNAME" -LogFile $logFile