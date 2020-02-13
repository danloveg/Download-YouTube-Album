
. $PSScriptRoot\Exceptions.ps1

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
        $noComments.Add($line.Substring(0, $index).Trim()) | Out-Null
    }

    return $noComments
}

Function GetAlbumData($contents) {
    $artistName = ''
    $albumName = ''
    $urlList = [System.Collections.ArrayList] @()

    $validLines = $contents | Where-Object { $_ -NotMatch '^$|^#.*$' }
    $firstLine = $validLines | Select-Object -First 1
    $secondLine = $validLines | Select-Object -Skip 1 -First 1

    ForEach ($line in @($firstLine, $secondLine)) {
        $artistMatch = [Regex]::Match($line, '(?i)^artist:\s+(.+)$')
        If ($artistMatch.Success) {
            $artistName = ([String] $artistMatch.Groups[1].Value).Trim()
            Continue
        }
        $albumMatch = [Regex]::Match($line, '(?i)^album:\s+(.+)$')
        If ($albumMatch.Success) {
            $albumName = ([String] $albumMatch.Groups[1].Value).Trim()
        }
    }

    If ($artistName -eq '' -Or $albumName -eq '') {
        Throw([AlbumManifestException]::new("Could not find album and artist name in manifest."))
    }

    $linesAfterAlbumAndArtist = $contents | Select-Object -Skip ($contents.IndexOf($secondLine) + 1)

    $numUrls = 0
    Foreach ($line in $linesAfterAlbumAndArtist) {
        If (-Not([String]::IsNullOrWhiteSpace($line))) {
            $uri = $line -as [System.URI]
            If (($Null -eq $uri) -Or -Not($uri.Scheme -match '[http|https]')) {
                Throw([AlbumManifestException]::new("`"$line`" does not appear to be a url."))
            } Else {
                $urlList.Add($line) | Out-Null
                $numUrls += 1
            }
        }
    }

    If ($numUrls -eq 0) {
        Throw([AlbumManifestException]::new("Could not find any URLs in the manifest file."))
    }

    $albumData = @{}
    $albumData.Add("artist", $artistName)
    $albumData.Add("album", $albumName)
    $albumData.Add("urls", $urlList)
    return $albumData
}