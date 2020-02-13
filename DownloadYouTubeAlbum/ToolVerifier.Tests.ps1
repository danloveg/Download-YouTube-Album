. $PSScriptRoot\ToolVerifier.ps1

Describe 'Tool Verifier Tests' {
    Context 'Tools all installed' {
        Mock Get-Command { return $True } -ParameterFilter { $Name -eq 'python' }
        Mock Get-Command { return $True } -ParameterFilter { $Name -eq 'ffmpeg' }
        Mock Get-Command { return $True } -ParameterFilter { $Name -eq 'youtube-dl' }
        Mock Get-Command { return $True } -ParameterFilter { $Name -eq 'beet' }

        It 'Should return True if all tools are installed' {
           { VerifyToolsInstalled } | Should -Not -Throw
        }
    }
}