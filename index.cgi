#!/usr/bin/env python
#coding=utf-8

from lib import Presence

class App(Presence):
    admins = ['Vít Baisa', 'Zdeněk Mejzlík', 'Hana Pospíšilová', 'Martin Svoboda', 'jan.vodak', "Marián König"]
    coach_ids = [4, 5, 24, 26, 30, 49]
    db = 'presence.db'
    passfile = ".htpasswd"

    def __init__(self):
        Presence.__init__(self, self.db)

if __name__ == '__main__':
    App().serve()
