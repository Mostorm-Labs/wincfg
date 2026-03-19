# Registry.ps1 — Registry read/write helpers
# Depends on: Logger.ps1, Snapshot.ps1

function Get-RegValue {
    param(
        [string] $Path,
        [string] $Name
    )
    try {
        $val = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
        return $val.$Name
    } catch {
        return $null
    }
}

function Set-RegValue {
    param(
        [string] $Path,
        [string] $Name,
        $Value,
        [Microsoft.Win32.RegistryValueKind] $Type = [Microsoft.Win32.RegistryValueKind]::DWord,
        [string] $Module = "Registry",
        [switch] $DryRun
    )
    $current = Get-RegValue -Path $Path -Name $Name

    if ($DryRun) {
        Write-Log -Level DRY -Module $Module -Message "Would set $Path\$Name = $Value (current: $current)"
        return
    }

    # Save snapshot before first change
    Save-Snapshot -Module $Module -Key "$Path\$Name" -CurrentValue $current

    # Ensure key exists
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
        Write-Log -Level INFO -Module $Module -Message "Created registry key $Path"
    }

    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
    Write-Log -Level INFO -Module $Module -Message "Set $Path\$Name = $Value (was: $current)"
}
