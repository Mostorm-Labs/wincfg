# Registry.ps1 - Registry read/write helpers
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

function Test-RegDefinition {
    param(
        [string] $Path,
        [string] $Name,
        $Value,
        [Microsoft.Win32.RegistryValueKind] $Type = [Microsoft.Win32.RegistryValueKind]::DWord
    )

    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    if ([string]::IsNullOrWhiteSpace($Name)) { return $false }
    if ($null -eq $Value) { return $false }
    if (-not [System.Enum]::IsDefined([Microsoft.Win32.RegistryValueKind], $Type)) { return $false }

    return $true
}

function Get-RegFailureCategory {
    param(
        [Parameter(Mandatory)]
        [System.Exception] $Exception,
        [string] $Path,
        [string] $Name,
        $Value,
        [Microsoft.Win32.RegistryValueKind] $Type = [Microsoft.Win32.RegistryValueKind]::DWord
    )

    if (-not (Test-RegDefinition -Path $Path -Name $Name -Value $Value -Type $Type)) {
        return 'invalid registry definition'
    }

    if (
        $Exception -is [System.UnauthorizedAccessException] -or
        $Exception.Message -match '(?i)access.+denied|unauthorized'
    ) {
        return 'access denied / unauthorized operation'
    }

    if (
        $Exception -is [System.NotSupportedException] -or
        $Exception -is [System.Management.Automation.PSNotSupportedException]
    ) {
        return 'unsupported registry path/value for current OS'
    }

    if (
        $Exception -is [System.Management.Automation.ItemNotFoundException] -or
        $Exception.Message -match '(?i)cannot find path|cannot find|does not exist'
    ) {
        return 'missing registry key/value'
    }

    if (
        $Exception -is [System.ArgumentException] -or
        $Exception -is [System.Management.Automation.ParameterBindingException] -or
        $Exception -is [System.Management.Automation.ParameterBindingValidationException]
    ) {
        return 'invalid registry definition'
    }

    return 'invalid registry definition'
}

function New-RegFailureMessage {
    param(
        [string] $Category,
        [string] $Path,
        [string] $Name,
        $IntendedValue,
        $PriorValue,
        [System.Exception] $Exception
    )

    return "Registry write failed ($Category): path='$Path' name='$Name' intended='$IntendedValue' prior='$PriorValue'. $($Exception.Message)"
}

function Format-RegLogValue {
    param($Value)

    if ($null -eq $Value) {
        return '<absent>'
    }

    return [string] $Value
}

function Test-RegUnauthorizedFailure {
    param(
        [Parameter(Mandatory)]
        [System.Exception] $Exception
    )

    return (
        $Exception -is [System.UnauthorizedAccessException] -or
        $Exception.Message -match 'access denied / unauthorized operation'
    )
}

function Set-RegValue {
    param(
        [string] $Path,
        [string] $Name,
        $Value,
        [Microsoft.Win32.RegistryValueKind] $Type = [Microsoft.Win32.RegistryValueKind]::DWord,
        [string] $Module = 'Registry',
        [switch] $DryRun
    )

    if (-not (Test-RegDefinition -Path $Path -Name $Name -Value $Value -Type $Type)) {
        $category = 'invalid registry definition'
        $message = "Registry write failed ($category): path='$Path' name='$Name' intended='$(Format-RegLogValue -Value $Value)' prior='<absent>'. Path, Name, Value, and Type are required."
        Write-Log -Level ERROR -Module $Module -Message $message
        throw [System.InvalidOperationException]::new($message)
    }

    $current = Get-RegValue -Path $Path -Name $Name
    $priorDisplay = Format-RegLogValue -Value $current
    $intendedDisplay = Format-RegLogValue -Value $Value

    if ($DryRun) {
        Write-Log -Level DRY -Module $Module -Message "Would set path='$Path' name='$Name' intended='$intendedDisplay' prior='$priorDisplay'"
        return
    }

    Save-Snapshot -Module $Module -Key "$Path\$Name" -CurrentValue $current

    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
            Write-Log -Level INFO -Module $Module -Message "Created registry key path='$Path'"
        }

        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction Stop | Out-Null
        Write-Log -Level INFO -Module $Module -Message "Set path='$Path' name='$Name' intended='$intendedDisplay' prior='$priorDisplay'"
    } catch {
        $category = Get-RegFailureCategory -Exception $_.Exception -Path $Path -Name $Name -Value $Value -Type $Type
        $message = New-RegFailureMessage -Category $category -Path $Path -Name $Name -IntendedValue $intendedDisplay -PriorValue $priorDisplay -Exception $_.Exception
        Write-Log -Level ERROR -Module $Module -Message $message
        throw [System.InvalidOperationException]::new($message, $_.Exception)
    }
}

function Set-OptionalRegValue {
    param(
        [string] $Path,
        [string] $Name,
        $Value,
        [Microsoft.Win32.RegistryValueKind] $Type = [Microsoft.Win32.RegistryValueKind]::DWord,
        [string] $Module = 'Registry',
        [switch] $DryRun,
        [string] $WarningPrefix = 'Skipping optional setting',
        [switch] $SkipOnUnauthorized
    )

    try {
        Set-RegValue -Path $Path -Name $Name -Value $Value -Type $Type -Module $Module -DryRun:$DryRun
    } catch {
        $innerException = if ($_.Exception.InnerException) { $_.Exception.InnerException } else { $_.Exception }

        if ($SkipOnUnauthorized -and (Test-RegUnauthorizedFailure -Exception $innerException)) {
            Write-Log -Level WARN -Module $Module -Message "$WarningPrefix path='$Path' name='$Name' intended='$(Format-RegLogValue -Value $Value)'. Direct registry write was rejected by the OS."
            return
        }

        throw
    }
}

function Set-ApplicableOptionalRegValue {
    param(
        [string] $Path,
        [string] $Name,
        $Value,
        [Microsoft.Win32.RegistryValueKind] $Type = [Microsoft.Win32.RegistryValueKind]::DWord,
        [string] $Module = 'Registry',
        [switch] $DryRun,
        [switch] $Applicable = $true,
        [string] $UnsupportedWarningPrefix = 'Skipping unsupported optional setting',
        [string] $WarningPrefix = 'Skipping optional setting',
        [switch] $SkipOnUnauthorized
    )

    if (-not $Applicable) {
        Write-Log -Level WARN -Module $Module -Message "$UnsupportedWarningPrefix path='$Path' name='$Name' intended='$(Format-RegLogValue -Value $Value)'"
        return
    }

    Set-OptionalRegValue -Path $Path -Name $Name -Value $Value -Type $Type -Module $Module -DryRun:$DryRun -WarningPrefix $WarningPrefix -SkipOnUnauthorized:$SkipOnUnauthorized
}
