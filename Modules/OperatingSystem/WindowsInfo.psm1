function Get-BEWindowsInfo {
    $os = Get-CimInstance Win32_OperatingSystem

    [PSCustomObject]@{
        Caption        = $os.Caption
        Version        = $os.Version
        BuildNumber    = $os.BuildNumber
        Architecture   = $os.OSArchitecture
        InstallDate    = $os.InstallDate
        LastBootTime   = $os.LastBootUpTime
        UptimeDays     = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalDays, 2)
        ComputerName   = $env:COMPUTERNAME
        CurrentUser    = $env:USERNAME
        PowerShell     = $PSVersionTable.PSVersion.ToString()
    }
}

Export-ModuleMember -Function Get-BEWindowsInfo
