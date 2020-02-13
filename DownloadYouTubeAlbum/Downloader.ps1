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