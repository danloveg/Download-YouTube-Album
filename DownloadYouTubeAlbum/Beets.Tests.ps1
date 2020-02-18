. $PSScriptRoot\Beets.ps1

Describe 'Beets Tests' {
    Context 'GetDefaultBeetConfig: Valid arguments' {
        Mock GetBeetsPlugFolder { return 'beetsPlugFolder' }

        It 'Has the plugin folder in pluginpath' {
            $ConfigContents = GetDefaultBeetConfig 'dummyValue'
            $ConfigContents | Should -Contain 'pluginpath: beetsPlugFolder'
        }

        It 'Uses the passed folder as the beets library directory' {
            $ConfigContents = GetDefaultBeetConfig 'library'
            $ConfigContents | Should -Contain 'directory: library'
        }

        It 'Has the custom beets plugins activated' {
            $ConfigContents = GetDefaultBeetConfig 'dummyValue'

            $PluginLine = ''
            ForEach ($line in $ConfigContents) {
                If ($line -Match '^plugins:.+$') {
                    $PluginLine = $line
                    Break
                }
            }

            $PluginLine | Should -Not -BeNullOrEmpty
            $PluginLine | Should -Match 'fromyoutubetitle'
            $PluginLine | Should -Match 'fromdirname'
        }
    }

    Context 'GetDefaultBeetConfig: Invalid arguments' {
        Mock GetBeetsPlugFolder { return 'beetsPlugFolder' }

        It 'Throws if empty string is passed' {
            { GetDefaultBeetConfig '' } | Should -Throw 'cannot be null or empty'
        }

        It 'Throws if $null is passed' {
            { GetDefaultBeetConfig $null } | Should -Throw 'cannot be null or empty'
        }
    }

    Context 'RestoreBeetConfig: Valid arguments' {
        It 'Out-File is called with contents passed' {
            Mock Out-File { }
            Mock Write-Host { }
            Mock Test-Path { return $True }

            $HashTable = @{
                'configLocation'='testLocation';
                'originalContents'='testContents';
            }

            RestoreBeetConfig $HashTable

            Assert-MockCalled 'Out-File' -ParameterFilter { $FilePath -eq 'testLocation'; $InputObject -eq 'testContents' }
        }
    }

    Context 'RestoreBeetConfig: Invalid arguments' {
        Mock Out-File { }
        Mock Write-Host { }

        It 'Throws if configLocation key is missing' {
            Mock Test-Path { return $True }

            $HashTable = @{ 'originalContents'='testContents' }

            { RestoreBeetConfig $HashTable } | Should -Throw 'Could not find "configLocation"'
        }

        It 'Throws if originalLocation key is missing' {
            Mock Test-Path { return $True }

            $HashTable = @{ 'configLocation'='testLocation' }

            { RestoreBeetConfig $HashTable } | Should -Throw 'Could not find "originalContents"'
        }

        It 'Throws if configLocation file does not exist' {
            Mock Test-Path { return $False }

            $HashTable = @{
                'configLocation'='testLocation';
                'originalContents'='testContents';
            }

            { RestoreBeetConfig $HashTable } | Should -Throw '"testLocation" does not exist'
        }
    }
}