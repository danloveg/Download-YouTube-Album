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
    The file must have the following contents:

    Artist Name|Album Name
    https://youtube.com/someurl1....
    https://youtube.com/someurl2...
    https://youtube.com/someurl3...

    .example
    Coming Soon!
    #>
    Param(
        [Parameter(Mandatory=$True)] [String] $albumManifest
    )

    $beetConfig = $NULL

    Try {
        If (-Not(VerifyToolsInstalled)) {
            return
        }

        $beetConfig = UpdateBeetConfig

        If (-Not (Test-Path -Path $albumManifest -PathType Leaf)) {
            Write-Host ("File '{0}' does not exist." -f $albumManifest)
            return
        }

        $albumManifestContents = (Get-Content $albumManifest)

        If (-Not(VerifyManifestContents($albumManifestContents))) {
            return
        }

        $albumInfo = GetAlbumInfo($albumManifestContents)

        Push-Location

        If (-Not(Test-Path -Path $albumInfo['artist'] -PathType Container)) {
            New-Item -ItemType Directory -Path $albumInfo['artist'] | Out-Null
        }
        Set-Location $albumInfo['artist']
        # TODO: What if the album folder exists and there are files in it?
        If (-Not(Test-Path -Path $albumInfo['album'] -PathType Container)) {
            New-Item -ItemType Directory -Path $albumInfo['album'] | Out-Null
        }
        Set-Location $albumInfo['album']

        # Download videos here

        Pop-Location
    } Catch {
        Write-Host $_.Exception | Format-List -Force
    } Finally {
        If ($beetConfig -ne $NULL) {
            RestoreBeetConfig($beetConfig)
        }
    }
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

Function VerifyManifestContents([String[]] $contents) {
    If ($contents.Length -eq 0) {
        Write-Error "Album manifest file appears to be empty."
        return $False
    }

    $firstLine = $contents[0]
    $firstLineContents = $firstLine.Split('|')
    If ($firstLineContents.Length -ne 2) {
        Write-Error "First line of file is not in the correct format. Should be <Artist Name>|<Album Name>"
        return $False
    }

    $secondLineAndLater = ($contents | Select-Object -Skip 1)
    Foreach ($line in $secondLineAndLater) {
        If (-Not([String]::IsNullOrWhiteSpace($line))) {
            $uri = $line -as [System.URI]
            If ($uri -eq $null -Or -Not($uri.Scheme -match '[http|https]')) {
                Write-Error ("The line `"{0}`" does not appear to be a url" -f $line)
                return $False
            }
        }
    }

    return $True
}

Function GetAlbumInfo($contents) {
    $firstLineSplit = $contents[0].Split('|')
    $albumInfo = @{}
    $albumInfo.Add("artist", $firstLineSplit[0])
    $albumInfo.Add("album", $firstLineSplit[1])

    return $albumInfo
}

# Beet config processing
Function UpdateBeetConfig() {
    $configLocation = [String](beet config -p)
    $origContents = @()

    If (-Not (Test-Path -Path $configLocation -PathType Leaf)) {
        Write-Host ("Creating a new beet default config file.")
        New-Item -ItemType File -Path $configLocation
    } Else {
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
    return @(
        "import:",
        "    copy: no",
        "",
        "plugins: fromfilename embedart fetchart"
    )
}

Function RestoreBeetConfig($configInfo) {
    Write-Host "Restoring your beet config."
    $configInfo["originalContents"] | Out-File $configInfo["configLocation"]
}

Export-ModuleMember -Function @(
    "Get-YoutubeAlbum"
)