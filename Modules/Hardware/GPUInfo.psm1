function Get-BEGPUInfo {
    $gpus = Get-CimInstance Win32_VideoController

    foreach ($gpu in $gpus) {
        [PSCustomObject]@{
            Name           = $gpu.Name
            DriverVersion  = $gpu.DriverVersion
            DriverDate     = $gpu.DriverDate
            VideoProcessor = $gpu.VideoProcessor
            AdapterRAMGB   = if ($gpu.AdapterRAM) { [math]::Round($gpu.AdapterRAM / 1GB, 2) } else { "N/A" }
        }
    }
}

Export-ModuleMember -Function Get-BEGPUInfo
