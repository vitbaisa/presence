#!/usr/bin/env python
#coding=utf-8

import os
import sys
import cgi
import sqlite3
import json
import datetime
from dateutil import tz

class Presence():
    "A lightweight event-presence manager"

    show_last_n = 3
    default_capacity = 16
    lock_n_hours_before = 24 # TODO
    is_admin = False

    def __init__(self, database):
        self.conn = sqlite3.connect(database)
        self.cursor = self.conn.cursor()
        self.output = sys.stdout

    def events(self):
        n = self.show_last_n
        q = """SELECT * FROM events
                WHERE date(starts) >= date('now')
                ORDER BY starts ASC
                LIMIT %d;""" % n
        r = self.cursor.execute(q)
        o = []
        for row in r.fetchall():
            o.append({
                'id': row[0],
                'title': row[1],
                'starts': self.utc2local(row[2]),
                'ends': self.utc2local(row[3]),
                'location': row[4],
                'capacity': row[5],
                'courts': row[6],
                'locked': self.soon(row[2])
            })
        return {'data': o}

    def capacity(self, eventid, capacity):
        if self.is_admin:
            q = """UPDATE events SET capacity = %d
                    WHERE id = %d""" % (int(capacity), int(eventid))
            r = self.cursor.execute(q)
            self.conn.commit()
            return {'data': 'Event updated'}
        else:
            return {'error': 'You are not admin'}

    def presence(self, eventid):
        q = """SELECT users.name,
                      presence.userid,
                      presence.guestname,
                      presence.datetime
                FROM presence, users
                WHERE eventid = %d
                AND presence.userid = users.id
                ORDER BY presence.datetime""" % int(eventid)
        r = self.cursor.execute(q)
        o = []
        for row in r.fetchall():
            o.append({
                'username': row[0],
                'userid': row[1],
                'guestname': row[2],
                'datetime': self.utc2local(row[3])
            })
        # guests
        q = """SELECT * FROM presence
               WHERE eventid = %d
               AND guestname != "";""" % int(eventid)
        r = self.cursor.execute(q)
        for row in r.fetchall():
            o.append({
                'guestname': row[3],
                'datetime': self.utc2local(row[4])
            })
        return {'data': o}

    def add_comment(self, eventid, comment):
        q = """INSERT INTO comments
                (eventid, userid, text)
                VALUES (%d, %d, "%s")""" % (int(eventid), self.userid, comment)
        r = self.cursor.execute(q)
        self.conn.commit()
        # TODO: sent comment id
        return {'data': 'OK'}

    def comments(self, eventid):
        q = """SELECT comments.id,
                    comments.eventid,
                    comments.userid,
                    comments.datetime,
                    comments.text,
                    users.name
                FROM comments, users
                WHERE eventid = %d
                AND users.id = comments.userid
                ORDER BY datetime DESC;""" % int(eventid)
        r = self.cursor.execute(q)
        o = []
        # TODO: use row_factory
        for row in r.fetchall():
            o.append({
                'id': row[0],
                'eventid': row[1],
                'userid': row[2],
                'datetime': self.utc2local(row[3]),
                'text': row[4],
                'name': row[5]
            })
        return {'data': o}

    def register_guest(self, guestname, eventid):
        if self.check_capacity(eventid) >= 1.0:
            return {'error': 'Capacity is full'}
        if not self.is_admin:
            return {'data': 'You are not admin!'}
        q = """INSERT INTO presence
               (eventid, userid, guestname)
               VALUES (%d, -1, "%s")""" % (int(eventid), guestname)
        r = self.cursor.execute(q)
        self.conn.commit()
        return {'data': 'Guest registered'}

    def check_capacity(self, eventid):
        q = """SELECT count(*) FROM presence WHERE eventid = %d""" % int(eventid)
        r = self.cursor.execute(q)
        players = int(r.fetchone()[0])
        e = self.get_event(int(eventid))
        return float(players) / e['capacity']

    def register(self, eventid):
        if self.check_capacity(eventid) >= 1.0:
            return {'error': 'Capacity full'}
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
        return {'error': 'Unknown or missing method'}

    def get_event(self, eventid):
        q = """SELECT * FROM events WHERE id = %d""" % eventid
        r = self.cursor.execute(q).fetchone()
        return {
            'id': r[0],
            'title': r[1],
            'starts': r[2],
            'ends': r[3],
            'location': r[4],
            'capacity': r[5],
            'courts': r[6]
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
            username = os.getenv('REMOTE_USER', 'anonymous')
            self.is_admin = username in self.admins
            user = self.get_user(username)
            self.userid = user['id']
            parameters = dict([(k, form.getvalue(k)) for k in form])
            response = apply(method, [], parameters)
            response['user'] = user
            self.output.write('Content-Type: application/json; charset=utf-8\n\n')
            self.output.write(json.dumps(response) + '\n')
        else:
            self.output.write('Content-Type: text/html; charset=utf-8\n\n')
            self.output.write(open('index.html').read())

    def soon(self, t):
        t1 = datetime.datetime.strptime(t, '%Y-%m-%d %H:%M:%S')
        now = datetime.datetime.now()
        delta = t1 - now
        #days = delta.days
        #hours, remainder = divmod(td.seconds, 3600)
        #minutes, seconds = divmod(remainder, 60)
        if delta.days < 1:
            return True
        return False

    def utc2local(self, t):
        t1 = datetime.datetime.strptime(t, '%Y-%m-%d %H:%M:%S')
        HERE = tz.tzlocal()
        UTC = tz.gettz('UTC')
        nt = t1.replace(tzinfo=UTC)
        return nt.astimezone(HERE).strftime('%d/%m/%Y %H:%M')

if __name__ == '__main__':
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
