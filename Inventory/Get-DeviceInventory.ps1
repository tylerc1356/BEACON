$ToolkitRoot = Split-Path $PSScriptRoot -Parent

Import-Module (Join-Path $ToolkitRoot "Modules\Logging.psm1") -Force

$ErrorActionPreference = "Stop"

$outputFolder = Join-Path $ToolkitRoot "Reports"
$logFolder = Join-Path $ToolkitRoot "Logs"
$logFile = "$logFolder\Inventory.log"

if (-not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
}

if (-not (Test-Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
}

Write-Log -Message "Inventory started for $env:COMPUTERNAME" -LogFile $logFile

$computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
$bios = Get-CimInstance -ClassName Win32_BIOS
$operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem
$disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"

$network = Get-NetIPConfiguration |
    Where-Object { $_.IPv4DefaultGateway -ne $null } |
    Select-Object -First 1

$ipv4 = Get-NetIPAddress -InterfaceIndex $network.InterfaceIndex -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notlike "169.254*" -and $_.IPAddress -ne "127.0.0.1" } |
    Select-Object -First 1 -ExpandProperty IPAddress

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$inventoryRecord = [PSCustomObject]@{
    CollectionDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    ComputerName = $env:COMPUTERNAME
    Manufacturer = $computerSystem.Manufacturer
    Model = $computerSystem.Model
    SerialNumber = $bios.SerialNumber
    BIOSVersion = $bios.SMBIOSBIOSVersion
    LoggedInUser = $computerSystem.UserName
    DomainOrWorkgroup = $computerSystem.Domain
    WindowsEdition = $operatingSystem.Caption
    WindowsVersion = $operatingSystem.Version
    WindowsBuild = $operatingSystem.BuildNumber
    LastBootTime = $operatingSystem.LastBootUpTime
    RAM_GB = [math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)
    SystemDriveSize_GB = [math]::Round($disk.Size / 1GB, 2)
    SystemDriveFree_GB = [math]::Round($disk.FreeSpace / 1GB, 2)
    NetworkAdapter = $network.InterfaceAlias
    IPv4Address = $ipv4
    MACAddress = $network.NetAdapter.MacAddress
}

$outputFile = "$outputFolder\$env:COMPUTERNAME-Inventory-$timestamp.csv"

$inventoryRecord | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
$inventoryRecord | Format-List

Write-Log -Message "Inventory completed successfully for $env:COMPUTERNAME" -LogFile $logFile
Write-Log -Message "CSV saved to $outputFile" -LogFile $logFile

Write-Host ""
Write-Host "Inventory completed successfully." -ForegroundColor Green
Write-Host "CSV saved to: $outputFile" -ForegroundColor Cyan