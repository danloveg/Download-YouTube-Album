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
        path_stem = item_file_path.stem
        new_title = remove_common_youtube_junk(path_stem)
        item.title = new_title


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
        new_title.replace(match_obj.group('junk'), '')

    return new_title.strip()