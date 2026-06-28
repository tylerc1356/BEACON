function Show-Banner {

    param(
        [string]$Title = "BEACON",
        [string]$Subtitle = "System Insight & Diagnostics",
        [string]$Version = "1.5.0"
    )

    Clear-Host

    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host ("  $Title") -ForegroundColor Green
    Write-Host ("  $Subtitle") -ForegroundColor Yellow
    Write-Host ("  Version $Version") -ForegroundColor DarkGray
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host ""
}

Export-ModuleMember -Function Show-Banner
