""" fromyoutubetitle Beets Plugin """

from pathlib import Path
import re

from beets.plugins import BeetsPlugin
from beets.util import displayable_path

import tagsfrompath as frompath


class FromYoutubeTitlePlugin(BeetsPlugin):
    """ Sets the title of each item to the filename, removing most of the common
    junk associated with YouTube titles like "(Official Audio)" and the name of
    the album or artist.
    Assumes the music is in an Artist/Album/Song folder structure, and that the
    song file names are the names of the YouTube videos they were extracted
    from.
    """
    def __init__(self):
        super(FromYoutubeTitlePlugin, self).__init__()
        self.register_listener('import_task_start', set_titles_no_junk)


YOUTUBE_TITLE_JUNK = [
    re.compile(r'(?i)(?P<junk>[\(\[\{]\s*Official\s*[\)\]\}])'),
    re.compile(r'(?i)(?P<junk>[\(\[\{]\s*(?:Official\s)?(?:Music\s)?Video\s*[\)\]\}])'),
    re.compile(r'(?i)(?P<junk>[\(\[\{]\s*(?:Official\s|Original\s)?Audio\s*[\)\]\}])'),
    re.compile(r'(?i)(?P<junk>[\(\[\{]\s*(?:Official\s)?Lyrics?(?:\sVideo|\sOn\sScreen)?\s*'
               r'[\)\]\}])'),
    re.compile(r'(?i)(?P<junk>[\(\[\{]\s*Lyrics,\sAudio\s*[\)\]\}])'),
    re.compile(r'(?i)(?P<junk>[\(\[\{]\s*Full\s(?:Album|Song)(?:\sStream)\s*[\)\]\}])'),
    re.compile(r'(?i)(?P<junk>[\(\[\{]\s*(?:New\s)?\d{4}\s*[\)\]\}])'),
    re.compile(r'(?i)(?P<junk>[\(\[\{]\s*iTunes.*?\s*[\)\]\}])'),
    re.compile(r'(?i)(?P<junk>[\(\[\{]\s*(?:Explicit(?:\sVersion)?|Clean(?:\sVersion)?|'
               r'Parental\sAdvisory)\s*[\)\]\}])'),
    re.compile(r'(?i)(?P<junk>[\(\[\{]\s*(?:New\s)?(?:HQ|HD|CDQ)(?:\sVersion)?\s*[\)\]\}])'),
    re.compile(r'(?i)(?P<junk>[\(\[\{]\s*New\sSong(?:\s\d{4})?\s*[\)\]\}])')
]


EXTRA_STRIP_PATTERNS = [
    re.compile(r'^\s*[-_\|]\s*(?P<title>.+)$'),
    re.compile(r'^(?P<title>.+)\s*[-_\|]\s*$')
]


def set_titles_no_junk(task, session):
    items = task.items if task.is_album else [task.item]

    for item in items:
        if item.title:
            continue
        item_file_path = Path(displayable_path(item.path))
        youtube_title = frompath.get_title(item_file_path)
        album_name = frompath.get_album_name(item_file_path)
        artist_name = frompath.get_artist_name(item_file_path)
        artist_album_junk = [
            '(?i)(?P<junk>\\({0}\\))'.format(re.escape(album_name)),
            '(?i)(?P<junk>\\(?{0}\\)?)'.format(re.escape(artist_name))
        ]
        item.title = remove_junk(youtube_title, artist_album_junk, YOUTUBE_TITLE_JUNK)


def remove_junk(title: str, *junk_patterns):
    new_title = title

    for pattern_list in junk_patterns:
        for pattern in pattern_list:
            match_obj = None
            if isinstance(pattern, re.Pattern):
                match_obj = pattern.search(new_title)
            elif isinstance(pattern, str):
                match_obj = re.search(pattern, title)
            if match_obj is not None:
                new_title = new_title.replace(match_obj.group('junk'), '')

    return smart_strip(new_title)


def smart_strip(string: str):
    stripped_string = string
    for pattern in EXTRA_STRIP_PATTERNS:
        match_obj = pattern.match(stripped_string)
        if match_obj is None:
            continue
        stripped_string = match_obj.group('title')
    return stripped_string.strip()
