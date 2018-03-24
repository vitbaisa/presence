#!/usr/bin/env python
#coding=utf-8

import os
import sys
import cgi
import sqlite3
import json

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
        # TODO: lock when capacity is full
        # TODO: lock N hours before event starts
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

    def register(self, eventid):
        q = """INSERT INTO presence
                (eventid, userid)
                VALUES ("%s", "%s");""" % (int(eventid), self.userid)
        r = self.cursor.execute(q)
        self.conn.commit()
        return {'data': 'registered'}

    def unregister(self, eventid):
        q = """DELETE FROM presence
                WHERE userid = %d
                AND eventid = %d""" % (self.userid, int(eventid))
        r = self.cursor.execute(q)
        self.conn.commit()
        return {'data': 'unregistered'}

    def default(self):
        return {
            'error': 'Unknown or missing method',
            'app': self.__doc__
        }

    def get_user(self, username):
        q = 'SELECT * FROM users WHERE username = "%s"' % username
        r = self.cursor.execute(q).fetchone()
        if r:
            return {
                'id': r[0],
                'username': r[1],
                'name': r[2],
                'last_access': r[3],
                'email': r[4],
                'admin': r[1] in self.admins
            }
        return {}

    def serve(self):
        form = cgi.FieldStorage()
        parse_url = os.getenv('PATH_INFO', '').strip().split('/')
        if len(parse_url) > 1:
            methodname = parse_url[1]
            method = getattr(self, methodname, self.default)
        else:
            method = self.default
        username = os.getenv('REMOTE_USER', 'anonymous')
        user = self.get_user(username)
        self.userid = user['id']
        parameters = dict([(k, form.getvalue(k)) for k in form])
        response = apply(method, [], parameters)
        response['user'] = user
        self.output.write('Content-Type: application/json; charset=utf-8\n\n')
        self.output.write(json.dumps(response) + '\n')

if __name__ == '__main__':
    import datetime
    next_week = datetime.datetime.now() + datetime.timedelta(days=7)
    day = datetime.datetime.today().weekday()
    titles = {
        0: 'Pondělí, řízený trénink',
        3: 'Čtvrtek, volná hra',
        6: 'Neděle, volná hra'
    }
    capacity = {0: 20, 3: 16, 6: 16}
    courts = {0: 5, 3: 4, 6: 4}
    event = {
        'title': titles[day],
        'location': 'Zetor Líšeň',
        'starts': next_week.strftime('%Y-%m-%d 19:00:00'),
        'ends': next_week.strftime('%Y-%m-%d 21:00:00'),
        'capacity': capacity[day],
        'courts': courts[day]
    }
    conn = sqlite3.connect('presence.db')
    cursor = conn.cursor()
    q = """INSERT INTO events
            (title, starts, ends, location, capacity, courts)
            VALUES ("%(title)s", "%(starts)s", "%(ends)s",
            "%(location)s", %(capacity)d, %(courts)d);""" % event
    cursor.execute(q)
