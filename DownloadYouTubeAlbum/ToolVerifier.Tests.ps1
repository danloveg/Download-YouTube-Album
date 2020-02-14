. $PSScriptRoot\ToolVerifier.ps1
. $PSScriptRoot\Exceptions.ps1

Describe 'Tool Verifier Tests' {
    Context 'Tools all installed' {
        Mock Get-Command { return $True } -ParameterFilter { $Name -eq 'python' }
        Mock Get-Command { return $True } -ParameterFilter { $Name -eq 'ffmpeg' }
        Mock Get-Command { return $True } -ParameterFilter { $Name -eq 'youtube-dl' }
        Mock Get-Command { return $True } -ParameterFilter { $Name -eq 'beet' }

        It 'No exception if all tools are installed' {
           { VerifyToolsInstalled } | Should -Not -Throw
        }
    }

    Context 'Python not installed' {
        Mock Get-Command { return $False } -ParameterFilter { $Name -eq 'python' }
        Mock Get-Command { return $True } -ParameterFilter { $Name -ne 'python' }

        It 'Exception thrown when python is not installed' {
            { VerifyToolsInstalled } | Should -Throw 'Could not find Python installation.'
        }
    }
}