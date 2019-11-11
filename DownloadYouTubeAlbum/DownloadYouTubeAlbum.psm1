Function Get-YoutubeAlbum() {
    <#
    .synopsis
    YouTube music album downloader. Solves the problem of having to download
    songs one by one from some youtube to mp3 converter, before tediously
    editing the metadata by hand.

    .description
    Use youtube-dl to download a list of mp3s from URLs, then use beets tool to
    automatically update metadata and album art.

    .parameter albumManifest
    A text file containing information required to download and create an album.
    The file must start with the album and artist name in any order, followed by
    one or more URLs. The URLs may be YouTube playlists. This is a sample album
    manifest:

    Album: <album name>
    Artist: <artist name>
    https://youtube.com/someplaylist

    .parameter isPlaylist
    Download YouTube URLs as playlists.

    .example
    DOWNLOAD ONE PLAYLIST AS AN ALBUM
    Assume the artist is Foo, and the album is Bar. The album manifest should contain:

    Artist: Foo
    Album: Bar
    https://youtube.com/foobarplaylist

    The command to download this album:

    Get-YoutubeAlbum -albumManifest path/to/manifest.txt -isPlaylist

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

    Get-YoutubeAlbum path/to/manifest.txt
    #>
    Param(
        [Parameter(Mandatory=$True)] [String] $albumManifest,
        [Switch] $isPlaylist = $False
    )

    $beetConfig = $NULL
    $initialLocation = $NULL

    Try {
        If (-Not(VerifyToolsInstalled)) {
            return
        }
        If (-Not (Test-Path -Path $albumManifest -PathType Leaf)) {
            Write-Host ("File '{0}' does not exist." -f $albumManifest) -ForegroundColor Red
            return
        }

        $albumManifestContents = (Get-Content $albumManifest)
        If (-Not(VerifyManifestContents($albumManifestContents))) {
            return
        }
        $albumInfo = GetAlbumInfo($albumManifestContents)

        $beetConfig = UpdateBeetConfig

        Push-Location

        If (-Not(Test-Path -Path $albumInfo['artist'] -PathType Container)) {
            New-Item -ItemType Directory -Path $albumInfo['artist'] | Out-Null
        }
        Set-Location $albumInfo['artist']
        # TODO: What if the album folder exists and there are files in it?
        If (-Not(Test-Path -Path $albumInfo['album'] -PathType Container)) {
            New-Item -ItemType Directory -Path $albumInfo['album'] | Out-Null
        }

        # Download the audio into the album folder
        Push-Location
        Set-Location $albumInfo['album']
        Write-Host ("`nDownloading album '{0}' by artist '{1}'`n" -f $albumInfo['album'], $albumInfo['artist']) -ForegroundColor Green
        DownloadAudio $albumManifestContents $isPlaylist
        Pop-Location

        # Update the music tags
        Write-Host ("`nAttempting to automatically fix music tags.`n") -ForegroundColor Green
        beet import $albumInfo['album']

        # Update the names of the files
        Write-Host ("`nRenaming mus`ic file names.`n") -ForegroundColor Green
        beet move $albumInfo['album']

        Write-Host

        Pop-Location
    } Catch {
        $e = $_.Exception
        $line = $_.InvocationInfo.ScriptLineNumber

        Write-Host "LINE: $line`n$e" -ForegroundColor Red
    } Finally {
        If ($Null -ne $beetConfig) {
            RestoreBeetConfig($beetConfig)
        }
    }
}

Function VerifyToolsInstalled() {
    If (-Not(Get-Command python -ErrorAction SilentlyContinue)) {
        Write-Host "Could not find python installation. Go to python.org to install." -ForegroundColor Red
        return $False
    }
    If (-Not(Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        Write-Host "Could not find FFmpeg installation. Go to ffmpeg.org to install." -ForegroundColor Red
        return $False
    }
    If (-Not(Get-Command youtube-dl -ErrorAction SilentlyContinue)) {
        Write-Warning "Could not find youtube-dl, attemtpting to install with pip."

        Write-Host "pip install youtube-dl" -ForegroundColor Green
        pip install youtube-dl

        If (-Not(Get-Command youtube-dl -ErrorAction SilentlyContinue)) {
            Write-Host "Something went wrong installing youtube-dl. See above output" -ForegroundColor Red
            return $False
        }
    }
    If (-Not(Get-Command beet -ErrorAction SilentlyContinue)) {
        Write-Warning "Could not find beets, attempting to install with pip."

        Write-Host "pip install beets" -ForegroundColor Green
        pip install beets
        pip install requests

        If (-Not(Get-Command beet -ErrorAction SilentlyContinue)) {
            Write-Host "Something went wrong installing beets. See above output." -ForegroundColor Red
            return $False
        }
    }

    return $True
}

Function VerifyManifestContents([String[]] $contents) {
    If ($contents.Length -eq 0) {
        Write-Host "Album manifest file appears to be empty." -ForegroundColor Red
        return $False
    }
    If ($contents.Length -lt 3) {
        Write-Host "Album manifest file requires at least three lines for artist, album, and URL" -ForegroundColor Red
    }

    $firstLine = $contents[0]
    $secondLine = $contents[1]

    If ($firstLine -Match "^[Aa]rtist:\s*.+$") {
        If ($secondLine -NotMatch "^[Aa]lbum:\s*.+$") {
            Write-Host "Second line of manifest file must start with 'Album:'" -ForegroundColor Red
            return $False
        }
    }
    ElseIf ($firstLine -Match "^[Aa]lbum:\s*.+$") {
        If ($secondLine -NotMatch "^[Aa]rtist:\s*.+$") {
            Write-Host "Second line of manifest file must start with 'Artist:'" -ForegroundColor Red
            return $False
        }
    }
    Else {
        Write-Host "First line of manifest file must start with 'Album:' or 'Artist:'" -ForegroundColor Red
        return $False
    }

    $thirdLineAndLater = ($contents | Select-Object -Skip 2)

    Foreach ($line in $thirdLineAndLater) {
        If (-Not([String]::IsNullOrWhiteSpace($line))) {
            $uri = $line -as [System.URI]
            If (($Null -eq $uri) -Or -Not($uri.Scheme -match '[http|https]')) {
                Write-Host ("The line `"{0}`" does not appear to be a url" -f $line) -ForegroundColor Red
                return $False
            }
        }
    }

    return $True
}

Function GetAlbumInfo($contents) {
    $firstLine = $contents[0]
    $secondLine = $contents[1]

    $ArtistName = ''
    $AlbumName = ''

    $artistMatch = "^[Aa]rtist:\s*(.+)$"
    $albumMatch = "^[Aa]lbum:\s*(.+)$"

    $firstLineArtistMatch = [Regex]::Match($firstLine, $artistMatch)
    $firstLineAlbumMatch = [Regex]::Match($firstLine, $albumMatch)

    If ($firstLineArtistMatch.Success) {
        $ArtistName = ([String] $firstLineArtistMatch.Groups[1].Value).Trim()
        $secondLineAlbumMatch = [Regex]::Match($secondLine, $albumMatch)
        $AlbumName = ([String] $secondLineAlbumMatch.Groups[1].Value).Trim()
    }
    ElseIf ($firstLineAlbumMatch.Success) {
        $AlbumName = ([String] $firstLineAlbumMatch.Groups[1].Value).Trim()
        $secondLineArtistMatch = [Regex]::Match($secondLine, $artistMatch)
        $ArtistName = ([String] $secondLineArtistMatch.Groups[1].Value).Trim()
    }
    Else {
        Write-Host "Error getting album info. Could not find 'Artist:' or 'Album:' in first line of manifest." -ForegroundColor Red
        return $NULL
    }

    $albumInfo = @{}
    $albumInfo.Add("artist", $ArtistName)
    $albumInfo.Add("album", $AlbumName)

    return $albumInfo
}

Function DownloadAudio($albumManifestContents, $isPlaylist) {
    $urls = ($albumManifestContents | Select-Object -Skip 2)

    Foreach ($url in $urls) {
        If (-Not([String]::IsNullOrWhiteSpace($url))) {
            If ($isPlaylist -eq $True) {
                youtube-dl --extract-audio --audio-format mp3 --output ".\%(title)s.%(ext)s" $url
            }
            Else {
                youtube-dl --no-playlist --extract-audio --audio-format mp3 --output ".\%(title)s.%(ext)s" $url
            }
        }
    }
}

Function GetBeetsPlugFolder() {
    return Join-Path -Path $PSScriptRoot -ChildPath "beetsplug"
}

# Beet config processing
Function UpdateBeetConfig() {
    $configLocation = [String](beet config -p)
    $origContents = @()

    If (-Not (Test-Path -Path $configLocation -PathType Leaf)) {
        Write-Host ("Creating a new beet default config file.")
        New-Item -ItemType File -Path $configLocation
    }
    Else {
        Write-Host ("Overwriting beet config, to be restored after processing.")
        $origContents = (Get-Content $configLocation)
    }

    GetDefaultBeetConfig | Out-File $configLocation

    $configInfo = @{}
    $configInfo.Add("configLocation", $configLocation)
    $configInfo.Add("originalContents", $origContents)
    return $configInfo
}

Function GetDefaultBeetConfig() {
    $beetsPlugFolder = GetBeetsPlugFolder

    return @(
       ("directory: {0}" -f ([String] (Get-Location).Path)),
        "import:",
        "    copy: no",
        "",
       ("pluginpath: {0}" -f $beetsPlugFolder),
        "plugins: fromdirname fromfilename fetchart embedart",
        "embedart:",
        "    remove_art_file: yes",
        "fetchart:",
        "    maxwidth: 512"
    )
}

Function RestoreBeetConfig($configInfo) {
    Write-Host "Restoring your beet config."
    $configInfo["originalContents"] | Out-File $configInfo["configLocation"]
}

Export-ModuleMember -Function @(
    "Get-YoutubeAlbum"
)
