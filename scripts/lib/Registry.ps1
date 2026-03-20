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
        [string] $Name
    )

    return -not [string]::IsNullOrWhiteSpace($Path) -and -not [string]::IsNullOrWhiteSpace($Name)
}

function Get-RegFailureCategory {
    param(
        [Parameter(Mandatory)]
        [System.Exception] $Exception,
        [string] $Path,
        [string] $Name
    )

    if (-not (Test-RegDefinition -Path $Path -Name $Name)) {
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
        [System.Exception] $Exception
    )

    return "Registry write failed ($Category): $Path\$Name. $($Exception.Message)"
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

    if (-not (Test-RegDefinition -Path $Path -Name $Name)) {
        $category = 'invalid registry definition'
        $message = "Registry write failed ($category): $Path\$Name. Path and Name are required."
        Write-Log -Level ERROR -Module $Module -Message $message
        throw [System.InvalidOperationException]::new($message)
    }

    $current = Get-RegValue -Path $Path -Name $Name

    if ($DryRun) {
        Write-Log -Level DRY -Module $Module -Message "Would set $Path\$Name = $Value (current: $current)"
        return
    }

    Save-Snapshot -Module $Module -Key "$Path\$Name" -CurrentValue $current

    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
            Write-Log -Level INFO -Module $Module -Message "Created registry key $Path"
        }

        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction Stop | Out-Null
        Write-Log -Level INFO -Module $Module -Message "Set $Path\$Name = $Value (was: $current)"
    } catch {
        $category = Get-RegFailureCategory -Exception $_.Exception -Path $Path -Name $Name
        $message = New-RegFailureMessage -Category $category -Path $Path -Name $Name -Exception $_.Exception
        Write-Log -Level ERROR -Module $Module -Message $message
        throw [System.InvalidOperationException]::new($message, $_.Exception)
    }
}
