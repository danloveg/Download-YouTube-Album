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

    Context 'UpdateBeetConfig: valid folder' {
        Mock Write-Host { }
        Mock Out-File { }
        Mock beet { return 'path\to\config.yaml' }

        It 'Creates a new config file if one does not exist' {
            Mock Get-Content { }
            Mock Test-Path { return $False }
            Mock New-Item { }
            Mock GetDefaultBeetConfig { }

            UpdateBeetConfig 'valid\folder'

            Assert-MockCalled New-Item -ParameterFilter { $Path -eq 'path\to\config.yaml' }
        }

        It 'Returns the original contents of the config file' {
            Mock Get-Content { return @('line1', 'line2') }
            Mock Test-Path { return $True }
            Mock New-Item { }
            Mock GetDefaultBeetConfig { }

            $Out = UpdateBeetConfig 'valid\folder'

            $Out['configLocation'] | Should -BeExactly 'path\to\config.yaml'
            $Out['originalContents'] | Should -HaveCount 2
            $Out['originalContents'][0] | Should -BeExactly 'line1'
            $Out['originalContents'][1] | Should -BeExactly 'line2'
        }

        It 'Overwrites the config file with the new contents' {
            Mock Get-Content { return @() }
            Mock Test-Path { return $True }
            Mock New-Item { }
            Mock GetDefaultBeetConfig { return @('default line 1', 'default line 2') }

            UpdateBeetConfig 'valid\folder'

            Assert-MockCalled Out-File -ParameterFilter { $FilePath -eq 'path\to\config.yaml' }
        }
    }

    Context 'UpdateBeetConfig: invalid folder' {
        Mock beet { }
        Mock Write-Host { }
        Mock Test-Path { }
        Mock New-Item { }
        Mock Get-Content { }
        Mock Out-File { }

        It 'Throws if folder is empty' {
            { UpdateBeetConfig '' } | Should -Throw 'cannot be null or empty'
        }

        It 'Throws if folder is $NULL' {
            { UpdateBeetConfig $null } | Should -Throw 'cannot be null or empty'
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