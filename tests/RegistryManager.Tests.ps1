#Requires -Modules Pester
<br>
BeforeAll {
    # Use a temp registry hive so tests never touch the real system
    $script:TestHive = 'HKCU:\SOFTWARE\WinConfTest'
    if (-not (Test-Path $script:TestHive)) {
        New-Item -Path $script:TestHive -Force | Out-Null
    }

    # Stub $ctx used by all functions
    $script:Ctx = @{
        DryRun   = $false
        Log      = [System.Collections.Generic.List[string]]::new()
        Snapshot = @{}
        Errors   = [System.Collections.Generic.List[string]]::new()
    }

    Import-Module "$PSScriptRoot\..\scripts\modules\RegistryManager.psm1" -Force
}

AfterAll {
    Remove-Item -Path $script:TestHive -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'Read-RegValue' {
    It 'returns the value when the key exists' {
        Set-ItemProperty -Path $script:TestHive -Name 'TestKey' -Value 42 -Type DWord
        Read-RegValue -Hive 'HKCU' -Path 'SOFTWARE\WinConfTest' -Name 'TestKey' | Should -Be 42
    }

    It 'returns $null when the key does not exist' {
        Read-RegValue -Hive 'HKCU' -Path 'SOFTWARE\WinConfTest' -Name 'NonExistent' | Should -BeNullOrEmpty
    }

    It 'returns the supplied default when the key does not exist' {
        Read-RegValue -Hive 'HKCU' -Path 'SOFTWARE\WinConfTest' -Name 'NonExistent' -Default 99 | Should -Be 99
    }
}

Describe 'Write-RegValue' {
    It 'creates a new key with the correct value' {
        Write-RegValue -Hive 'HKCU' -Path 'SOFTWARE\WinConfTest' -Name 'NewKey' -Value 1 -Type 'DWord'
        (Get-ItemProperty -Path $script:TestHive -Name 'NewKey').NewKey | Should -Be 1
    }

    It 'overwrites an existing key' {
        Set-ItemProperty -Path $script:TestHive -Name 'Existing' -Value 0 -Type DWord
        Write-RegValue -Hive 'HKCU' -Path 'SOFTWARE\WinConfTest' -Name 'Existing' -Value 1 -Type 'DWord'
        (Get-ItemProperty -Path $script:TestHive -Name 'Existing').Existing | Should -Be 1
    }

    It 'is idempotent — does not error when value already matches' {
        Set-ItemProperty -Path $script:TestHive -Name 'Same' -Value 5 -Type DWord
        { Write-RegValue -Hive 'HKCU' -Path 'SOFTWARE\WinConfTest' -Name 'Same' -Value 5 -Type 'DWord' } | Should -Not -Throw
    }

    It 'does not write in dry-run mode' {
        $dryCtx = $script:Ctx.Clone(); $dryCtx.DryRun = $true
        Write-RegValue -Hive 'HKCU' -Path 'SOFTWARE\WinConfTest' -Name 'DryKey' -Value 1 -Type 'DWord' -Ctx $dryCtx
        Test-Path "$script:TestHive\DryKey" | Should -BeFalse
    }
}

Describe 'Remove-RegValue' {
    It 'removes a key that exists' {
        Set-ItemProperty -Path $script:TestHive -Name 'ToRemove' -Value 1 -Type DWord
        Remove-RegValue -Hive 'HKCU' -Path 'SOFTWARE\WinConfTest' -Name 'ToRemove'
        { Get-ItemProperty -Path $script:TestHive -Name 'ToRemove' -ErrorAction Stop } | Should -Throw
    }

    It 'does not error when key is already absent' {
        { Remove-RegValue -Hive 'HKCU' -Path 'SOFTWARE\WinConfTest' -Name 'AlreadyGone' } | Should -Not -Throw
    }
}

Describe 'Test-RegistryManager' {
    It 'returns a hashtable with one entry per target' {
        $result = Test-RegistryManager -Ctx $script:Ctx
        $result | Should -BeOfType [hashtable]
        $result.Count | Should -BeGreaterThan 0
    }

    It 'does not modify any registry keys' {
        $before = (Get-ItemProperty -Path $script:TestHive -ErrorAction SilentlyContinue)
        Test-RegistryManager -Ctx $script:Ctx | Out-Null
        $after  = (Get-ItemProperty -Path $script:TestHive -ErrorAction SilentlyContinue)
        $before | Should -Be $after
    }
}

Describe 'Set-RegistryManager' {
    It 'saves before-values to ctx.Snapshot' {
        $ctx = $script:Ctx.Clone(); $ctx.Snapshot = @{}
        Set-RegistryManager -Ctx $ctx
        $ctx.Snapshot.ContainsKey('RegistryManager') | Should -BeTrue
    }

    It 'skips all writes in dry-run mode' {
        $ctx = $script:Ctx.Clone(); $ctx.DryRun = $true; $ctx.Snapshot = @{}
        # Capture registry state before
        $before = (Get-ChildItem -Path $script:TestHive -ErrorAction SilentlyContinue)
        Set-RegistryManager -Ctx $ctx
        $after  = (Get-ChildItem -Path $script:TestHive -ErrorAction SilentlyContinue)
        $before | Should -Be $after
    }

    It 'logs every operation' {
        $ctx = $script:Ctx.Clone(); $ctx.Log = [System.Collections.Generic.List[string]]::new(); $ctx.Snapshot = @{}
        Set-RegistryManager -Ctx $ctx
        $ctx.Log.Count | Should -BeGreaterThan 0
    }
}

Describe 'Restore-RegistryManager' {
    It 'restores a key to its original value' {
        Set-ItemProperty -Path $script:TestHive -Name 'RestoreMe' -Value 0 -Type DWord
        $ctx = $script:Ctx.Clone()
        $ctx.Snapshot = @{
            RegistryManager = @(
                @{ Hive='HKCU'; Path='SOFTWARE\WinConfTest'; Name='RestoreMe'; OriginalValue=0; WasAbsent=$false }
            )
        }
        # Simulate a change
        Set-ItemProperty -Path $script:TestHive -Name 'RestoreMe' -Value 99 -Type DWord
        Restore-RegistryManager -Ctx $ctx
        (Get-ItemProperty -Path $script:TestHive -Name 'RestoreMe').RestoreMe | Should -Be 0
    }

    It 'removes a key that was absent before' {
        $ctx = $script:Ctx.Clone()
        $ctx.Snapshot = @{
            RegistryManager = @(
                @{ Hive='HKCU'; Path='SOFTWARE\WinConfTest'; Name='WasAbsent'; OriginalValue=$null; WasAbsent=$true }
            )
        }
        Set-ItemProperty -Path $script:TestHive -Name 'WasAbsent' -Value 1 -Type DWord
        Restore-RegistryManager -Ctx $ctx
        { Get-ItemProperty -Path $script:TestHive -Name 'WasAbsent' -ErrorAction Stop } | Should -Throw
    }
}
