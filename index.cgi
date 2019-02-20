#!/usr/bin/env python
#coding=utf-8

from lib import Presence

class App(Presence):
    admins = ['Vít Baisa', 'Zdeněk Mejzlík', 'Hana Pospíšilová', 'Martin Svoboda', 'jan.vodak']
    coach_ids = [4, 5, 24, 26, 30, 49]
    admin_mails = ['vit.baisa@gmail.com']
    db = 'presence.db'

    def __init__(self):
        Presence.__init__(self, self.db)

if __name__ == '__main__':
    App().serve()
