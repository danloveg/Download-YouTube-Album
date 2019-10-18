Function Get-YoutubeAlbum() {
    <#
    .synopsis
    YouTube music album downloader. Solves the problem of having to download
    songs one by one from some youtube to mp3 converter, before tediously
    editing the files by hand.

    .description
    Use youtube-dl to download a list of mp3s from URLs, then use beets tool to
    automatically update metadata and album art.

    .parameter albumManifest
    A text file containing information required to download and create an album.

    .example
    Coming Soon!
    #>
    Param(
        [Parameter(Mandatory=$True)] [String] $albumManifest
    )

    If (VerifyToolsInstalled -eq $False) { return }
}

Function VerifyToolsInstalled() {
    If (-Not(Get-Command python -ErrorAction SilentlyContinue)) {
        Write-Error "Could not find python installation. Go to python.org to install."
        return $False
    }
    If (-Not(Get-Command youtube-dl -ErrorAction SilentlyContinue)) {
        Write-Warning "Could not find youtube-dl, attemtpting to install with pip."

        Write-Host "pip install youtube-dl" -ForegroundColor Green
        pip install youtube-dl

        If (-Not(Get-Command youtube-dl -ErrorAction SilentlyContinue)) {
            Write-Error "Something went wrong installing youtube-dl. See above output"
            return $False
        }
    }
    If (-Not(Get-Command beet -ErrorAction SilentlyContinue)) {
        Write-Warning "Could not find beets, attempting to install with pip."

        Write-Host "pip install beets" -ForegroundColor Green
        pip install beets

        If (-Not(Get-Command beet -ErrorAction SilentlyContinue)) {
            Write-Error "Something went wrong installing beets. See above output."
            return $False
        }
    }

    return $True
}

Export-ModuleMember -Function @(
    "Get-YoutubeAlbum"
)