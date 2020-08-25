#!/usr/bin/env python
#coding=utf-8

from lib import Presence

class App(Presence):
    _admins = ['Vít Baisa', 'Zdeněk Mejzlík', 'Hana Pospíšilová', 'Martin Svoboda', 'jan.vodak', "Marián König"]
    _coach_ids = [4, 5, 24, 26, 30, 49, 97, 98]
    _db = 'presence.db'
    _passfile = ".htpasswd"
    _eventsfile = "/var/www/baisa.net/vitek/presence/events.json"

    def __init__(self):
        Presence.__init__(self, self._db, self._eventsfile)

if __name__ == '__main__':
    App().serve()
