. $PSScriptRoot\Urls.ps1

Describe 'Urls Unit Tests' -Tag 'Unit' {
    Context 'All Valid Urls' {
        It 'Trims whitespace from URLs' {
            $List = @(" https://youtube.com  ", "`nhttps://google.ca")
            $Result = GetVerifiedUrlList $List
            $Result | Should -HaveCount 2
            $Result[0] | Should -BeExactly 'https://youtube.com'
            $Result[1] | Should -BeExactly 'https://google.ca'
        }

        It 'Ignores empty URLS' {
            $List = @("`n", ' ', 'https://youtube.com', '  ', 'https://google.ca')
            $Result = GetVerifiedUrlList $List
            $Result | Should -HaveCount 2
            $Result[0] | Should -BeExactly 'https://youtube.com'
            $Result[1] | Should -BeExactly 'https://google.ca'
        }
    }

    Context 'Invalid Urls' {
        It 'Throws if one invalid URL' {
            $InvalidUrl = 'thisisinvalid'
            { GetVerifiedUrlList @($InvalidUrl) } | Should -Throw "`"$InvalidURL`" does not appear to be a URL"
        }

        It 'Throws if invalid URL is buried in valid URLs' {
            $InvalidUrl = 'thisisinvalid'
            $List = @('https://youtube.com', 'https://google.ca', $InvalidUrl)
            { GetVerifiedUrlList $List } | Should -Throw "`"$InvalidURL`" does not appear to be a URL"
        }

        It 'Throws if invalid URL is buried in empty URLs' {
            $InvalidUrl = 'thisisinvalid'
            $List = @('', '', '', $InvalidUrl, '')
            { GetVerifiedUrlList $List } | Should -Throw "`"$InvalidURL`" does not appear to be a URL"
        }

        It 'Throws if the list is $NULL' {
            { GetVerifiedUrlList $Null } | Should -Throw 'Could not find any URLs'
        }

        It 'Throws if the list is empty' {
            { GetVerifiedUrlList @() } | Should -Throw 'Could not find any URLs'
        }

        It 'Throws if the list is full of whitespace' {
            $List = @("`n", ' ', '', '  ')
            { GetVerifiedUrlList $List } | Should -Throw 'Could not find any URLs'
        }
    }
}
