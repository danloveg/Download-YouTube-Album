. $PSScriptRoot\Exceptions.ps1
. $PSScriptRoot\Urls.ps1

Function VerifyManifestExists($manifestPath) {
    If (-Not (Test-Path -Path $manifestPath -PathType Leaf)) {
        Throw ([System.IO.FileNotFoundException]::new("File '$manifestPath' does not exist."))
    }
}

Function GetContentsWithoutComments($filePath) {
    $fileLines = (Get-Content $filePath)
    $noComments = [System.Collections.ArrayList] @()

    ForEach ($line in $fileLines) {
        $index = $line.IndexOf('#')
        If ($index -eq -1) {
            $index = $line.Length
        }
        $noComments.Add($line.Substring(0, $index).TrimEnd()) | Out-Null
    }

    return $noComments
}

Function GetAlbumDataFromManifest($contents) {
    $artistName = ''
    $albumName = ''

    $validLines = $contents | Where-Object { $_ -NotMatch '^$|^#.*$' }
    $firstLine = $validLines | Select-Object -First 1
    $secondLine = $validLines | Select-Object -Skip 1 -First 1

    ForEach ($line in @($firstLine, $secondLine)) {
        $artistMatch = [Regex]::Match($line, '(?i)^artist:\s+(.+)$')
        If ($artistMatch.Success) {
            $artistNameDirty = ([String] $artistMatch.Groups[1].Value).Trim()
            $artistName = $artistNameDirty.Split([System.IO.Path]::GetInvalidFileNameChars()) -Join '_'
            Continue
        }
        $albumMatch = [Regex]::Match($line, '(?i)^album:\s+(.+)$')
        If ($albumMatch.Success) {
            $albumNameDirty = ([String] $albumMatch.Groups[1].Value).Trim()
            $albumName = $albumNameDirty.Split([System.IO.Path]::GetInvalidFileNameChars()) -Join '_'
        }
    }

    If ($artistName -eq '' -Or $albumName -eq '') {
        Throw([AlbumDataException]::new("Could not find album and artist name in manifest."))
    }

    $linesAfterAlbumAndArtist = $contents | Select-Object -Skip ($contents.IndexOf($secondLine) + 1)
    $urlList = @(GetVerifiedUrlList -Urls $linesAfterAlbumAndArtist)

    $albumData = @{}
    $albumData.Add("artist", $artistName)
    $albumData.Add("album", $albumName)
    $albumData.Add("urls", $urlList)
    return $albumData
}

Function GetAlbumDataFromLiterals {
    Param(
        [Parameter(Mandatory=$True)]
        [String]
        $ArtistName,

        [Parameter(Mandatory=$True)]
        [String]
        $AlbumName,

        [Parameter(Mandatory=$True)]
        [String[]]
        $Urls
    )

    $VerifiedUrls = @(GetVerifiedUrlList -Urls $Urls)
    $albumData = @{}
    $albumData.Add("artist", $ArtistName)
    $albumData.Add("album", $AlbumName)
    $albumData.Add("urls", $VerifiedUrls)
    return $albumData
}
