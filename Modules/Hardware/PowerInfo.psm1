function Get-BEPowerInfo {
    $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue

    $powerPlan = try {
        powercfg /getactivescheme 2>$null
    }
    catch {
        "Unavailable"
    }

    [PSCustomObject]@{
        ActivePowerPlan          = $powerPlan
        BatteryPresent           = if ($battery) { $true } else { $false }
        BatteryStatus            = if ($battery) { $battery.BatteryStatus } else { "N/A" }
        EstimatedChargeRemaining = if ($battery) { $battery.EstimatedChargeRemaining } else { "N/A" }
        EstimatedRuntimeMinutes  = if ($battery) { $battery.EstimatedRunTime } else { "N/A" }
    }
}

Export-ModuleMember -Function Get-BEPowerInfo
