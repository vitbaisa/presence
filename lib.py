#!/usr/bin/env python
#coding=utf-8

import os
import sys
import cgi
import sqlite3
import json

"""
TODO: Properties
1. invite guest (for admins?)
2. each event has a limit number of players
3. responsive, fast, simple, small
4. lock N hours before every event
5. lock when limit is reached
"""

class Presence():
    "A lightweight event-presence manager"

    show_last_n = 3
    default_limit = 16
    lock_n_hours_before = 24

    def __init__(self, database):
        self.conn = sqlite3.connect(database)
        self.cursor = self.conn.cursor()
        self.output = sys.stdout

    def get_users(self):
        return []

    def get_last_events(self, n=self.show_last_n):
        # returns ids of last n events
        return []

    def register(self, userid, eventid):
        # save attendance
        return {'data': 'User has registered for the event'}

    def unregister(self, userid, eventid):
        # remove attendance
        return {'data': 'User has unregistered from the event'}

    def session(self, userid, cookie):
        # check session
        return 


    def last_n_

    def default(self):
        return {
            'error': 'Unknown or missing method',
            'app': self.__doc__
        }

    def serve(self):
        form = cgi.FieldStorage()
        parse_url = os.getenv('PATH_INFO', '').strip().split('/')
        if len(parse_url) > 1:
            methodname = parse_url[1]
            method = getattr(self, methodname, self.default)
        else:
            method = self.default
        parameters = dict([(k, form.getvalue(k)) for k in form])
        response = apply(method, [], parameters)
        self.output.write('Content-Type: application/json; charset=utf-8\n\n')
        self.output.write(json.dumps(response) + '\n')

if __name__ == '__main__':
    events = [
        {
            'day': 1,
            'location': 'Zetor Líšeň',
            'title': 'Pondělní řízený trénink',
            'limit': 16,
            'from': '19:00:00',
            'to': '21:00:00',
        },
        {
            'day': 4,
            'location': 'Zetor Líšeň',
            'title': 'Čtvrteční trénink',
            'limit': 16,
            'from': '19:00:00',
            'to': '21:00:00',
        }
    ]
    # TODO: create new event
