function Get-BEStorageInfo {
    $drives = Get-CimInstance Win32_LogicalDisk |
        Where-Object { $_.DriveType -eq 3 }

    foreach ($drive in $drives) {
        $totalGB = [math]::Round($drive.Size / 1GB, 2)
        $freeGB = [math]::Round($drive.FreeSpace / 1GB, 2)
        $usedGB = [math]::Round($totalGB - $freeGB, 2)
        $freePercent = [math]::Round(($drive.FreeSpace / $drive.Size) * 100, 2)

        [PSCustomObject]@{
            DriveLetter = $drive.DeviceID
            VolumeName  = $drive.VolumeName
            FileSystem  = $drive.FileSystem
            TotalGB     = $totalGB
            UsedGB      = $usedGB
            FreeGB      = $freeGB
            FreePercent = $freePercent
        }
    }
}

Export-ModuleMember -Function Get-BEStorageInfo
