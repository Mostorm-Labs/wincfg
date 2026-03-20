#Requires -Modules Pester

Describe 'Registry.ps1 outcome classification' {
    BeforeEach {
        . "$PSScriptRoot\..\scripts\lib\Logger.ps1"
        . "$PSScriptRoot\..\scripts\lib\Snapshot.ps1"
        . "$PSScriptRoot\..\scripts\lib\Registry.ps1"

        $script:LogPath = Join-Path $env:TEMP ("winconf-registry-test-{0}.log" -f ([guid]::NewGuid()))
        $script:SnapshotPath = Join-Path $env:TEMP ("winconf-registry-test-{0}.json" -f ([guid]::NewGuid()))

        Initialize-Logger -LogPath $script:LogPath
        Initialize-Snapshot -Path $script:SnapshotPath

        Mock Get-RegValue { $null }
    }

    AfterEach {
        Remove-Item -Path $script:LogPath -ErrorAction SilentlyContinue
        Remove-Item -Path $script:SnapshotPath -ErrorAction SilentlyContinue
    }

    It 'classifies invalid registry definition when Path is missing' {
        $message = $null

        try {
            Set-RegValue -Path '' -Name 'TestName' -Value 1 -Module 'Test'
        } catch {
            $message = $_.Exception.Message
        }

        $message | Should BeLike '*invalid registry definition*'
        (Get-Content $script:LogPath -Raw) | Should BeLike '*invalid registry definition*'
        Test-Path $script:SnapshotPath | Should Be $false
    }

    It 'classifies access denied separately from missing key/value' {
        $message = $null
        Mock Test-Path { $true }
        Mock New-ItemProperty { throw [System.UnauthorizedAccessException]::new('Access is denied') }

        try {
            Set-RegValue -Path 'HKCU:\Software\WinConfTest' -Name 'TestName' -Value 1 -Module 'Test'
        } catch {
            $message = $_.Exception.Message
        }

        $message | Should BeLike '*access denied / unauthorized operation*'
        (Get-Content $script:LogPath -Raw) | Should BeLike '*access denied / unauthorized operation*'
    }

    It 'classifies unsupported registry path/value for current OS' {
        $message = $null
        Mock Test-Path { $true }
        Mock New-ItemProperty { throw [System.NotSupportedException]::new('This registry path is not supported') }

        try {
            Set-RegValue -Path 'HKCU:\Software\WinConfTest' -Name 'TestName' -Value 1 -Module 'Test'
        } catch {
            $message = $_.Exception.Message
        }

        $message | Should BeLike '*unsupported registry path/value for current OS*'
        (Get-Content $script:LogPath -Raw) | Should BeLike '*unsupported registry path/value for current OS*'
    }

    It 'classifies missing registry key/value separately' {
        $message = $null
        Mock Test-Path { $true }
        Mock New-ItemProperty { throw [System.Management.Automation.ItemNotFoundException]::new('Cannot find path') }

        try {
            Set-RegValue -Path 'HKCU:\Software\WinConfTest' -Name 'TestName' -Value 1 -Module 'Test'
        } catch {
            $message = $_.Exception.Message
        }

        $message | Should BeLike '*missing registry key/value*'
        (Get-Content $script:LogPath -Raw) | Should BeLike '*missing registry key/value*'
    }
}
