# DownloadYouTubeAlbum.psm1
# Author: Daniel Lovegrove

. $PSScriptRoot\AlbumManifest.ps1
. $PSScriptRoot\Beets.ps1
. $PSScriptRoot\Downloader.ps1
. $PSScriptRoot\Exceptions.ps1
. $PSScriptRoot\FileSystem.ps1
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

    .parameter AlbumManifest
    A text file containing information required to download and create an album.
    The file must start with the album and artist name in any order, followed by
    one or more URLs. The URLs may be YouTube playlists. This is a sample album
    manifest:

    Album: <album name>
    Artist: <artist name>
    https://youtube.com/someplaylist

    .parameter NoPlaylist
    Avoid downloading YouTube URLs as playlists.

    .parameter PreferMP3
    Encode downloaded audio as MP3, rather than the default m4a.

    .example
    DOWNLOAD ONE PLAYLIST AS AN ALBUM
    Assume the artist is Foo, and the album is Bar. The album manifest should contain:

    Artist: Foo
    Album: Bar
    https://youtube.com/foobarplaylist

    The command to download this album:

    Get-YoutubeAlbum -AlbumManifest path/to/manifest.txt

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

    Get-YoutubeAlbum -AlbumManifest path/to/manifest.txt -NoPlaylist
    #>
    Param(
        [Parameter(Mandatory=$True)]
        [AllowNull($False)]
        [AllowEmptyString($False)]
        [String] $AlbumManifest,
        [Switch] $NoPlaylist = $False,
        [Switch] $PreferMP3 = $False
    )

    $beetConfig = $NULL
    $initialLocation = $NULL

    Try {
        VerifyToolsInstalled
        VerifyManifestExists $AlbumManifest
        $albumManifestContents = GetContentsWithoutComments $AlbumManifest
        $albumData = GetAlbumData $albumManifestContents

        $initialLocation = (Get-Location).Path
        $beetConfig = UpdateBeetConfig $initialLocation
        Push-Location # Add current folder to stack

        CreateNewFolder $albumData['artist']
        Set-Location $albumData['artist']
        Push-Location # Add artist folder to stack

        CreateNewFolder $albumData['album']
        Set-Location $albumData['album']
        Write-Host ("`nDownloading album '{0}' by artist '{1}'`n" -f $albumData['album'], $albumData['artist']) -ForegroundColor Green
        DownloadAudio $albumData['urls'] $NoPlaylist $PreferMP3
        Pop-Location # Pop artist folder from stack

        Write-Host ("`nAttempting to automatically fix music tags.`n") -ForegroundColor Green
        AutoTagAlbum $albumData['album']
        Pop-Location # Pop intial folder from stack

        CleanFolderIfEmpty $albumData['artist']
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

Export-ModuleMember -Function @(
    "Get-YoutubeAlbum"
)

Set-Alias Download-Album 'Get-YoutubeAlbum'

Export-ModuleMember -Alias @(
    'Download-Album'
)
