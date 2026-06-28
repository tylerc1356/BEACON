function Get-BEServicesInfo {
    $importantServiceNames = @(
        "wuauserv",
        "WinDefend",
        "Spooler",
        "WinRM",
        "BITS",
        "EventLog",
        "LanmanWorkstation",
        "LanmanServer"
    )

    foreach ($serviceName in $importantServiceNames) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        $serviceCim = Get-CimInstance Win32_Service -Filter "Name='$serviceName'" -ErrorAction SilentlyContinue

        if ($service) {
            [PSCustomObject]@{
                Name        = $service.Name
                DisplayName = $service.DisplayName
                Status      = $service.Status
                StartType   = if ($serviceCim) { $serviceCim.StartMode } else { "Unavailable" }
            }
        }
    }
}

Export-ModuleMember -Function Get-BEServicesInfo
