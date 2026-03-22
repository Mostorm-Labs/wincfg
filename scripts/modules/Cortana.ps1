# Cortana.ps1 - Disable Cortana and web search
# Depends on: Logger.ps1, Registry.ps1, Snapshot.ps1

function Test-CortanaSettingOsProtectedOptional {
    param(
        [Parameter(Mandatory)]
        [string] $Name
    )

    switch ($Name) {
        'ShowCortanaButton' { return $true }
        default { return $false }
    }
}

function Set-OptionalCortanaRegValue {
    param(
        [Parameter(Mandatory)]
        [string] $Path,
        [Parameter(Mandatory)]
        [string] $Name,
        [Parameter(Mandatory)]
        $Value,
        [Microsoft.Win32.RegistryValueKind] $Type = [Microsoft.Win32.RegistryValueKind]::DWord,
        [Parameter(Mandatory)]
        [string] $Module,
        [switch] $DryRun
    )

    try {
        Set-RegValue -Path $Path -Name $Name -Value $Value -Type $Type -Module $Module -DryRun:$DryRun
    } catch {
        $isProtectedOptionalSetting = Test-CortanaSettingOsProtectedOptional -Name $Name
        $isUnauthorized = (
            $_.Exception.InnerException -is [System.UnauthorizedAccessException] -or
            $_.Exception.Message -match 'access denied / unauthorized operation'
        )

        if ($isProtectedOptionalSetting -and $isUnauthorized) {
            Write-Log -Level WARN -Module $Module -Message "Skipping OS-protected optional Cortana setting path='$Path' name='$Name' intended='$Value'. Direct registry write was rejected by the OS."
            return
        }

        throw
    }
}

function Invoke-Cortana {
    param([switch] $DryRun)

    $module = "Cortana"
    $cortanaPath  = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    $explorerPolicyPath = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
    $taskbarPath  = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Write-Log -Level INFO -Module $module -Message "=== Starting Cortana module ==="

    # 1. Disable Cortana via policy
    Set-RegValue -Path $cortanaPath -Name "AllowCortana" -Value 0 `
        -Module $module -DryRun:$DryRun

    # 2. Disable web search suggestions in Start
    Set-RegValue -Path $explorerPolicyPath -Name "DisableSearchBoxSuggestions" -Value 1 `
        -Module $module -DryRun:$DryRun

    # 3. Hide Cortana button on taskbar
    Set-OptionalCortanaRegValue -Path $taskbarPath -Name "ShowCortanaButton" -Value 0 `
        -Module $module -DryRun:$DryRun

    Write-Log -Level INFO -Module $module -Message "=== Cortana module complete ==="
}
