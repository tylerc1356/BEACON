function Get-BEEventLogInfo {
    $eventStartTime = (Get-Date).AddHours(-24)

    $criticalEvents = Get-WinEvent -FilterHashtable @{
        LogName   = "System"
        Level     = 1
        StartTime = $eventStartTime
    } -ErrorAction SilentlyContinue

    $errorEvents = Get-WinEvent -FilterHashtable @{
        LogName   = "System"
        Level     = 2
        StartTime = $eventStartTime
    } -ErrorAction SilentlyContinue

    $recentProblemEvents = Get-WinEvent -FilterHashtable @{
        LogName   = "System"
        Level     = 1,2
        StartTime = $eventStartTime
    } -ErrorAction SilentlyContinue |
    Select-Object -First 10 TimeCreated, ProviderName, Id, LevelDisplayName, Message

    [PSCustomObject]@{
        TimeWindowHours     = 24
        CriticalEventCount  = if ($criticalEvents) { $criticalEvents.Count } else { 0 }
        ErrorEventCount     = if ($errorEvents) { $errorEvents.Count } else { 0 }
        RecentProblemEvents = $recentProblemEvents
    }
}

Export-ModuleMember -Function Get-BEEventLogInfo
