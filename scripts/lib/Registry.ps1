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

function New-RegSettingDescriptor {
    param(
        [Parameter(Mandatory)]
        [string] $Name,
        [Parameter(Mandatory)]
        [string] $Path,
        [Parameter(Mandatory)]
        $Value,
        [Microsoft.Win32.RegistryValueKind] $Type = [Microsoft.Win32.RegistryValueKind]::DWord,
        [bool] $Required = $true,
        [string] $Category = 'stable_user_preference',
        $MinBuild = $null,
        $MaxBuild = $null,
        [bool] $SkipOnUnauthorized = $false,
        [string] $UnsupportedWarningPrefix = 'Skipping unsupported optional setting',
        [string] $WarningPrefix = 'Skipping optional setting',
        [hashtable] $Profiles = @{}
    )

    return [PSCustomObject]@{
        Name                     = $Name
        Path                     = $Path
        Value                    = $Value
        Type                     = $Type
        Required                 = $Required
        Category                 = $Category
        MinBuild                 = $MinBuild
        MaxBuild                 = $MaxBuild
        SkipOnUnauthorized       = $SkipOnUnauthorized
        UnsupportedWarningPrefix = $UnsupportedWarningPrefix
        WarningPrefix            = $WarningPrefix
        Profiles                 = $Profiles
    }
}

function New-RegProfileAction {
    param(
        [ValidateSet('set', 'remove')]
        [string] $Action,
        $Value = $null,
        [Microsoft.Win32.RegistryValueKind] $Type = [Microsoft.Win32.RegistryValueKind]::DWord
    )

    return [PSCustomObject]@{
        Action = $Action
        Value  = $Value
        Type   = $Type
    }
}

function Test-RegSettingDescriptor {
    param(
        [Parameter(Mandatory)]
        $Descriptor
    )

    $validCategories = @(
        'required_policy_backed',
        'stable_user_preference',
        'optional_os_dependent',
        'os_protected_optional'
    )

    if ($null -eq $Descriptor) { return $false }
    if (-not (Test-RegDefinition -Path $Descriptor.Path -Name $Descriptor.Name -Value $Descriptor.Value -Type $Descriptor.Type)) { return $false }
    if ($Descriptor.Category -notin $validCategories) { return $false }
    if ($null -ne $Descriptor.MinBuild -and $Descriptor.MinBuild -isnot [int]) { return $false }
    if ($null -ne $Descriptor.MaxBuild -and $Descriptor.MaxBuild -isnot [int]) { return $false }
    if ($null -eq $Descriptor.Profiles) { return $false }

    foreach ($profileName in $Descriptor.Profiles.Keys) {
        $profile = $Descriptor.Profiles[$profileName]
        if ([string]::IsNullOrWhiteSpace([string]$profileName)) { return $false }
        if ($null -eq $profile) { return $false }
        if ($profile.Action -notin @('set', 'remove')) { return $false }
        if ($profile.Action -eq 'set' -and -not (Test-RegDefinition -Path $Descriptor.Path -Name $Descriptor.Name -Value $profile.Value -Type $profile.Type)) { return $false }
    }

    return $true
}

function Test-RegSettingApplicable {
    param(
        [Parameter(Mandatory)]
        $Descriptor,
        [int] $Build = 0
    )

    if (-not (Test-RegSettingDescriptor -Descriptor $Descriptor)) {
        return $false
    }

    if ($Descriptor.MinBuild -ne $null -and $Build -lt $Descriptor.MinBuild) {
        return $false
    }

    if ($Descriptor.MaxBuild -ne $null -and $Build -gt $Descriptor.MaxBuild) {
        return $false
    }

    return $true
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

function Remove-RegValue {
    param(
        [string] $Path,
        [string] $Name,
        [string] $Module = 'Registry',
        [switch] $DryRun
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or [string]::IsNullOrWhiteSpace($Name)) {
        $message = "Registry remove failed (invalid registry definition): path='$Path' name='$Name'. Path and Name are required."
        Write-Log -Level ERROR -Module $Module -Message $message
        throw [System.InvalidOperationException]::new($message)
    }

    $current = Get-RegValue -Path $Path -Name $Name
    $priorDisplay = Format-RegLogValue -Value $current

    if ($DryRun) {
        Write-Log -Level DRY -Module $Module -Message "Would remove path='$Path' name='$Name' prior='$priorDisplay'"
        return
    }

    Save-Snapshot -Module $Module -Key "$Path\$Name" -CurrentValue $current

    if (-not (Test-Path $Path) -or $null -eq $current) {
        Write-Log -Level INFO -Module $Module -Message "Remove skipped path='$Path' name='$Name' prior='$priorDisplay'"
        return
    }

    try {
        Remove-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
        Write-Log -Level INFO -Module $Module -Message "Removed path='$Path' name='$Name' prior='$priorDisplay'"
    } catch {
        $category = Get-RegFailureCategory -Exception $_.Exception -Path $Path -Name $Name -Value 0 -Type ([Microsoft.Win32.RegistryValueKind]::DWord)
        $message = "Registry remove failed ($category): path='$Path' name='$Name' prior='$priorDisplay'. $($_.Exception.Message)"
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

function Invoke-RegSettingDescriptor {
    param(
        [Parameter(Mandatory)]
        $Descriptor,
        [string] $Module = 'Registry',
        [switch] $DryRun,
        [int] $Build = 0
    )

    if (-not (Test-RegSettingDescriptor -Descriptor $Descriptor)) {
        $message = "Invalid registry setting descriptor for name='$($Descriptor.Name)' path='$($Descriptor.Path)'"
        Write-Log -Level ERROR -Module $Module -Message $message
        throw [System.InvalidOperationException]::new($message)
    }

    $applicable = Test-RegSettingApplicable -Descriptor $Descriptor -Build $Build

    if ($Descriptor.Required) {
        if (-not $applicable) {
            $message = "Required setting is not applicable on this build: path='$($Descriptor.Path)' name='$($Descriptor.Name)' build='$Build'"
            Write-Log -Level ERROR -Module $Module -Message $message
            throw [System.InvalidOperationException]::new($message)
        }

        Set-RegValue -Path $Descriptor.Path -Name $Descriptor.Name -Value $Descriptor.Value -Type $Descriptor.Type -Module $Module -DryRun:$DryRun
        return
    }

    Set-ApplicableOptionalRegValue -Path $Descriptor.Path -Name $Descriptor.Name -Value $Descriptor.Value -Type $Descriptor.Type -Module $Module -DryRun:$DryRun `
        -Applicable:$applicable `
        -UnsupportedWarningPrefix $Descriptor.UnsupportedWarningPrefix `
        -WarningPrefix $Descriptor.WarningPrefix `
        -SkipOnUnauthorized:$Descriptor.SkipOnUnauthorized
}

function Invoke-RegSettingProfile {
    param(
        [Parameter(Mandatory)]
        $Descriptor,
        [Parameter(Mandatory)]
        [string] $ProfileName,
        [string] $Module = 'Registry',
        [switch] $DryRun
    )

    if (-not (Test-RegSettingDescriptor -Descriptor $Descriptor)) {
        $message = "Invalid registry setting descriptor for name='$($Descriptor.Name)' path='$($Descriptor.Path)'"
        Write-Log -Level ERROR -Module $Module -Message $message
        throw [System.InvalidOperationException]::new($message)
    }

    if (-not $Descriptor.Profiles.ContainsKey($ProfileName)) {
        $message = "Restore profile '$ProfileName' is not defined for path='$($Descriptor.Path)' name='$($Descriptor.Name)'"
        Write-Log -Level ERROR -Module $Module -Message $message
        throw [System.InvalidOperationException]::new($message)
    }

    $profile = $Descriptor.Profiles[$ProfileName]

    if ($profile.Action -eq 'remove') {
        Remove-RegValue -Path $Descriptor.Path -Name $Descriptor.Name -Module $Module -DryRun:$DryRun
        return
    }

    Set-RegValue -Path $Descriptor.Path -Name $Descriptor.Name -Value $profile.Value -Type $profile.Type -Module $Module -DryRun:$DryRun
}
