function Show-MainMenu {
    Write-Host "1. Run Device Inventory"
    Write-Host "2. Run System Health Check"
    Write-Host "3. Open Reports Folder"
    Write-Host "4. Open Logs Folder"
    Write-Host "5. Exit"
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
            explorer (Join-Path $ToolkitRoot "Reports")
        }
        "4" {
            explorer (Join-Path $ToolkitRoot "Logs")
        }
        "5" {
            Write-Host "Exiting Tyler Toolkit." -ForegroundColor Yellow
        }
        default {
            Write-Host "Invalid selection." -ForegroundColor Red
            Pause
        }
    }
}

Export-ModuleMember -Function Show-MainMenu, Invoke-MainMenuSelection