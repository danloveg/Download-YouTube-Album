"""If the album and artist are empty, try to extract the album and artist from
the directories the file is in. Looks above the file for the album, and above
the album for the artist name.
"""

from __future__ import division, absolute_import, print_function
from beets.plugins import BeetsPlugin
from beets.util import displayable_path
from pathlib import Path


class FromDirectoryNamePlugin(BeetsPlugin):
    def __init__(self):
        super(FromDirectoryNamePlugin, self).__init__()
        self.register_listener('import_task_start', update_album_artist_with_dirnames)


def update_album_artist_with_dirnames(task, session):
    items = task.items if task.is_album else [task.item]

    for item in items:
        if item.album and item.artist:
            continue

        file_path = Path(displayable_path(item.path))

        # The album name is assumed to be the parent of the file
        album_name = str(file_path.parent.name)

        # The artist name is assumed to be the parent of the album
        artist_name = str(file_path.parent.parent.name)

        if not item.album:
            item.album = album_name

        if not item.artist:
            item.artist = artist_name
