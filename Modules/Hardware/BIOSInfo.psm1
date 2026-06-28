function Get-BEBIOSInfo {
    $bios = Get-CimInstance Win32_BIOS
    $baseboard = Get-CimInstance Win32_BaseBoard
    $computerSystemProduct = Get-CimInstance Win32_ComputerSystemProduct

    [PSCustomObject]@{
        BIOSManufacturer        = $bios.Manufacturer
        BIOSVersion             = $bios.SMBIOSBIOSVersion
        BIOSSerialNumber        = $bios.SerialNumber
        BIOSReleaseDate         = $bios.ReleaseDate
        MotherboardManufacturer = $baseboard.Manufacturer
        MotherboardProduct      = $baseboard.Product
        MotherboardVersion      = $baseboard.Version
        SystemUUID              = $computerSystemProduct.UUID
    }
}

Export-ModuleMember -Function Get-BEBIOSInfo
