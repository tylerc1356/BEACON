$ToolkitRoot = $PSScriptRoot

Import-Module (Join-Path $ToolkitRoot "Modules\Banner.psm1") -Force
Import-Module (Join-Path $ToolkitRoot "Modules\Menu.psm1") -Force

do {
    Show-Banner

    Show-MainMenu

    $choice = Read-Host "Select an option"

    Invoke-MainMenuSelection -Choice $choice -ToolkitRoot $ToolkitRoot

} while ($choice -ne "7")