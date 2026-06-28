function Get-BEMemoryInfo {
    $computer = Get-CimInstance Win32_ComputerSystem
    $os = Get-CimInstance Win32_OperatingSystem
    $memoryModules = Get-CimInstance Win32_PhysicalMemory

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
        MemoryType         = ($memoryModules | Select-Object -First 1).SMBIOSMemoryType
        SpeedMHz           = ($memoryModules | Select-Object -First 1).Speed
    }
}

Export-ModuleMember -Function Get-BEMemoryInfo
