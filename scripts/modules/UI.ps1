# UI.ps1 - Taskbar and shell UI cleanup
# Depends on: Logger.ps1, Registry.ps1, Snapshot.ps1

function Get-WindowsBuildNumber {
    return [System.Environment]::OSVersion.Version.Build
}

function Test-UISettingApplicable {
    param(
        [Parameter(Mandatory)]
        [string] $Name,
        [int] $Build = (Get-WindowsBuildNumber)
    )

    switch ($Name) {
        'ShellFeedsTaskbarViewMode' { return $Build -gt 0 -and $Build -lt 22000 }
        'TaskbarDa' { return $Build -ge 22000 }
        default { return $true }
    }
}

function Set-OptionalUIRegValue {
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

    if (-not (Test-UISettingApplicable -Name $Name)) {
        Write-Log -Level WARN -Module $Module -Message "Skipping unsupported UI setting path='$Path' name='$Name' intended='$Value'"
        return
    }

    Set-RegValue -Path $Path -Name $Name -Value $Value -Type $Type -Module $Module -DryRun:$DryRun
}

function Invoke-UI {
    param(
        [switch] $DryRun,
        [switch] $AutoHideTaskbar
    )

    $module          = 'UI'
    $advancedPath    = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    $feedsPath       = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds'
    $policyFeedsPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds'

    Write-Log -Level INFO -Module $module -Message '=== Starting UI module ==='

    Set-RegValue -Path $advancedPath -Name 'ShowTaskViewButton' -Value 0 -Module $module -DryRun:$DryRun
    Set-RegValue -Path $policyFeedsPath -Name 'EnableFeeds' -Value 0 -Module $module -DryRun:$DryRun

    Set-OptionalUIRegValue -Path $advancedPath -Name 'TaskbarDa' -Value 0 -Module $module -DryRun:$DryRun
    Set-OptionalUIRegValue -Path $feedsPath -Name 'ShellFeedsTaskbarViewMode' -Value 2 -Module $module -DryRun:$DryRun

    Set-RegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'HideMeetNow' -Value 1 -Module $module -DryRun:$DryRun

    if ($AutoHideTaskbar) {
        Set-RegValue -Path $advancedPath -Name 'AutoHideTaskbar' -Value 1 -Module $module -DryRun:$DryRun
    }

    Write-Log -Level INFO -Module $module -Message '=== UI module complete ==='
}
