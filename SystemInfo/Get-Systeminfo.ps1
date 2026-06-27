$computer = Get-CimInstance Win32_ComputerSystem
$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor

$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"

$uptime = (Get-Date) - $os.LastBootUpTime

Write-Host ""
Write-Host "========== SYSTEM INFORMATION ==========" -ForegroundColor Cyan
Write-Host ""

Write-Host "Computer Name :" $env:COMPUTERNAME
Write-Host "User          :" $env:USERNAME
Write-Host "Windows       :" $os.Caption
Write-Host "PowerShell    :" $PSVersionTable.PSVersion

Write-Host ""

Write-Host "CPU           :" $cpu.Name
Write-Host "Memory        :" ("{0:N1} GB" -f ($computer.TotalPhysicalMemory /1GB))
Write-Host "Disk Free     :" ("{0:N1} GB" -f ($disk.FreeSpace/1GB))

Write-Host ""

Write-Host "Uptime        :" ("{0:N0} Days {1:N0} Hours" -f $uptime.TotalDays,$uptime.Hours)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan