
. $PSScriptRoot\Exceptions.ps1
. $PSScriptRoot\Beets.ps1
. $PSScriptRoot\ToolVerifier.ps1

Function Get-YoutubeAlbum() {
    <#
    .synopsis
    YouTube music album downloader. Solves the problem of having to download
    songs one by one from some youtube to mp3 converter, before tediously
    editing the metadata by hand.

    .description
    Use youtube-dl to download a list of m4a files (or mp3s) from URLs, then use
    beets tool to automatically update metadata and album art.

    .parameter albumManifest
    A text file containing information required to download and create an album.
    The file must start with the album and artist name in any order, followed by
    one or more URLs. The URLs may be YouTube playlists. This is a sample album
    manifest:

    Album: <album name>
    Artist: <artist name>
    https://youtube.com/someplaylist

    .parameter noPlaylist
    Avoid downloading YouTube URLs as playlists.

    .parameter preferMP3
    Encode downloaded audio as MP3, rather than the default m4a.

    .example
    DOWNLOAD ONE PLAYLIST AS AN ALBUM
    Assume the artist is Foo, and the album is Bar. The album manifest should contain:

    Artist: Foo
    Album: Bar
    https://youtube.com/foobarplaylist

    The command to download this album:

    Get-YoutubeAlbum -albumManifest path/to/manifest.txt

    .example
    DOWNLOAD MUTLIPLE DIFFERENT SONGS AS AN ALBUM
    Assume the artist is Peel, and the album is Banana. Also assume that there
    are three songs in the album. The album manifest should contain:

    Album: Banana
    Arist: Peel
    https://youtube.com/someurl1
    https://youtube.com/someurl2
    https://youtube.com/someurl3

    The command to download this album:

    Get-YoutubeAlbum path/to/manifest.txt -noPlaylist
    #>
    Param(
        [Parameter(Mandatory=$True)] [String] $albumManifest,
        [Switch] $noPlaylist = $False,
        [Switch] $preferMP3 = $False
    )

    $beetConfig = $NULL
    $initialLocation = $NULL

    Try {
        VerifyToolsInstalled
        VerifyManifestExists $albumManifest
        $albumManifestContents = GetContentsWithoutComments $albumManifest
        $albumData = GetAlbumData $albumManifestContents

        $initialLocation = (Get-Location).Path
        $beetConfig = UpdateBeetConfig $initialLocation
        Push-Location # Add current folder to stack

        CreateNewFolder $albumData['artist']
        Set-Location $albumData['artist']
        Push-Location # Add artist folder to stack

        # Download the audio into the album folder
        CreateNewFolder $albumData['album']
        Set-Location $albumData['album']
        Write-Host ("`nDownloading album '{0}' by artist '{1}'`n" -f $albumData['album'], $albumData['artist']) -ForegroundColor Green
        DownloadAudio $albumData['urls'] $noPlaylist $preferMP3
        Pop-Location # Pop artist folder from stack

        # Update the music tags
        Write-Host ("`nAttempting to automatically fix music tags.`n") -ForegroundColor Green
        beet import $albumData['album']
        Pop-Location # Pop intial folder from stack

        CleanArtistFolderIfEmpty $albumData['artist']
    }
    Catch [System.IO.FileNotFoundException] {
        Write-Host "File Not Found Exception:" -ForegroundColor Red
        Write-Host "$_" -ForegroundColor Red
    }
    Catch [DependencyException] {
        Write-Host "Dependency Exception:" -ForegroundColor Red
        Write-Host "$_" -ForegroundColor Red
    }
    Catch [AlbumManifestException] {
        Write-Host "Album Manifest Exception:" -ForegroundColor Red
        Write-Host "$_" -ForegroundColor Red
    }
    Catch {
        $e = $_.Exception
        $line = $_.InvocationInfo.ScriptLineNumber

        Write-Host "LINE: $line`n$e" -ForegroundColor Red
    } Finally {
        If ($Null -ne $beetConfig) {
            RestoreBeetConfig($beetConfig)
        }
        If ($Null -ne $initialLocation) {
            $currentLocation = (Get-Location).Path
            If ($currentLocation -ne $initialLocation) {
                Set-Location $initialLocation
            }
        }
    }
}

Function CreateNewFolder($folderName) {
    If (-Not(Test-Path -Path $folderName -PathType Container)) {
        New-Item -ItemType Directory -Path $folderName | Out-Null
    }
}


Function VerifyManifestExists($ManifestPath) {
    If (-Not (Test-Path -Path $albumManifest -PathType Leaf)) {
        Throw ([System.IO.FileNotFoundException]::new("File '$albumManifest' does not exist."))
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

Function DownloadAudio($urls, $noPlaylist, $preferMP3) {
    $preferAvconv = $False
    If (-Not(Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        $preferAvconv = $True
    }
    $downloadCmd = 'youtube-dl'
    If ($preferAvconv) {
        $downloadCmd += ' --prefer-avconv'
    }
    If ($noPlaylist) {
        $downloadCmd += ' --no-playlist'
    }
    $downloadCmd += ' -x --audio-format'
    If ($preferMP3) {
        $downloadCmd += ' mp3'
    }
    Else {
        $downloadCmd += ' m4a'
    }
    $downloadCmd += ' --output ".\%(title)s.%(ext)s" "{0}"'

    Foreach ($url in $urls) {
        Invoke-Expression(($downloadCmd -f $url))
    }
}

Function CleanArtistFolderIfEmpty($artistFolderName) {
    $numFilesInArtistFolder = (Get-ChildItem -Recurse -File -Path $artistFolderName | Measure-Object).Count
    If ($numFilesInArtistFolder -eq 0) {
        Remove-Item -Recurse -Force $artistFolderName
    }
}

Export-ModuleMember -Function @(
    "Get-YoutubeAlbum"
)
