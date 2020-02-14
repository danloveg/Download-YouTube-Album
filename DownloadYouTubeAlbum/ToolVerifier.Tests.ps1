. $PSScriptRoot\ToolVerifier.ps1

Describe 'Tool Verifier Tests' {
    Context 'VerifyToolsInstalled: Tools all installed' {
        Mock Get-Command { return $True } -ParameterFilter { $Name -eq 'python' }
        Mock Get-Command { return $True } -ParameterFilter { $Name -eq 'ffmpeg' }
        Mock Get-Command { return $True } -ParameterFilter { $Name -eq 'youtube-dl' }
        Mock Get-Command { return $True } -ParameterFilter { $Name -eq 'beet' }

        It 'No exception if all tools are installed' {
           { VerifyToolsInstalled } | Should -Not -Throw
        }
    }

    Context 'VerifyToolsInstalled: Python not installed' {
        Mock Get-Command { return $False } -ParameterFilter { $Name -eq 'python' }
        Mock Get-Command { return $True } -ParameterFilter { $Name -ne 'python' }

        It 'Exception thrown when python is not installed' {
            { VerifyToolsInstalled } | Should -Throw 'Could not find Python installation'
        }
    }

    Context 'VerifyToolsInstalled: ffmpeg not installed, avconv not installed' {
        Mock Get-Command { return $False } -ParameterFilter { $Name -eq 'ffmpeg' }
        Mock Get-Command { return $False } -ParameterFilter { $Name -eq 'avconv' }
        Mock Get-Command { return $True } -ParameterFilter { $Name -ne 'avconv' -And $Name -ne 'ffmpeg' }

        It 'Exception thrown when ffmpeg and avconv are not installed' {
            { VerifyToolsInstalled } | Should -Throw 'Could not find FFmpeg or avconv installation'
        }
    }

    Context 'VerifyToolsInstalled: youtube-dl not installed' {
        Mock Get-Command { return $False } -ParameterFilter { $Name -eq 'youtube-dl' }
        Mock pip { }
        Mock Get-Command { return $True } -ParameterFilter { $Name -ne 'youtube-dl' }

        It 'Exception thrown when youtube-dl cannot be installed' {
            { VerifyToolsInstalled } | Should -Throw 'Something went wrong installing youtube-dl'
        }
    }


    Context 'VerifyToolsInstalled: beets not installed' {
        Mock Get-Command { return $False } -ParameterFilter { $Name -eq 'beet' }
        Mock pip { }
        Mock Get-Command { return $True } -ParameterFilter { $Name -ne 'beet'}

        It 'Exception thrown when beets cannot be installed' {
            { VerifyToolsInstalled } | Should -Throw 'Something went wrong installing beets'
        }
    }
}