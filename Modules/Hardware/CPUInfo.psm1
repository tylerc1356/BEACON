function Get-BECPUInfo {
    $cpu = Get-CimInstance Win32_Processor

    [PSCustomObject]@{
        Name              = $cpu.Name
        Manufacturer      = $cpu.Manufacturer
        Cores             = $cpu.NumberOfCores
        LogicalProcessors = $cpu.NumberOfLogicalProcessors
        CurrentClockSpeed = $cpu.CurrentClockSpeed
        MaxClockSpeed     = $cpu.MaxClockSpeed
        LoadPercentage    = $cpu.LoadPercentage
    }
}

Export-ModuleMember -Function Get-BECPUInfo
