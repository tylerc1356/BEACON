function Get-BESecurityInfo {
    $firewallProfiles = Get-NetFirewallProfile

    $defenderStatus = try {
        Get-MpComputerStatus -ErrorAction Stop
    }
    catch {
        $null
    }

    $bitLockerStatus = try {
        Get-BitLockerVolume -MountPoint "C:" -ErrorAction Stop
    }
    catch {
        $null
    }

    $secureBootStatus = try {
        Confirm-SecureBootUEFI -ErrorAction Stop
    }
    catch {
        "Unsupported or unavailable"
    }

    [PSCustomObject]@{
        DefenderEnabled              = if ($defenderStatus) { $defenderStatus.AntivirusEnabled } else { "Unavailable" }
        RealTimeProtectionEnabled    = if ($defenderStatus) { $defenderStatus.RealTimeProtectionEnabled } else { "Unavailable" }
        DefenderSignatureVersion     = if ($defenderStatus) { $defenderStatus.AntivirusSignatureVersion } else { "Unavailable" }
        SecureBoot                   = $secureBootStatus
        BitLockerC                   = if ($bitLockerStatus) { $bitLockerStatus.ProtectionStatus } else { "Unavailable" }
        DomainFirewallEnabled        = ($firewallProfiles | Where-Object Name -eq "Domain").Enabled
        PrivateFirewallEnabled       = ($firewallProfiles | Where-Object Name -eq "Private").Enabled
        PublicFirewallEnabled        = ($firewallProfiles | Where-Object Name -eq "Public").Enabled
    }
}

Export-ModuleMember -Function Get-BESecurityInfo
