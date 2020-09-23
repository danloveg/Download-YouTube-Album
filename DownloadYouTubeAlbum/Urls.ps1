. $PSScriptRoot\Exceptions.ps1

Function GetVerifiedUrlList {
    <#
    .SYNOPSIS

    Check that each string can be parsed as a URI

    .PARAMETER Urls

    A list of URLs to verify. Empty strings are allowed, but are ignored.

    .OUTPUTS

    System.Collections.ArrayList. A list of all the valid URIs.
    #>
    Param(
        [Parameter(Mandatory=$True)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [AllowNull()]
        [String[]]
        $Urls
    )

    $VerifiedUrls = [System.Collections.ArrayList] @()

    If ($Urls) {
        Foreach ($Item in $Urls) {
            If (-Not([String]::IsNullOrWhiteSpace($Item))) {
                $CleanUrlString = $Item.Trim()
                $Uri = $CleanUrlString -as [System.URI]
                If (-Not $Uri -Or -Not($Uri.Scheme -match '[http|https]')) {
                    Throw([AlbumDataException]::new("`"$CleanUrlString`" does not appear to be a url."))
                }
                Else {
                    $VerifiedUrls.Add($CleanUrlString) | Out-Null
                }
            }
        }
    }

    If (-Not $VerifiedUrls) {
        Throw([AlbumDataException]::new("Could not find any URLs."))
    }

    $VerifiedUrls
}
