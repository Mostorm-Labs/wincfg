# WindowsRestore.ps1 - Restore availability control
# Depends on: Logger.ps1

function Get-WindowsRestoreAvailabilityState {
    try {
        $output = reagentc /info | Out-String
    } catch {
        return $null
    }

    if ($output -match '(?i)Windows RE status\s*:\s*Enabled' -or $output -match 'Windows RE.*启用') {
        return 'enabled'
    }

    if ($output -match '(?i)Windows RE status\s*:\s*Disabled' -or $output -match 'Windows RE.*禁用') {
        return 'disabled'
    }

    return $null
}

function Invoke-WindowsRestoreCommand {
    param(
        [Parameter(Mandatory)]
        [string] $Command,
        [switch] $DryRun
    )

    $module = 'WindowsRestore'

    if ($DryRun) {
        Write-Log -Level DRY -Module $module -Message "Would execute command='$Command'"
        return
    }

    $commandParts = $Command -split ' '
    & $commandParts[0] $commandParts[1] | Out-Null

    if ($LASTEXITCODE -ne 0) {
        $message = "Command failed: '$Command' exit_code='$LASTEXITCODE'"
        Write-Log -Level ERROR -Module $module -Message $message
        throw [System.InvalidOperationException]::new($message)
    }

    Write-Log -Level INFO -Module $module -Message "Executed command='$Command'"
}

function Invoke-WindowsRestoreDisable {
    param([switch] $DryRun)

    $module = 'WindowsRestore'
    $state = if ($DryRun) { $null } else { Get-WindowsRestoreAvailabilityState }

    if ($state -eq 'disabled') {
        Write-Log -Level INFO -Module $module -Message "Skipping command='reagentc /disable' because restore availability is already disabled"
        return
    }

    Invoke-WindowsRestoreCommand -Command 'reagentc /disable' -DryRun:$DryRun
}

function Invoke-WindowsRestoreEnable {
    param([switch] $DryRun)

    $module = 'WindowsRestore'
    $state = if ($DryRun) { $null } else { Get-WindowsRestoreAvailabilityState }

    if ($state -eq 'enabled') {
        Write-Log -Level INFO -Module $module -Message "Skipping command='reagentc /enable' because restore availability is already enabled"
        return
    }

    Invoke-WindowsRestoreCommand -Command 'reagentc /enable' -DryRun:$DryRun
}

function Invoke-WindowsRestore {
    param(
        [switch] $DryRun,
        [switch] $Enable
    )

    $module = 'WindowsRestore'

    Write-Log -Level INFO -Module $module -Message '=== Starting WindowsRestore module ==='

    if ($Enable) {
        Invoke-WindowsRestoreEnable -DryRun:$DryRun
    } else {
        Invoke-WindowsRestoreDisable -DryRun:$DryRun
    }

    Write-Log -Level INFO -Module $module -Message '=== WindowsRestore module complete ==='
}
