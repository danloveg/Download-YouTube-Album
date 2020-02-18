. $PSScriptRoot\Downloader.ps1

Describe 'Downloader Tests' {
    Mock Invoke-Expression { }

    Context 'DownloadAudio: ffmpeg is available' {
        Mock Get-Command { return $True }

        It 'youtube-dl is called for one url' {
            DownloadAudio @('url_1') $False $False
            Assert-MockCalled Invoke-Expression -ParameterFilter { $Command -Match 'url_1' }
        }

        It 'youtube-dl is called multiple times for each url' {
            DownloadAudio @('url_1', 'url_2') $False $False
            Assert-MockCalled Invoke-Expression -ParameterFilter { $Command -Match 'url_1' }
            Assert-MockCalled Invoke-Expression -ParameterFilter { $Command -Match 'url_2' }
        }

        It '--no-playlist added if $NoPlaylist is true' {
            DownloadAudio @('url1_1') $True $False
            Assert-MockCalled Invoke-Expression -ParameterFilter { $Command -Match '--no-playlist' }
        }

        It '--no-playlist NOT added if $NoPlaylist is false' {
            DownloadAudio @('url_1') $True $False
            Assert-MockCalled Invoke-Expression -ParameterFilter { -Not ($Command -Match '--no-playlist') }
        }

        It '--audio-format mp3 added if $PreferMP3 is true' {
            DownloadAudio @('url_1') $False $True
            Assert-MockCalled Invoke-Expression -ParameterFilter { $Command -Match '--audio-format mp3' }
        }

        It '--audio-format m4a added if $PreferMP3 is false' {
            DownloadAudio @('url_1') $False $True
            Assert-MockCalled Invoke-Expression -ParameterFilter { $Command -Match '--audio-format m4a' }
        }
    }

    Context 'DownloadAudio: ffmpeg is not available' {
        Mock Get-Command { return $False }

        It '--prefer-avconv is added if ffmpeg is not available' {
            DownloadAudio @('url_1') $False $False
            Assert-MockCalled Invoke-Expression -ParameterFilter { $Command -Match '--prefer-avconv' }
        }
    }
}