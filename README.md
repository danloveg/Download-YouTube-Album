# Get-YouTubeAlbum

PowerShell tool that downloads a series of mp3s from YouTube and compiles them into an album with proper metadata and album art.



## Dependencies

The following programs must be installed manually for the album downloader to work:

- [python](https://python.org)
- [ffmpeg](https://ffmpeg.org) : youtube-dl uses this to convert downloaded audio into mp3 format.

The following programs are installed automatically if you don't have it, using Python's `pip`

- [youtube-dl](https://ytdl-org.github.io/youtube-dl/index.html) : Downloads audio from YouTube URLs.
- [beets](https://beets.io) : Automatically fetches and updates metadata for downloaded audio.