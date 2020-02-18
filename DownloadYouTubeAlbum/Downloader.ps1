Function DownloadAudio($Urls, $NoPlaylist, $PreferMP3) {
    $preferAvconv = $False
    If (-Not(Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        $preferAvconv = $True
    }
    $downloadCmd = 'youtube-dl'
    If ($preferAvconv) {
        $downloadCmd += ' --prefer-avconv'
    }
    If ($NoPlaylist) {
        $downloadCmd += ' --no-playlist'
    }
    $downloadCmd += ' -x --audio-format'
    If ($PreferMP3) {
        $downloadCmd += ' mp3'
    }
    Else {
        $downloadCmd += ' m4a'
    }
    $downloadCmd += ' --output ".\%(title)s.%(ext)s" "{0}"'

    Foreach ($url in $Urls) {
        Invoke-Expression -Command ($downloadCmd -f $url)
    }
}