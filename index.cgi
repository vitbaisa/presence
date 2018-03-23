#!/usr/bin/env python

from lib import Presence

class App(Presence):
    admins = ['vit_baisa', 'hana_pospisilova', 'martin_svoboda']
    db = 'presence.db'

    def __init__(self):
        Presence.__init__(self, self.db)

if __name__ == '__main__':
    App().serve()
