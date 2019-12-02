""" If the title is empty, set the title to the name of the file without any
junk, which can include:
(Official Video)
{Audio}
(Music Video)
[ New 2019 ]
Artist Name
Album Name
"""

from beets.plugins import BeetsPlugin
from beets.util import displayable_path
from pathlib import Path
import re

class FromYoutubeTitlePlugin(BeetsPlugin):
    def __init__(self):
        super(FromYoutubeTitlePlugin, self).__init__()
        self.register_listener('import_task_start', set_titles_no_junk)


YOUTUBE_TITLE_JUNK = [
    re.compile(r'(?i)(?P<junk>[\(\[\{]\s*Official\s*[\)\]\}])'),
    re.compile(r'(?i)(?P<junk>[\(\[\{]\s*(?:Official\s)?(?:Music\s)?Video\s*[\)\]\}])'),
    re.compile(r'(?i)(?P<junk>[\(\[\{]\s*(?:Official\s|Original\s)?Audio\s*[\)\]\}])'),
    re.compile(r'(?i)(?P<junk>[\(\[\{]\s*(?:Official\s)?Lyrics?(?:\sVideo|\sOn\sScreen)?\s*[\)\]\}])'),
    re.compile(r'(?i)(?P<junk>[\(\[\{]\s*Lyrics,\sAudio\s*[\)\]\}])'),
    re.compile(r'(?i)(?P<junk>[\(\[\{]\s*Full\s(?:Album|Song)(?:\sStream)\s*[\)\]\}])'),
    re.compile(r'(?i)(?P<junk>[\(\[\{]\s*(?:New\s)?\d{4}\s*[\)\]\}])'),
    re.compile(r'(?i)(?P<junk>[\(\[\{]\s*iTunes.*?\s*[\)\]\}])'),
    re.compile(r'(?i)(?P<junk>[\(\[\{]\s*(?:Explicit(?:\sVersion)?|Clean(?:\sVersion)?|Parental\sAdvisory)\s*[\)\]\}])'),
    re.compile(r'(?i)(?P<junk>[\(\[\{]\s*(?:New\s)?(?:HQ|HD|CDQ)(?:\sVersion)?\s*[\)\]\}])'),
    re.compile(r'(?i)(?P<junk>[\(\[\{]\s*New\sSong(?:\s\d{4})?\s*[\)\]\}])')
]


EXTRA_STRIP_PATTERNS = [
    re.compile(r'^\s*[-_]\s*(?P<title>.+)$'),
    re.compile(r'^(?P<title>.+)\s*[-_]\s*$')
]


def set_titles_no_junk(task, session):
    items = task.items if task.is_album else [task.item]

    for item in items:
        if item.title: continue
        item_file_path = Path(displayable_path(item.path))
        youtube_title = get_title_from_path(item_file_path)
        album_name = get_album_name_from_path(item_file_path)
        artist_name = get_artist_name_from_path(item_file_path)
        new_title = remove_common_youtube_junk(youtube_title)
        no_junk_title = remove_album_and_artist(new_title, album_name, artist_name)
        item.title = no_junk_title


def get_title_from_path(p: Path):
    return p.stem


def get_album_name_from_path(p: Path):
    return p.parent.name


def get_artist_name_from_path(p: Path):
    return p.parent.parent.name


def remove_common_youtube_junk(youtube_title: str):
    new_title = youtube_title
    for pattern in YOUTUBE_TITLE_JUNK:
        match_obj = pattern.search(new_title)
        if match_obj == None: continue
        new_title = new_title.replace(match_obj.group('junk'), '')
    return smart_strip(new_title)


def remove_album_and_artist(youtube_title: str, album: str, artist: str):
    new_title = youtube_title
    for name in [f'({album})', f'({artist})', artist]:
        if name in new_title:
            new_title = new_title.replace(name, '')
    return smart_strip(new_title)


def smart_strip(string: str):
    stripped_string = string
    for pattern in EXTRA_STRIP_PATTERNS:
        match_obj = pattern.match(stripped_string)
        if match_obj == None: continue
        stripped_string = match_obj.group('title')
    return stripped_string.strip()
