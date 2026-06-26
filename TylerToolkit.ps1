$ToolkitRoot = $PSScriptRoot

Import-Module (Join-Path $ToolkitRoot "Modules\Banner.psm1") -Force
Import-Module (Join-Path $ToolkitRoot "Modules\Menu.psm1") -Force
do {
    
    Show-Banner

    Write-Host "1. Run Device Inventory"
    Write-Host "2. Open Reports Folder"
    Write-Host "3. Open Logs Folder"
    Write-Host "4. Exit"
    Write-Host ""

    $choice = Read-Host "Select an option"

    switch ($choice) {
        "1" {
            & (Join-Path $ToolkitRoot "Inventory\Get-DeviceInventory.ps1")
            Write-Host ""
            Pause
        }
        "2" {
            explorer (Join-Path $ToolkitRoot "Reports")
        }
        "3" {
            explorer (Join-Path $ToolkitRoot "Logs")
        }
        "4" {
            Write-Host "Exiting Tyler Toolkit." -ForegroundColor Yellow
        }
        default {
            Write-Host "Invalid selection." -ForegroundColor Red
            Pause
        }
    }

} while ($choice -ne "5")