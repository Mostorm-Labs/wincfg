#Requires -Modules Pester

BeforeAll {
    $script:Ctx = @{
        DryRun   = $false
        Log      = [System.Collections.Generic.List[string]]::new()
        Snapshot = @{}
        Errors   = [System.Collections.Generic.List[string]]::new()
    }

    Import-Module "$PSScriptRoot\..\scripts\modules\PowerManager.psm1" -Force

    # Capture real state once so we can restore after the suite
    $script:OriginalPlan    = Get-ActivePlan
    $script:OriginalTimeouts = @{}
    foreach ($s in @('standby-timeout-ac','standby-timeout-dc','monitor-timeout-ac','monitor-timeout-dc','hibernate-timeout-dc')) {
        $script:OriginalTimeouts[$s] = Get-Timeout -Setting $s
    }
}

AfterAll {
    # Restore system to pre-test state
    Set-ActivePlan -Guid $script:OriginalPlan
    foreach ($kv in $script:OriginalTimeouts.GetEnumerator()) {
        Set-Timeout -Setting $kv.Key -Value $kv.Value
    }
}

Describe 'Get-ActivePlan' {
    It 'returns a valid GUID string' {
        $guid = Get-ActivePlan
        $guid | Should -Match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    }
}

Describe 'Get-Timeout' {
    It 'returns an integer for a valid setting' {
        $val = Get-Timeout -Setting 'standby-timeout-ac'
        $val | Should -BeOfType [int]
    }

    It 'returns a non-negative value' {
        Get-Timeout -Setting 'monitor-timeout-ac' | Should -BeGreaterOrEqual 0
    }
}

Describe 'Set-ActivePlan' {
    It 'activates the high-performance plan' {
        $highPerf = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
        Set-ActivePlan -Guid $highPerf
        Get-ActivePlan | Should -Be $highPerf
    }

    It 'is idempotent — does not error when plan is already active' {
        $current = Get-ActivePlan
        { Set-ActivePlan -Guid $current } | Should -Not -Throw
    }
}

Describe 'Set-Timeout' {
    It 'sets standby-timeout-ac to 0' {
        Set-Timeout -Setting 'standby-timeout-ac' -Value 0
        Get-Timeout -Setting 'standby-timeout-ac' | Should -Be 0
    }

    It 'is idempotent — does not error when value already matches' {
        Set-Timeout -Setting 'monitor-timeout-ac' -Value 0
        { Set-Timeout -Setting 'monitor-timeout-ac' -Value 0 } | Should -Not -Throw
    }
}

Describe 'Test-PowerManager' {
    It 'returns a hashtable' {
        $result = Test-PowerManager -Ctx $script:Ctx
        $result | Should -BeOfType [hashtable]
    }

    It 'includes ActivePlan key' {
        $result = Test-PowerManager -Ctx $script:Ctx
        $result.ContainsKey('ActivePlan') | Should -BeTrue
    }

    It 'includes all timeout settings' {
        $result = Test-PowerManager -Ctx $script:Ctx
        foreach ($s in @('standby-timeout-ac','standby-timeout-dc','monitor-timeout-ac','monitor-timeout-dc','hibernate-timeout-dc')) {
            $result.ContainsKey($s) | Should -BeTrue
        }
    }

    It 'does not change any power settings' {
        $before = Get-ActivePlan
        Test-PowerManager -Ctx $script:Ctx | Out-Null
        Get-ActivePlan | Should -Be $before
    }
}

Describe 'Set-PowerManager' {
    It 'saves ActivePlan to ctx.Snapshot before changing' {
        $ctx = $script:Ctx.Clone(); $ctx.Snapshot = @{}
        Set-PowerManager -Ctx $ctx
        $ctx.Snapshot.ContainsKey('PowerManager') | Should -BeTrue
        $ctx.Snapshot.PowerManager.ContainsKey('ActivePlan') | Should -BeTrue
    }

    It 'activates the high-performance plan' {
        $ctx = $script:Ctx.Clone(); $ctx.Snapshot = @{}
        Set-PowerManager -Ctx $ctx
        Get-ActivePlan | Should -Be '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
    }

    It 'sets all timeouts to 0' {
        $ctx = $script:Ctx.Clone(); $ctx.Snapshot = @{}
        Set-PowerManager -Ctx $ctx
        foreach ($s in @('standby-timeout-ac','standby-timeout-dc','monitor-timeout-ac','monitor-timeout-dc')) {
            Get-Timeout -Setting $s | Should -Be 0
        }
    }

    It 'skips all changes in dry-run mode' {
        $ctx = $script:Ctx.Clone(); $ctx.DryRun = $true; $ctx.Snapshot = @{}
        $planBefore = Get-ActivePlan
        Set-PowerManager -Ctx $ctx
        Get-ActivePlan | Should -Be $planBefore
    }

    It 'logs every operation' {
        $ctx = $script:Ctx.Clone()
        $ctx.Log      = [System.Collections.Generic.List[string]]::new()
        $ctx.Snapshot = @{}
        Set-PowerManager -Ctx $ctx
        $ctx.Log.Count | Should -BeGreaterThan 0
    }
}

Describe 'Restore-PowerManager' {
    It 'restores the original power plan' {
        $original = Get-ActivePlan
        $ctx = $script:Ctx.Clone()
        $ctx.Snapshot = @{
            PowerManager = @{
                ActivePlan           = $original
                'standby-timeout-ac' = 15
                'standby-timeout-dc' = 15
                'monitor-timeout-ac' = 10
                'monitor-timeout-dc' = 10
                'hibernate-timeout-dc' = 30
            }
        }
        # Change to something else
        Set-ActivePlan -Guid '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
        Restore-PowerManager -Ctx $ctx
        Get-ActivePlan | Should -Be $original
    }

    It 'restores timeout values from snapshot' {
        $ctx = $script:Ctx.Clone()
        $ctx.Snapshot = @{
            PowerManager = @{
                ActivePlan           = Get-ActivePlan
                'standby-timeout-ac' = 20
                'standby-timeout-dc' = 20
                'monitor-timeout-ac' = 20
                'monitor-timeout-dc' = 20
                'hibernate-timeout-dc' = 20
            }
        }
        Set-Timeout -Setting 'standby-timeout-ac' -Value 0
        Restore-PowerManager -Ctx $ctx
        Get-Timeout -Setting 'standby-timeout-ac' | Should -Be 20
    }
}
