#Requires -Modules Pester

Describe 'winconf.ps1 restore mode selection' {
    It 'defines explicit restore profile selection separate from rollback' {
        $content = Get-Content -Path "$PSScriptRoot\..\scripts\winconf.ps1" -Raw

        $content | Should Match '\[string\] \$RestoreProfile = ""'
        $content | Should Match 'Cannot combine -Rollback with -RestoreProfile'
        $content | Should Match 'Restore profile mode requires -Module'
    }

    It 'limits profile-based restore to supported modules and passes the profile through' {
        $content = Get-Content -Path "$PSScriptRoot\..\scripts\winconf.ps1" -Raw

        $content | Should Match 'does not support restore profiles'
        $content | Should Match 'RestoreProfile \$RestoreProfile'
    }

    It 'fails rollback explicitly when snapshot restore fails' {
        $content = Get-Content -Path "$PSScriptRoot\..\scripts\winconf.ps1" -Raw

        $content | Should Match 'Rollback requested'
        $content | Should Match 'Rollback failed:'
        $content | Should Match 'exit 1'
    }
}
