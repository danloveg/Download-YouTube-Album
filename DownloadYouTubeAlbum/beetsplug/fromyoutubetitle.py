""" If the title is empty, set the title to the name of the file, and remove any
extra junk such as (Official Video) or (Audio)
"""

from __future__ import division, absolute_import, print_function
from beets.plugins import BeetsPlugin
from beets.util import displayable_path
from pathlib import Path

class FromYoutubeTitlePlugin(BeetsPlugin):
    def __init__(self):
        self.register_listener(
            'import_task_start',
            set_titles_no_junk
        )


def set_titles_no_junk(task, session):
    items = task.items if task.is_album else [task.item]

    for item in items:
        if item.title:
            continue