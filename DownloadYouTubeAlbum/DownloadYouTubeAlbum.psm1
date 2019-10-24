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
    $oldEnvPath = $env:path

    Try {
        If (-Not(VerifyToolsInstalled)) {
            return
        }
        If (-Not (Test-Path -Path $albumManifest -PathType Leaf)) {
            Write-Host ("File '{0}' does not exist." -f $albumManifest)
            return
        }

        $albumManifestContents = (Get-Content $albumManifest)
        If (-Not(VerifyManifestContents($albumManifestContents))) {
            return
        }
        $albumInfo = GetAlbumInfo($albumManifestContents)

        $env:Path = GetNewPathVariable
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
        Set-Location $albumInfo['album']

        # Download the audio into the album folder
        DownloadAudio($albumManifestContents)

        Pop-Location

        # Update the music tags
        beet import $albumInfo['artist']

        # Update the names of the files
        beet move $albumInfo['artist']

        Write-Host
    } Catch {
        Write-Host $_.Exception | Format-List -Force
    } Finally {
        If ($Null -ne $beetConfig) {
            RestoreBeetConfig($beetConfig)
        }
        $env:path = $oldEnvPath
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

        If (-Not(Get-Command beet -ErrorAction SilentlyContinue)) {
            Write-Host "Something went wrong installing beets. See above output." -ForegroundColor Red
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
            If (($Null -eq $uri) -Or -Not($uri.Scheme -match '[http|https]')) {
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

Function DownloadAudio($albumManifestContents) {
    $urls = ($albumManifestContents | Select-Object -Skip 1)

    Foreach ($url in $urls) {
        If (-Not([String]::IsNullOrWhiteSpace($url))) {
            youtube-dl --no-playlist --extract-audio --audio-format mp3 --output ".\%(title)s.%(ext)s" $url
        }
    }
}

Function GetBeetsPlugFolder() {
    return Join-Path -Path $PSScriptRoot -ChildPath "beetsplug"
}

Function GetNewPathVariable() {
    $beetsPlugFolder = GetBeetsPlugFolder
    return ("{0}{1};" -f $env:path, $beetsPlugFolder)
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
    $beetsPlugFolder = GetBeetsPlugFolder

    return @(
       ("directory: {0}" -f ([String] (Get-Location).Path)),
        "import:",
        "    copy: no",
        "",
       ("pluginpath: {0}" -f $beetsPlugFolder),
        "plugins: fromdirname fromfilename fetchart embedart",
        "embedart:",
        "    remove_art_file: yes"
    )
}

Function RestoreBeetConfig($configInfo) {
    Write-Host "Restoring your beet config."
    $configInfo["originalContents"] | Out-File $configInfo["configLocation"]
}

Export-ModuleMember -Function @(
    "Get-YoutubeAlbum"
)