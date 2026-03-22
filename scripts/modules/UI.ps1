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
        'HideMeetNow' { return $Build -gt 0 -and $Build -lt 22000 }
        'ShellFeedsTaskbarViewMode' { return $Build -gt 0 -and $Build -lt 22000 }
        'TaskbarDa' { return $Build -ge 22000 }
        default { return $true }
    }
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

    Set-ApplicableOptionalRegValue -Path $advancedPath -Name 'TaskbarDa' -Value 0 -Module $module -DryRun:$DryRun `
        -Applicable:(Test-UISettingApplicable -Name 'TaskbarDa') `
        -UnsupportedWarningPrefix 'Skipping unsupported UI setting' `
        -WarningPrefix 'Skipping OS-protected optional UI setting' `
        -SkipOnUnauthorized

    Set-ApplicableOptionalRegValue -Path $feedsPath -Name 'ShellFeedsTaskbarViewMode' -Value 2 -Module $module -DryRun:$DryRun `
        -Applicable:(Test-UISettingApplicable -Name 'ShellFeedsTaskbarViewMode') `
        -UnsupportedWarningPrefix 'Skipping unsupported UI setting'

    Set-ApplicableOptionalRegValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'HideMeetNow' -Value 1 -Module $module -DryRun:$DryRun `
        -Applicable:(Test-UISettingApplicable -Name 'HideMeetNow') `
        -UnsupportedWarningPrefix 'Skipping unsupported UI setting' `
        -WarningPrefix 'Skipping OS-protected optional UI setting' `
        -SkipOnUnauthorized

    if ($AutoHideTaskbar) {
        Set-RegValue -Path $advancedPath -Name 'AutoHideTaskbar' -Value 1 -Module $module -DryRun:$DryRun
    }

    Write-Log -Level INFO -Module $module -Message '=== UI module complete ==='
}
