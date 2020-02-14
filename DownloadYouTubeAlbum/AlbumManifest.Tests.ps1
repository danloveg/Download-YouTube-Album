. $PSScriptRoot\AlbumManifest.ps1

Describe 'Album Manifest Tests' {
    Context 'VerifyManifestExists: File exists' {
        Mock Test-Path { return $True } -ParameterFilter { $Path -eq 'Manifest.txt' }

        It 'Does not throw if exists' {
            { VerifyManifestExists 'Manifest.txt' } | Should -Not -Throw
        }
    }

    Context 'VerifyManifestExists: File does not exist' {
        $FileName = 'Manifest.txt'
        Mock Test-Path { return $False } -ParameterFilter { $Path -eq $FileName }

        It 'Throws if manifest does not exist' {
            { VerifyManifestExists $FileName } | Should -Throw "File '$FileName' does not exist"
        }
    }

    Context 'GetContentsWithoutComments: Empty file' {
        Mock Get-Content { return $Null }

        It 'Returns NULL or empty' {
            $Output = GetContentsWithoutComments 'dummy_path'
            $Output | Should -BeNullOrEmpty
        }
    }

    Context 'GetContentsWithoutComments: No comments' {
        $Content = @(
            'Line 1',
            'Line 2'
        )

        Mock Get-Content { return $Content }

        It 'No content is removed' {
            $Output = GetContentsWithoutComments 'dummy_path'

            $Output | Should -HaveCount 2
            $Output[0] | Should -BeExactly $Content[0]
            $Output[1] | Should -BeExactly $Content[1]
        }
    }

    Context 'GetContentsWithoutComments: All comments' {
        $Content = @(
            '# Comment 1',
            '# Comment 2',
            '# Comment 3'
        )

        Mock Get-Content { return $Content }

        It 'Every line is returned empty' {
            $Output = GetContentsWithoutComments 'dummy_path'

            $Output | Should -HaveCount 3
            $Output[0] | Should -BeNullOrEmpty
            $Output[1] | Should -BeNullOrEmpty
            $Output[2] | Should -BeNullOrEmpty
        }
    }

    Context 'GetContentsWithoutComments: Comments on line ends' {
        $Content = @(
            'Content 1 # Comment 1',
            'Content 2 # Comment 2'
        )

        Mock Get-Content { return $Content }

        It 'Comments removed and content trimmed' {
            $Output = GetContentsWithoutComments 'dummy_path'

            $Output | Should -HaveCount 2
            $Output[0] | Should -BeExactly 'Content 1'
            $Output[1] | Should -BeExactly 'Content 2'
        }
    }

    Context 'GetContentsWithoutComments: Content with leading spaces' {
        $Content = @(
            'Function Hello() {',
            '    console.log("Hello!") # Output "Hello" to the console',
            '}'
        )

        Mock Get-Content { return $Content }

        It 'Leading spaces are retained' {
            $Output = GetContentsWithoutComments 'dummy_path'

            $Output | Should -HaveCount 3
            $Output[0] | Should -BeExactly $Content[0]
            $Output[1] | Should -BeExactly '    console.log("Hello!")'
            $Output[2] | Should -BeExactly $Content[2]
        }
    }

    Context 'GetAlbumData: All contents valid' {
        It 'Parses if artist is first, album is second' {
            $Content = @(
                'Artist: Elton John',
                'Album: Greatest Hits',
                'https://youtube.com'
            )

            $Output = GetAlbumData $Content

            $Output['Artist'] | Should -BeExactly 'Elton John'
            $Output['Album'] | Should -BeExactly 'Greatest Hits'
            $Output['Urls'] | Should -HaveCount 1
            $Output['Urls'][0] | Should -BeExactly 'https://youtube.com'
        }

        It 'Parses if album is first, artist is second' {
            $Content = @(
                'Album: Greatest Hits',
                'Artist: Elton John',
                'https://youtube.com'
            )

            $Output = GetAlbumData $Content

            $Output['Artist'] | Should -BeExactly 'Elton John'
            $Output['Album'] | Should -BeExactly 'Greatest Hits'
            $Output['Urls'] | Should -HaveCount 1
            $Output['Urls'][0] | Should -BeExactly 'https://youtube.com'
        }

        It 'Parses if content is interspersed with newlines' {
            $Content = @(
                '',
                '',
                'Album: Greatest Hits',
                '',
                'Artist: Elton John',
                '',
                '',
                '',
                'https://youtube.com',
                '',
                'https://tubeyou.com',
                ''
            )

            $Output = GetAlbumData $Content

            $Output['Artist'] | Should -BeExactly 'Elton John'
            $Output['Album'] | Should -BeExactly 'Greatest Hits'
            $Output['Urls'] | Should -HaveCount 2
            $Output['Urls'][0] | Should -BeExactly 'https://youtube.com'
            $Output['Urls'][1] | Should -BeExactly 'https://tubeyou.com'
        }
    }

    Context 'GetAlbumData: Content missing' {
        It 'Throws if artist line does not exist' {
            $Content = @(
                'Album: Greatest Hits',
                'https://youtube.com'
            )

            { GetAlbumData $Content } | Should -Throw 'Could not find album and artist'
        }

        It 'Throws if album line does not exist' {
            $Content = @(
                'Artist: Elton John',
                'https://youtube.com'
            )

            { GetAlbumData $Content } | Should -Throw 'Could not find album and artist'
        }

        It 'Throws if there are no URLs' {
            $Content = @(
                'Artist: Elton John',
                'Album: Greatest Hits'
            )

            { GetAlbumData $Content } | Should -Throw 'Could not find any URLs'
        }
    }

    Context 'GetAlbumData: Malformed data' {
        It 'Throws if Artist line is malformed' {
            $Content = @(
                'Artist -> Elton John',
                'Album: Greatest Hits',
                'https://youtube.com'
            )

            { GetAlbumData $Content } | Should -Throw 'Could not find album and artist'
        }

        It 'Throws if album line is malformed' {
            $Content = @(
                'Artist: Elton John',
                'Greatest Hits Album',
                'https://youtube.com'
            )

            { GetAlbumData $Content } | Should -Throw 'Could not find album and artist'
        }

        It 'Throws if URLs are invalid' {
            $InvalidURL = 'Some BS'

            $Content = @(
                'Artist: Elton John',
                'Album: Greatest Hits',
                $InvalidURL
            )

            { GetAlbumData $Content } | Should -Throw "`"$InvalidURL`" does not appear to be a URL"
        }

        It 'Throws if one of multiple URLs are invalid' {
            $InvalidURL = 'htP;/gogl.fr'

            $Content = @(
                'Artist: Elton John',
                'Album: Greatest Hits',
                'https://youtube.com',
                'https://youtube.com',
                $InvalidURL
            )

            { GetAlbumData $Content } | Should -Throw "`"$InvalidURL`" does not appear to be a URL"
        }
    }
}