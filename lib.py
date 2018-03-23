#!/usr/bin/env python
#coding=utf-8

import os
import sys
import cgi
import sqlite3
import json

"""
TODO: Properties
4. lock N hours before every event
5. lock when limit is reached
"""

class Presence():
    "A lightweight event-presence manager"

    show_last_n = 3
    default_capacity = 16
    lock_n_hours_before = 24
    is_admin = False

    def __init__(self, database):
        self.conn = sqlite3.connect(database)
        self.cursor = self.conn.cursor()
        self.output = sys.stdout

    def events(self):
        n = self.show_last_n
        q = """SELECT * FROM events
                WHERE date(starts) > date('now')
                ORDER BY starts ASC
                LIMIT %d;""" % n
        r = self.cursor.execute(q)
        o = []
        for row in r.fetchall():
            o.append({
                'id': row[0],
                'title': row[1],
                'starts': row[2],
                'ends': row[3],
                'location': row[4],
                'capacity': row[5],
                'courts': row[6],
                'full': False, # TODO
                'locked': False # TODO
            })
        return {'data': o}

    def presence(self, eventid):
        q = """SELECT users.name,
                      presence.userid,
                      presence.guestname,
                      presence.datetime
                FROM presence, users
                WHERE eventid = %d
                AND presence.userid = users.id
                ORDER BY users.name""" % int(eventid)
        r = self.cursor.execute(q)
        o = []
        for row in r.fetchall():
            o.append({
                'username': row[0],
                'userid': row[1],
                'guestname': row[2],
                'datetime': row[3]
            })
        return {'data': o}

    def comments(self, eventid):
        q = """SELECT *
                FROM comments
                WHERE eventid = %d
                ORDER BY datetime DESC;""" % int(eventid)
        r = self.cursor.execute(q)
        o = []
        # TODO: use row_factory
        for row in r.fetchall():
            o.append({
                'id': row[0],
                'eventid': row[1],
                'userid': row[2],
                'datetime': row[3],
                'text': row[4]
            })
        return {'data': o}

    def register_guest(self, guestname, eventid):
        # only admin
        return []

    def register(self, userid, eventid):
        q = """INSERT INTO presence
                (eventid, userid)
                VALUES ("%s", "%s");"""
        r = self.cursor.execute(q)
        # TODO: return the inserted row
        return {'data': 'registered'}

    def unregister(self, userid, eventid):
        # remove attendance
        q = """DELETE * FROM presence
                WHERE userid = %d
                AND eventid = %d""" % (userid, eventid)
        return {'data': 'unregistered'}

    def session(self, userid, cookie):
        # check session, check if user is admin
        return 

    def default(self):
        return {
            'error': 'Unknown or missing method',
            'app': self.__doc__
        }

    def username2userid(self, username):
        q = 'SELECT id FROM users WHERE username = "%s"' % username
        r = self.cursor.execute(q).fetchone()
        return r and r[0] or -1

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
        username = os.getenv('REMOTE_USER', 'anonymous')
        self.userid = self.username2userid(username)
        self.output.write('Content-Type: application/json; charset=utf-8\n\n')
        self.output.write(json.dumps(response) + '\n')

if __name__ == '__main__':
    import datetime
    today = datetime.datetime.now()
    thursday = today + datetime.timedelta(days=3)
    sunday = today + datetime.timedelta(days=6)
    events = [
        {
            'title': 'Pondělí, řízený trénink',
            'location': 'Zetor Líšeň',
            'starts': monday.strftime('%Y-%m-%d 19:00:00'),
            'ends': monday.strftime('%Y-%m-%d 21:00:00'),
            'capacity': 16,
            'courts': 5
        },
        {
            'title': 'Čtvrtek, volná hra',
            'location': 'Zetor Líšeň',
            'starts': thursday.strftime('%Y-%m-%d 19:00:00'),
            'ends': thursday.strftime('%Y-%m-%d 21:00:00'),
            'capacity': 20,
            'courts': 4
        },
        {
            'title': 'Neděle, volná hra',
            'location': 'Zetor Líšeň',
            'starts': sunday.strftime('%Y-%m-%d 19:00:00'),
            'ends': sunday.strftime('%Y-%m-%d 21:00:00'),
            'capacity': 20,
            'courts': 4
        }
    ]
    conn = sqlite3.connect('presence.db')
    cursor = conn.cursor()
    for ev in events:
        q = """INSERT INTO events
               (title, starts, ends, location, capacity, courts)
               VALUES ("%(title)s", "%(starts)s", "%(ends)s",
               "%(location)s", %(capacity)d, %(courts)d);""" % ev
        cursor.execute(q)
