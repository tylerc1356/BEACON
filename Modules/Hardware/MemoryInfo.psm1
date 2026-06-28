function Get-BEMemoryInfo {
    $computer = Get-CimInstance Win32_ComputerSystem
    $os = Get-CimInstance Win32_OperatingSystem
    $memoryModules = @(Get-CimInstance Win32_PhysicalMemory)
    $firstModule = $memoryModules | Select-Object -First 1

    $totalMemoryGB = [math]::Round($computer.TotalPhysicalMemory / 1GB, 2)
    $freeMemoryGB = [math]::Round(($os.FreePhysicalMemory * 1KB) / 1GB, 2)
    $usedMemoryGB = [math]::Round($totalMemoryGB - $freeMemoryGB, 2)
    $memoryUsedPercent = [math]::Round(($usedMemoryGB / $totalMemoryGB) * 100, 2)

    [PSCustomObject]@{
        TotalMemoryGB      = $totalMemoryGB
        UsedMemoryGB       = $usedMemoryGB
        FreeMemoryGB       = $freeMemoryGB
        MemoryUsedPercent  = $memoryUsedPercent
        SlotCount          = $memoryModules.Count
        MemoryType         = if ($firstModule.SMBIOSMemoryType) { $firstModule.SMBIOSMemoryType } else { "Unavailable" }
        SpeedMHz           = if ($firstModule.Speed) { $firstModule.Speed } else { "Unavailable" }
    }
}

Export-ModuleMember -Function Get-BEMemoryInfo
