#Requires -Modules Pester
# NOTE: These tests require Administrator privileges — service install/remove needs elevation.

BeforeAll {
    $script:ServiceName = 'WinConfTestAgent'

    $script:Ctx = @{
        DryRun   = $false
        Log      = [System.Collections.Generic.List[string]]::new()
        Snapshot = @{}
        Errors   = [System.Collections.Generic.List[string]]::new()
        Config   = @{
            service = @{
                name        = $script:ServiceName
                displayName = 'WinConf Test Agent'
                binaryPath  = 'C:\Windows\System32\cmd.exe'   # real binary; won't actually run as a service
                startType   = 'Manual'                         # Manual so it doesn't auto-start on test machines
                account     = 'LocalSystem'
            }
        }
    }

    Import-Module "$PSScriptRoot\..\scripts\modules\ServiceInstaller.psm1" -Force
}

AfterAll {
    # Best-effort cleanup — remove test service if it still exists
    $svc = Get-Service -Name $script:ServiceName -ErrorAction SilentlyContinue
    if ($svc) {
        Stop-Service  -Name $script:ServiceName -Force -ErrorAction SilentlyContinue
        sc.exe delete $script:ServiceName | Out-Null
    }
}

Describe 'Get-ServiceState' {
    Context 'when the service does not exist' {
        It 'returns Exists=$false' {
            $state = Get-ServiceState -Name 'NonExistentService_XYZ'
            $state.Exists | Should -BeFalse
        }
    }

    Context 'when a known service exists' {
        It 'returns Exists=$true for the spooler service' {
            $state = Get-ServiceState -Name 'Spooler'
            $state.Exists | Should -BeTrue
        }

        It 'returns a Status field' {
            $state = Get-ServiceState -Name 'Spooler'
            $state.ContainsKey('Status') | Should -BeTrue
        }

        It 'returns a StartType field' {
            $state = Get-ServiceState -Name 'Spooler'
            $state.ContainsKey('StartType') | Should -BeTrue
        }
    }
}

Describe 'Test-ServiceInstaller' {
    It 'returns a hashtable' {
        $result = Test-ServiceInstaller -Ctx $script:Ctx
        $result | Should -BeOfType [hashtable]
    }

    It 'includes Exists key' {
        $result = Test-ServiceInstaller -Ctx $script:Ctx
        $result.ContainsKey('Exists') | Should -BeTrue
    }

    It 'does not create or modify any service' {
        $before = Get-ServiceState -Name $script:ServiceName
        Test-ServiceInstaller -Ctx $script:Ctx | Out-Null
        $after  = Get-ServiceState -Name $script:ServiceName
        $after.Exists | Should -Be $before.Exists
    }
}

Describe 'Install-WinService' {
    AfterEach {
        Stop-Service  -Name $script:ServiceName -Force -ErrorAction SilentlyContinue
        sc.exe delete $script:ServiceName | Out-Null
        Start-Sleep -Milliseconds 500   # give SCM time to remove
    }

    It 'creates the service' {
        Install-WinService -Config $script:Ctx.Config.service
        (Get-ServiceState -Name $script:ServiceName).Exists | Should -BeTrue
    }

    It 'sets the correct display name' {
        Install-WinService -Config $script:Ctx.Config.service
        (Get-Service -Name $script:ServiceName).DisplayName | Should -Be $script:Ctx.Config.service.displayName
    }

    It 'does not error when called twice (idempotent)' {
        Install-WinService -Config $script:Ctx.Config.service
        { Install-WinService -Config $script:Ctx.Config.service } | Should -Not -Throw
    }
}

Describe 'Remove-WinService' {
    BeforeEach {
        Install-WinService -Config $script:Ctx.Config.service
        Start-Sleep -Milliseconds 300
    }

    It 'removes the service' {
        Remove-WinService -Name $script:ServiceName
        (Get-ServiceState -Name $script:ServiceName).Exists | Should -BeFalse
    }

    It 'does not error when service is already absent' {
        Remove-WinService -Name $script:ServiceName
        { Remove-WinService -Name $script:ServiceName } | Should -Not -Throw
    }
}

Describe 'Set-ServiceInstaller' {
    AfterEach {
        Stop-Service  -Name $script:ServiceName -Force -ErrorAction SilentlyContinue
        sc.exe delete $script:ServiceName | Out-Null
        Start-Sleep -Milliseconds 500
    }

    It 'snapshots WasAbsent=$true when service did not exist' {
        $ctx = $script:Ctx.Clone(); $ctx.Snapshot = @{}
        Set-ServiceInstaller -Ctx $ctx
        $ctx.Snapshot.ServiceInstaller.WasAbsent | Should -BeTrue
    }

    It 'creates the service' {
        $ctx = $script:Ctx.Clone(); $ctx.Snapshot = @{}
        Set-ServiceInstaller -Ctx $ctx
        (Get-ServiceState -Name $script:ServiceName).Exists | Should -BeTrue
    }

    It 'skips install in dry-run mode' {
        $ctx = $script:Ctx.Clone(); $ctx.DryRun = $true; $ctx.Snapshot = @{}
        Set-ServiceInstaller -Ctx $ctx
        (Get-ServiceState -Name $script:ServiceName).Exists | Should -BeFalse
    }

    It 'logs the install operation' {
        $ctx = $script:Ctx.Clone()
        $ctx.Log      = [System.Collections.Generic.List[string]]::new()
        $ctx.Snapshot = @{}
        Set-ServiceInstaller -Ctx $ctx
        $ctx.Log.Count | Should -BeGreaterThan 0
    }

    It 'snapshots WasAbsent=$false when service already existed' {
        # Pre-install the service
        Install-WinService -Config $script:Ctx.Config.service
        $ctx = $script:Ctx.Clone(); $ctx.Snapshot = @{}
        Set-ServiceInstaller -Ctx $ctx
        $ctx.Snapshot.ServiceInstaller.WasAbsent | Should -BeFalse
    }
}

Describe 'Restore-ServiceInstaller' {
    It 'removes the service when WasAbsent=$true' {
        Install-WinService -Config $script:Ctx.Config.service
        $ctx = $script:Ctx.Clone()
        $ctx.Snapshot = @{
            ServiceInstaller = @{ WasAbsent = $true; Name = $script:ServiceName }
        }
        Restore-ServiceInstaller -Ctx $ctx
        (Get-ServiceState -Name $script:ServiceName).Exists | Should -BeFalse
    }

    It 'leaves the service when WasAbsent=$false' {
        Install-WinService -Config $script:Ctx.Config.service
        $ctx = $script:Ctx.Clone()
        $ctx.Snapshot = @{
            ServiceInstaller = @{ WasAbsent = $false; Name = $script:ServiceName }
        }
        Restore-ServiceInstaller -Ctx $ctx
        (Get-ServiceState -Name $script:ServiceName).Exists | Should -BeTrue
        # Cleanup
        sc.exe delete $script:ServiceName | Out-Null
    }
}
