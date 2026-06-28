function Show-MainMenu {
    Write-Host "1. Run Device Inventory"
    Write-Host "2. Run System Health Check"
    Write-Host "3. View System Information"
    Write-Host "4. Generate Full Report"
    Write-Host "5. Open Reports Folder"
    Write-Host "6. Open Logs Folder"
    Write-Host "7. Exit"
    Write-Host ""
}

function Invoke-MainMenuSelection {
    param(
        [string]$Choice,
        [string]$ToolkitRoot
    )

    switch ($Choice) {
        "1" {
            & (Join-Path $ToolkitRoot "Inventory\Get-DeviceInventory.ps1")
            Write-Host ""
            Pause
        }
        "2" {
            & (Join-Path $ToolkitRoot "Health\Get-SystemHealth.ps1")
            Write-Host ""
            Pause
        }
        "3" {
            & (Join-Path $ToolkitRoot "SystemInfo\Get-SystemInfo.ps1")
            Write-Host ""
            Pause
        }
        "4" {
            & (Join-Path $ToolkitRoot "Reporting\New-FullReport.ps1")
            Write-Host ""
            Pause
        }
        "5" {
            explorer (Join-Path $ToolkitRoot "Reports")
        }
        "6" {
            explorer (Join-Path $ToolkitRoot "Logs")
        }
        "7" {
            Write-Host "Exiting BEACON." -ForegroundColor Yellow
        }
        default {
            Write-Host "Invalid selection." -ForegroundColor Red
            Pause
        }
    }
}

Export-ModuleMember -Function Show-MainMenu, Invoke-MainMenuSelection