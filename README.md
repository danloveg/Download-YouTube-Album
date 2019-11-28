![PowerShell](powershell.png)

# Get-YouTubeAlbum

Are you annoyed by how tedious it is to download single MP3s from YouTube to make an album? Are you also annoyed by how tedious the work is to manually edit the tags of the music?

**Get-YouTubeAlbum automatically handles most of the tedious work involved in downloading an album from YouTube and lets you listen to your favourite music faster.**

To download an album from YouTube, you simply need to:

1. Create a text file containing YouTube links, the Album name, and the Artist name
2. Call `Get-YouTubeAlbum` with the text file

The text file you need to write is very simple. The following is an example of one:

```
Artist: Your Favourite Artist
Album: Greatest Hits
https://youtube.com/link_to_album_playlist_on_youtube
```

`Get-YouTubeAlbum` will download all of the audio from the YouTube links you specified into an `Artist/Album` folder, and will automatically correct all of the MP3 tags as well as embed the album art. It will automatically download all of the songs from a playlist of songs too, unless you don't want it to. Cool!

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

`Get-YouTubeAlbum [-albumManifest] <path to text file> [-noPlaylist]`

If you want more information, you can get help in PowerShell:

`Get-Help Get-YouTubeAlbum -Full`

The process of downloading an album represented in the `albumManifest` file is *almost always completely automatic*. But sometimes, the underlying program [beets](https://beets.io) will ask you to make a decision. This will happen if the songs names downloaded are not very similar to the actual song names in the album, or possibly if you mistyped the album or artist name in the text file. There are two cases where beets may ask you to make a decision:

### Beets Decision A: Which Album to Use?

If beets is unsure of what album you just tried downloading, it will present you with a prompt similar to the following:

```
C:\Users\lovegrod\Music\Young Thug\Super Slimey (13 items)
Finding tags for album "Young Thug - Super Slimey".
Candidates:
1. Future & Young Thug - SUPER SLIMEY (62.8%) (tracks, artist) (Digital Media, 2017, US, Epic, explicit version)
2. Young Thug - 1017 Thug 3: The Finale (47.0%) (tracks, album) (Digital Media, 2014, XW)
3. Young Thug - I Came From Nothing (39.4%) (tracks, album) (Digital Media, 2011, US, Archive Entertainment)
4. Young Thug - Barter 6 (37.5%) (tracks, album) (Digital Media, 2015, US, Atlantic)
5. Young Thug - Slime Season 2 (33.7%) (tracks, missing tracks, album) (Digital Media, 2015, XW)
# selection (default 1), Skip, Use as-is, as Tracks, Group albums,
Enter search, enter Id, aBort?
```

If you press enter at the prompt, it will assume you meant to download album #1. You can also enter any number from 1-5 if any of the other albums are the ones you meant to download. If all of the candidates are wrong, you can press `E` and hit enter which will allow you to search for the correct album.

### Beets Decision B: Should Titles be Changed?

So beets either found the correct album or you entered which album you wanted it to use. But it stops again because it's unsure if it should change the track titles. Beets will give you a prompt similar to the following:

```
Correcting tags from:
    Young Thug - Super Slimey
To:
    Future & Young Thug - SUPER SLIMEY
URL:
    https://musicbrainz.org/release/0baf1bae-9935-4770-987a-d81e9dd7e497
(Similarity: 62.8%) (tracks, artist) (Digital Media, 2017, US, Epic, explicit version)
 * Future & Young Thug - No Cap (Super Slimey) (#0) ->
   No Cap (#1) (title)
 * Future & Young Thug - Three (Super Slimey) (#0) ->
   Three (#2) (title)
 * Future & Young Thug - All Da Smoke (Super Slimey) (#0) ->
   All da Smoke (#3) (title)
 * Future & Young Thug - 200 (Super Slimey) (#0) ->
   200 (#4) (title)
 * Young Thug - Cruise Ship (Super Slimey) (#0) ->
   Cruise Ship (#5) (title)
 * Future & Young Thug - Patek Water ft. Offset (Super Slimey) (#0) ->
   Patek Water (#6) (title)
 * Future - Feed Me Dope (Super Slimey) (#0) ->
   Feed Me Dope (#7) (title)
 * Future & Young Thug - Drip On Me (Super Slimey) (#0) ->
   Drip on Me (#8) (title)
 * Future & Young Thug - Real Love (Super Slimey) (#0) ->
   Real Love (#9) (title)
 * Future - 4 Da Gang (Super Slimey) (#0) ->
   4 da Gang (#10) (title)
 * Young Thug - Killed Before (Super Slimey) (#0) ->
   Killed Before (#11) (title)
 * Future & Young Thug - Mink Flow (Super Slimey) (#0) ->
   Mink Flow (#12) (title)
 * Future & Young Thug - Group Home (Super Slimey) (#0) ->
   Group Home (#13) (title)
Apply, More candidates, Skip, Use as-is, as Tracks, Group albums,
Enter search, enter Id, aBort?
```

Typically, you can just enter `A` and press `Enter` to "`A`pply" the changes. The arrow `->` indicates what it will rename the title of the track.