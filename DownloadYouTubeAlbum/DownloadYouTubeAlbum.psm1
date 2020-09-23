# DownloadYouTubeAlbum.psm1
# Author: Daniel Lovegrove

. $PSScriptRoot\AlbumManifest.ps1
. $PSScriptRoot\Beets.ps1
. $PSScriptRoot\Downloader.ps1
. $PSScriptRoot\Exceptions.ps1
. $PSScriptRoot\FileSystem.ps1
. $PSScriptRoot\ToolVerifier.ps1

Function Get-YoutubeAlbum {
    <#
    .synopsis
    YouTube music album downloader. Solves the problem of having to download
    songs one by one from some youtube to mp3 converter, before tediously
    editing the metadata by hand.

    .description
    Use youtube-dl to download a list of m4a files (or mp3s) from URLs, then use
    beets tool to automatically update metadata and album art.

    .parameter Artist
    The name of the artist who created the album

    .parameter Album
    The name of the album being downloaded

    .parameter Urls
    The list of URLs to download music from

    .parameter AlbumManifest
    A text file containing information required to download and create an album.
    If you do not want to use the literal -Artist -Album & -Urls parameters, you
    can input a manifest file. The file must start with the album and artist
    name (in any order) followed by one or more URLs on each line. The URLs may
    be YouTube playlists. You may place comments in the file after a "#". This
    is a sample album manifest:

    Album: <album name>
    Artist: <artist name>
    https://youtube.com/someplaylist # Contains all songs on the album

    .parameter NoPlaylist
    Avoid downloading YouTube URLs as playlists.

    .parameter PreferMP3
    Encode downloaded audio as MP3, rather than the default m4a.

    .example
    DOWNLOAD ONE PLAYLIST AS AN ALBUM WITH A MANIFEST
    Assume the artist is Foo, and the album is Bar. The album manifest should contain:

    Artist: Foo
    Album: Bar
    https://youtube.com/fooplaylist

    The command to download the album from the manifest:

    $> Get-YoutubeAlbum -AlbumManifest path/to/manifest.txt

    .example
    DOWNLOAD MUTLIPLE DIFFERENT SONGS AS AN ALBUM

    $> Get-YoutubeAlbum -Artist 'Foo' -Album 'Bar', -Urls 'song1', 'song2', 'song3'  -NoPlaylist

    .example
    DOWNLOAD ONE PLAYLIST AS AN ALBUM OF MP3s (NO MANIFEST)

    $> Get-YoutubeAlbum -Artist 'Foo' -Album 'Bar' -Urls 'playlist' -PreferMP3
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True, ParameterSetName='Manifest')]
        [String] $AlbumManifest,

        [Parameter(Mandatory=$True, ParameterSetName='Literal')]
        [String] $Artist,
        [Parameter(Mandatory=$True, ParameterSetName='Literal')]
        [String] $Album,
        [Parameter(Mandatory=$True, ParameterSetName='Literal')]
        [String[]] $Urls,

        [Switch] $NoPlaylist = $False,
        [Switch] $PreferMP3 = $False
    )

    Begin {
        $beetConfig = $NULL
        $initialLocation = (Get-Location).Path
    }

    Process {
        Try {
            VerifyToolsInstalled

            If ($PSCmdlet.ParameterSetName -eq 'Manifest') {
                VerifyManifestExists $AlbumManifest
                $albumManifestContents = GetContentsWithoutComments $AlbumManifest
                $albumData = GetAlbumDataFromManifest $albumManifestContents
            }
            Else {
                $albumData = GetAlbumDataFromLiterals -ArtistName $Artist -AlbumName $Album -Urls $Urls
            }

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
            Write-Host 'File Not Found Exception:' -ForegroundColor Red
            Write-Host "$_" -ForegroundColor Red
        }
        Catch [DependencyException] {
            Write-Host 'Dependency Exception:' -ForegroundColor Red
            Write-Host "$_" -ForegroundColor Red
        }
        Catch [AlbumDataException] {
            Write-Host 'Album Data Exception:' -ForegroundColor Red
            Write-Host "$_" -ForegroundColor Red
        }
        Catch {
            $e = $_.Exception
            $line = $_.InvocationInfo.ScriptLineNumber
            Write-Host "LINE: $line`n$e" -ForegroundColor Red
        }
    }

    End {
        If ($Null -ne $beetConfig) {
            RestoreBeetConfig($beetConfig)
        }
        Set-Location $initialLocation
    }
}

Export-ModuleMember -Function @(
    'Get-YoutubeAlbum'
)

Set-Alias Download-Album 'Get-YoutubeAlbum'

Export-ModuleMember -Alias @(
    'Download-Album'
)
