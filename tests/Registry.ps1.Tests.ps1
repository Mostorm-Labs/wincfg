#Requires -Modules Pester

Describe 'Registry.ps1 Issue #1 behavior' {
    BeforeEach {
        . "$PSScriptRoot\..\scripts\lib\Logger.ps1"
        . "$PSScriptRoot\..\scripts\lib\Snapshot.ps1"
        . "$PSScriptRoot\..\scripts\lib\Registry.ps1"

        $script:BasePath = 'HKCU:\SOFTWARE\WinConfIssue1Tests'
        $script:KeyPath = Join-Path $script:BasePath ([guid]::NewGuid().ToString())
        $script:LogPath = Join-Path $env:TEMP ("winconf-registry-test-{0}.log" -f ([guid]::NewGuid()))
        $script:SnapshotPath = Join-Path $env:TEMP ("winconf-registry-test-{0}.json" -f ([guid]::NewGuid()))

        Initialize-Logger -LogPath $script:LogPath
        Initialize-Snapshot -Path $script:SnapshotPath
    }

    AfterEach {
        Remove-Item -Path $script:KeyPath -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $script:LogPath -ErrorAction SilentlyContinue
        Remove-Item -Path $script:SnapshotPath -ErrorAction SilentlyContinue
    }

    It 'logs intended and prior values when overwriting an existing value' {
        New-Item -Path $script:KeyPath -Force | Out-Null
        New-ItemProperty -Path $script:KeyPath -Name 'Existing' -Value 3 -PropertyType DWord -Force | Out-Null

        Set-RegValue -Path $script:KeyPath -Name 'Existing' -Value 5 -Module 'Test'

        (Get-ItemProperty -Path $script:KeyPath -Name 'Existing').Existing | Should Be 5
        $log = Get-Content $script:LogPath -Raw
        $log | Should BeLike "*path='$script:KeyPath' name='Existing' intended='5' prior='3'*"
    }

    It 'logs an absent prior value cleanly when creating a missing value' {
        New-Item -Path $script:KeyPath -Force | Out-Null

        Set-RegValue -Path $script:KeyPath -Name 'MissingValue' -Value 1 -Module 'Test'

        $log = Get-Content $script:LogPath -Raw
        $log | Should BeLike "*path='$script:KeyPath' name='MissingValue' intended='1' prior='<absent>'*"
    }

    It 'creates a missing value under an existing key' {
        New-Item -Path $script:KeyPath -Force | Out-Null

        Set-RegValue -Path $script:KeyPath -Name 'MissingValue' -Value 1 -Module 'Test'

        (Get-ItemProperty -Path $script:KeyPath -Name 'MissingValue').MissingValue | Should Be 1
    }

    It 'creates a missing key and value for a valid path' {
        Set-RegValue -Path $script:KeyPath -Name 'CreatedValue' -Value 9 -Module 'Test'

        Test-Path $script:KeyPath | Should Be $true
        (Get-ItemProperty -Path $script:KeyPath -Name 'CreatedValue').CreatedValue | Should Be 9
    }

    It 'fails invalid registry definitions when Value is missing' {
        $message = $null

        try {
            Set-RegValue -Path $script:KeyPath -Name 'NullValue' -Value $null -Module 'Test'
        } catch {
            $message = $_.Exception.Message
        }

        $message | Should BeLike '*invalid registry definition*'
    }

    It 'classifies access denied separately from missing key creation' {
        $category = Get-RegFailureCategory `
            -Exception ([System.UnauthorizedAccessException]::new('Access is denied')) `
            -Path $script:KeyPath `
            -Name 'DeniedValue' `
            -Value 1

        $category | Should Be 'access denied / unauthorized operation'
    }

    It 'classifies unsupported registry paths separately' {
        $category = Get-RegFailureCategory `
            -Exception ([System.NotSupportedException]::new('This registry path is not supported')) `
            -Path $script:KeyPath `
            -Name 'UnsupportedValue' `
            -Value 1

        $category | Should Be 'unsupported registry path/value for current OS'
    }

    It 'records snapshot metadata for registry entries' {
        Set-RegValue -Path $script:KeyPath -Name 'CreatedValue' -Value 11 -Module 'Test'

        $snapshot = Get-Content -Path $script:SnapshotPath -Raw | ConvertFrom-Json
        $snapshot.Type | Should Be 'Registry'
        $snapshot.Module | Should Be 'Test'
        $snapshot.Key | Should Be "$script:KeyPath\CreatedValue"
    }

    It 'restores prior state by removing a value created under a newly created key' {
        Set-RegValue -Path $script:KeyPath -Name 'CreatedValue' -Value 11 -Module 'Test'
        Restore-Snapshot

        Test-Path $script:KeyPath | Should Be $false
    }

    It 'supports module-scoped rollback without touching unrelated snapshot entries' {
        $uiPath = Join-Path $script:BasePath ([guid]::NewGuid().ToString())
        New-Item -Path $uiPath -Force | Out-Null
        New-ItemProperty -Path $uiPath -Name 'UiValue' -Value 1 -PropertyType DWord -Force | Out-Null

        @(
            [PSCustomObject]@{
                Module    = 'WindowsUpdate'
                Key       = 'Service:wuauserv:StartType'
                Value     = 'Manual'
                Type      = 'Service'
                Timestamp = '2026-03-23 11:00:00'
            }
            [PSCustomObject]@{
                Module    = 'UI'
                Key       = "$uiPath\UiValue"
                Value     = $null
                Type      = 'Registry'
                Timestamp = '2026-03-23 11:00:01'
            }
        ) | ConvertTo-Json -Depth 5 | Set-Content -Path $script:SnapshotPath -Encoding UTF8

        { Restore-Snapshot -Module 'UI' } | Should Not Throw
        Test-Path $uiPath | Should Be $false
    }

    It 'supports module-scoped rollback when only a single snapshot entry matches' {
        $wuPath = Join-Path $script:BasePath ([guid]::NewGuid().ToString())
        New-Item -Path $wuPath -Force | Out-Null
        New-ItemProperty -Path $wuPath -Name 'UpdateValue' -Value 1 -PropertyType DWord -Force | Out-Null

        @(
            [PSCustomObject]@{
                Module    = 'WindowsUpdate'
                Key       = "$wuPath\UpdateValue"
                Value     = $null
                Type      = 'Registry'
                Timestamp = '2026-03-23 11:30:00'
            }
        ) | ConvertTo-Json -Depth 5 | Set-Content -Path $script:SnapshotPath -Encoding UTF8

        { Restore-Snapshot -Module 'WindowsUpdate' } | Should Not Throw
        Test-Path $wuPath | Should Be $false
    }

    It 'supports module-scoped rollback under strict mode when only a single snapshot entry matches' {
        $wuPath = Join-Path $script:BasePath ([guid]::NewGuid().ToString())
        New-Item -Path $wuPath -Force | Out-Null
        New-ItemProperty -Path $wuPath -Name 'UpdateValue' -Value 1 -PropertyType DWord -Force | Out-Null

        @(
            [PSCustomObject]@{
                Module    = 'WindowsUpdate'
                Key       = "$wuPath\UpdateValue"
                Value     = $null
                Type      = 'Registry'
                Timestamp = '2026-03-24 09:00:00'
            }
        ) | ConvertTo-Json -Depth 5 | Set-Content -Path $script:SnapshotPath -Encoding UTF8

        Set-StrictMode -Version Latest
        try {
            { Restore-Snapshot -Module 'WindowsUpdate' } | Should Not Throw
        } finally {
            Set-StrictMode -Off
        }

        Test-Path $wuPath | Should Be $false
    }

    It 'supports module-scoped rollback under strict mode when no snapshot entries match the requested module' {
        @(
            [PSCustomObject]@{
                Module    = 'UI'
                Key       = 'Service:wuauserv:StartType'
                Value     = 'Manual'
                Type      = 'Service'
                Timestamp = '2026-03-24 09:05:00'
            }
        ) | ConvertTo-Json -Depth 5 | Set-Content -Path $script:SnapshotPath -Encoding UTF8

        Set-StrictMode -Version Latest
        try {
            { Restore-Snapshot -Module 'WindowsUpdate' } | Should Not Throw
        } finally {
            Set-StrictMode -Off
        }
    }
}
