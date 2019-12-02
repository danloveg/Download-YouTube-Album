![PowerShell](powershell.png)

# Get-YouTubeAlbum

Are you annoyed by how tedious it is to download single songs from YouTube to make an album? Are you also annoyed by how tedious the work is to manually edit the tags of the music?

**Get-YouTubeAlbum automatically handles most of the tedious work involved in downloading an album from YouTube and lets you listen to your favourite music faster.**

To download an album from YouTube, you simply need to:

1. Create a text file containing YouTube links to the songs you want, the Album name for the songs, and the Artist's name
2. Call `Get-YouTubeAlbum` with the text file

The text file you need to write is very simple. The following is an example of one:

```
Artist: Your Favourite Artist
Album: Greatest Hits
https://youtube.com/link_to_album_playlist_on_youtube
```

`Get-YouTubeAlbum` will download all of the audio from the YouTube links you specified into an `Artist/Album` folder, and will automatically correct all of the tags as well as embed the album art. It will automatically download all of the songs from a playlist of songs too, unless you don't want it to. Cool!

## How to Install It

This is how you install it.

### Dependencies

The following programs must be installed manually for `Get-YouTubeAlbum` to work:

- [python](https://python.org)
- [ffmpeg](https://ffmpeg.org) : youtube-dl uses this to convert downloaded audio into mp3 format.

The following programs are installed automatically if you don't have it, using Python's `pip`

- [youtube-dl](https://ytdl-org.github.io/youtube-dl/index.html) : Downloads audio from YouTube URLs.
- [beets](https://beets.io) : Automatically fetches and updates metadata for downloaded audio.

## How to Use It

Since this tool is written in PowerShell, it must be used from PowerShell. The tool's invocation is very simple:

`Get-YouTubeAlbum [-albumManifest] <path to text file> [-noPlaylist] [-preferMP3]`

If you want more information, you can get help in PowerShell:

`Get-Help Get-YouTubeAlbum -Full`

### Beets Prompted me for Input, What do I do?

The process of downloading an album represented in the `albumManifest` file is *almost always completely automatic*. But sometimes, the underlying program [beets](https://beets.io) will ask you to make a decision. This will happen if the songs names downloaded are not very similar to the actual song names in the album, or possibly if you mistyped the album or artist name in the text file.

If beets prompts you to enter input but you do not know how to proceed, I recommend reading [this short page](https://beets.readthedocs.io/en/stable/guides/tagger.html#similarity) in the beets documentation to become familiar with your options for input in these situations. *Don't be deterred by this!* Beets is simple to interact with in these instances. You'll typically only need to press `Enter`, or tell beets to Apply the changes with "`A`".