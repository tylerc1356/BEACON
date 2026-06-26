function Write-Log {

    param(
        [string]$Message,
        [string]$LogFile
    )

    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    "$time - $Message" | Add-Content -Path $LogFile
}

Export-ModuleMember -Function Write-Log

