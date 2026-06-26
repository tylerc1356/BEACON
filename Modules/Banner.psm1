function Show-Banner {

    param(
        [string]$Title = "Tyler Toolkit",
        [string]$Subtitle = "Windows IT Utility",
        [string]$Version = "1.3.0"
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
