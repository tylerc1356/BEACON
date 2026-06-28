function Get-BEUpdateInfo {
    $hotfixes = Get-HotFix |
        Sort-Object InstalledOn -Descending

    $latestHotfix = $hotfixes | Select-Object -First 1

    [PSCustomObject]@{
        LatestHotFixID      = if ($latestHotfix) { $latestHotfix.HotFixID } else { "Unavailable" }
        LatestDescription   = if ($latestHotfix) { $latestHotfix.Description } else { "Unavailable" }
        LatestInstalledOn   = if ($latestHotfix) { $latestHotfix.InstalledOn } else { "Unavailable" }
        LatestInstalledBy   = if ($latestHotfix) { $latestHotfix.InstalledBy } else { "Unavailable" }
        RecentHotFixes      = $hotfixes | Select-Object -First 5
    }
}

Export-ModuleMember -Function Get-BEUpdateInfo
