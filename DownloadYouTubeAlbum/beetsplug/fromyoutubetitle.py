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
        self.register_listener(
            'import_task_start',
            set_titles_no_junk
        )


def set_titles_no_junk(task, session):
    items = task.items if task.is_album else [task.item]

    for item in items:
        if item.title: continue
        item_file_path = Path(displayable_path(item.path))
        youtube_title = item_file_path.stem
        album_name = item_file_path.parent.name
        artist_name = item_file_path.parent.parent.name
        new_title = remove_common_youtube_junk(youtube_title)
        no_junk_title = remove_album_and_artist(new_title, album_name, artist_name)
        item.title = no_junk_title


YOUTUBE_TITLE_JUNK = [
    re.compile(r'(?i)(?P<junk>[\(\[\{]\s*(?:Official\s)?(?:Music\s)?Video\s*[\)\]\}])'),
    re.compile(r'(?i)(?P<junk>[\(\[\{]\s*(?:Official\s)?Audio\s*[\)\]\}])'),
    re.compile(r'(?i)(?P<junk>[\(\[\{]\s*(?:Official\s)?Lyrics?(?:\sVideo)?\s*[\)\]\}])'),
    re.compile(r'(?i)(?P<junk>[\(\[\{]\s*Full\sAlbum(?:\sStream)\s*[\)\]\}])'),
    re.compile(r'(?i)(?P<junk>[\(\[\{]\s*(?:New\s)?\d{4}\s*[\)\]\}])'),
]


def remove_common_youtube_junk(youtube_title):
    new_title = youtube_title
    for pattern in YOUTUBE_TITLE_JUNK:
        match_obj = pattern.search(new_title)
        if match_obj == None: continue
        new_title = new_title.replace(match_obj.group('junk'), '')
    return smart_strip(new_title)


def remove_album_and_artist(youtube_title, album, artist):
    new_title = youtube_title
    for name in [f'({album})', album, f'({artist})', artist]:
        new_title = new_title.replace(name, '')
    return smart_strip(new_title)


EXTRA_STRIP_PATTERNS = [
    re.compile(r'^\s?[-_]\s?(?P<title>.+)$'),
    re.compile(r'^(?P<title>.+)\s?[-_]\s?$')
]


def smart_strip(string: str):
    stripped_string = string
    for pattern in EXTRA_STRIP_PATTERNS:
        match_obj = pattern.match(stripped_string)
        if match_obj == None: continue
        stripped_string = match_obj.group('title')
    return stripped_string.strip()
