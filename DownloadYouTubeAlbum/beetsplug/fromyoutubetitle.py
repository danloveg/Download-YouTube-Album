""" If the title is empty, set the title to the name of the file, and remove any
extra junk such as (Official Video) or (Audio)
"""

from __future__ import division, absolute_import, print_function
from beets.plugins import BeetsPlugin
from beets.util import displayable_path
from pathlib import Path
import re

class FromYoutubeTitlePlugin(BeetsPlugin):
    def __init__(self):
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
        album_name = str(item_file_path.parent.name)
        artist_name = str(item_file_path.parent.parent.name)
        new_title = remove_common_youtube_junk(youtube_title)
        no_junk_title = remove_album_and_artist(new_title, album_name, artist_name)
        item.title = no_junk_title


YOUTUBE_TITLE_JUNK = [
    re.compile(r'(?P<junk>[\(\[\{](?:[Oo]fficial\s)?(?:[Mm]usic\s)?[Vv]ideo[\)\]\}])'),
    re.compile(r'(?P<junk>[\(\[\{](?:[Oo]fficial\s)?[Aa]udio[\)\]\}])'),
    re.compile(r'(?P<junk>[\(\[\{](?:[Oo]fficial\s)?[Ll]yrics?(?:\s[Vv]ideo)?[\)\]\}])'),
    re.compile(r'(?P<junk>[\(\[\{][Ff]ull\s[Aa]lbum(?:\s[Ss]tream)[\)\]\}])'),
    re.compile(r'(?P<junk>[\(\[\{](?:[Nn][Ee][Ww]\s)?\d{4}[\)\]\}])'),
]


def remove_common_youtube_junk(youtube_title):
    new_title = youtube_title
    for pattern in YOUTUBE_TITLE_JUNK:
        match_obj = pattern.search(new_title)
        if match_obj == None: continue
        new_title = new_title.replace(match_obj.group('junk'), '')
    return new_title.strip()


def remove_album_and_artist(youtube_title, album, artist):
    new_title = youtube_title
    for name in [f'({album})', album, f'({artist})', artist]:
        new_title = new_title.replace(name, '')
    return new_title.strip()
