#!/usr/bin/python3
#coding=utf-8

import os
import sys
import cgi
import sqlite3
import json
import random
import datetime
from dateutil import tz
from functools import wraps

"""
TODO:
    * remove jQuery, materialize
    * favicon.ico
"""

def utc2local(t):
    t1 = datetime.datetime.strptime(t, '%Y-%m-%d %H:%M:%S')
    HERE = tz.tzlocal()
    UTC = tz.gettz('UTC')
    nt = t1.replace(tzinfo=UTC)
    return nt.astimezone(HERE).strftime('%Y-%m-%d %H:%M')

def admin(f):
    @wraps(f)
    def wrapper(self, *args, **kwds):
        if self._is_admin:
            return f(self, *args, **kwds)
        else:
            return {'error': 'Access denied'}
    return wrapper

class Presence():
    _is_admin = False
    in_advance = 36 # limit time for registering before event start

    def __init__(self, database, eventsfn):
        self.conn = sqlite3.connect(database)
        self.cursor = self.conn.cursor()
        self._events_file = eventsfn

    def _parse_restriction(self, s):
        if not s.strip():
            return []
        l = []
        items = s.split(',')
        for i in items:
            if '-' in i:
                a, b = i.split('-')
                l.extend(range(int(a), int(b)+1))
            elif not i.strip():
                continue
            else:
                l.append(int(i))
        return l

    def events(self):
        q = """SELECT * FROM events
                WHERE (
                    datetime(starts) >= datetime('now', 'localtime', '-2 hours')
                    AND
                    datetime(starts) < datetime('now', 'localtime', '+8 days')
                )
                OR (
                    datetime(starts) >= datetime('now', 'localtime', '-2 hours')
                    AND
                    pinned = 1
                )
                ORDER BY starts ASC"""
        r = self.cursor.execute(q)
        o = []
        for row in r.fetchall():
            restr = self._parse_restriction(row[7])
            if restr and self.userid not in restr:
                continue
            starts = datetime.datetime.strptime(row[2], "%Y-%m-%d %H:%M:%S")
            o.append({
                'id': row[0],
                'title': row[1],
                'starts': row[2],
                'date': starts.strftime("%-d. %-m."),
                'time': starts.strftime("%H.%M"),
                'lasts': row[3],
                'location': row[4],
                'capacity': row[5],
                'courts': row[6],
                'junior': 'JUN' in row[1],
                'locked': 'JUN' not in row[1] and self.late(row[2], self.in_advance),
                'in_advance': self.in_advance,
                'restriction': restr
            })
        return {'data': o}

    @admin
    def add_user(self, username, fullname, password):
        import subprocess as sp
        if self.get_user(username):
            return {'error': "Username already in use"}
        q = "INSERT INTO users (username, nickname, email) VALUES (?, ?, ?)"
        self.cursor.execute(q, (username, fullname.decode('utf-8'), username + '@dummymail.cz'))
        self.conn.commit()
        pf = getattr(self, "_passfile", None)
        command = ["htpasswd", "-i", pf, username]
        p = sp.Popen(command, stdin=sp.PIPE, stdout=sp.PIPE)
        p.communicate(input=password)
        if p.returncode == 0:
            return {'message': "User %s created" % username}
        return {'error': 'User not created'}

    def stats(self):
        q = """SELECT userid, count(*) as sum
                FROM presence
                WHERE userid > -1
                GROUP BY userid
                ORDER by sum DESC"""
        r = self.cursor.execute(q)
        o = []
        for row in r.fetchall():
            u = self.get_user(userid=row[0])
            o.append({
                'name': u['nickname'] or u['username'],
                'attended': row[1]
            })
        return {'data': o}

    @admin
    def courts(self, eventid, courts):
        q = """UPDATE events SET courts = ? WHERE id = ?"""
        r = self.cursor.execute(q, (int(courts), int(eventid)))
        self.conn.commit()
        return {'data': 'Event updated'}

    @admin
    def capacity(self, eventid, capacity):
        q = """UPDATE events SET capacity = ? WHERE id = ?"""
        r = self.cursor.execute(q, (int(capacity), int(eventid)))
        self.conn.commit()
        return {'data': 'Event updated'}

    def users(self):
        q = "SELECT id, username, nickname FROM users ORDER BY nickname, username;"
        r = self.cursor.execute(q)
        o = []
        for row in r.fetchall():
            i = {
                'id': int(row[0]),
                'username': row[1],
                'nickname': row[2]
            }
            o.append(i)
        return {'data': o}

    def presence(self, eventid):
        q = """SELECT users.username,
                      users.nickname,
                      presence.userid,
                      presence.name,
                      presence.datetime,
                      presence.id
                FROM presence, users
                WHERE eventid = ?
                AND presence.userid = users.id
                ORDER BY presence.datetime"""
        r = self.cursor.execute(q, (int(eventid),))
        o = []
        for row in r.fetchall():
            o.append({
                'username': row[0],
                'nickname': row[1],
                'userid': row[2],
                'name': row[3],
                'datetime': utc2local(row[4]),
                'coach': row[2] in getattr(self, '_coach_ids', []),
                'id': row[5]
            })
        # guests
        q = """SELECT * FROM presence
               WHERE eventid = ?
               AND userid = -1
               ORDER BY presence.datetime"""
        r = self.cursor.execute(q, (int(eventid),))
        for row in r.fetchall():
            o.append({
                'name': row[3],
                'datetime': utc2local(row[4]),
                'id': row[0]
            })
        return {'data': o}

    def remove_user(self, id):
        q = """DELETE FROM presence WHERE id = ?"""
        self.cursor.execute(q, (int(id),))
        self.conn.commit()
        return {'data': 'OK'}

    def add_comment(self, eventid, comment):
        q = """INSERT INTO comments (eventid, userid, text) VALUES (?, ?, ?);"""
        try:
            self.cursor.execute(q, (int(eventid), self.userid, comment.decode('utf-8')))
            self.conn.commit()
        except:
            return {'error': 'Comment not saved'}
        return {'message': 'OK'}

    def comments(self, eventid):
        q = """SELECT comments.id,
                    comments.eventid,
                    comments.userid,
                    comments.datetime,
                    comments.text,
                    users.username,
                    users.nickname
                FROM comments, users
                WHERE eventid = ?
                AND users.id = comments.userid
                ORDER BY datetime DESC;"""
        r = self.cursor.execute(q, (int(eventid),))
        o = []
        for row in r.fetchall():
            o.append({
                'id': row[0],
                'eventid': row[1],
                'userid': row[2],
                'datetime': row[3],
                'text': row[4],
                'name': row[6] or row[5]
            })
        return {'data': o}

    @admin
    def remove_event(self, eventid):
        q = """DELETE FROM events WHERE id = ?"""
        self.cursor.execute(q, (int(eventid),))
        self.conn.commit()
        q = """DELETE FROM presence WHERE eventid = ?"""
        self.cursor.execute(q, (int(eventid),))
        self.conn.commit()
        return {'message': 'Event removed'}

    @admin
    def update_restriction(self, eventid, restriction):
        q = "UPDATE events SET restriction = ? WHERE id = ?"
        r = self.cursor.execute(q, (restriction, int(eventid)))
        self.conn.commit()
        return {"data": "OK"}

    @admin
    def create_event(self, users="", title="", starts="", duration=2,
            location="Zetor", capacity=0, courts=0, pinned=0):
        q = """INSERT INTO events
               (title, starts, duration, location, capacity, courts, restriction, pinned)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?);"""
        self.cursor.execute(q, (title.decode('utf-8'), starts, int(duration),
                location.decode('utf-8'), int(capacity), int(courts), users, int(pinned)))
        self.conn.commit()
        lastrowid = self.cursor.execute("SELECT last_insert_rowid();").fetchone()[0]
        return {'data': 'Event ID#%d created' % lastrowid}

    @admin
    def register_guest(self, name, eventid):
        if self.check_capacity(eventid) >= 1.0:
            return {'error': 'Capacity is full'}
        q = """INSERT INTO presence
               (eventid, name)
               VALUES (%d, "%s")""" % (int(eventid), name)
        r = self.cursor.execute(q)
        self.conn.commit()
        return {'data': 'Guest registered'}

    def check_capacity(self, eventid):
        q = """SELECT count(*) FROM presence WHERE eventid = ?"""
        r = self.cursor.execute(q, (int(eventid),))
        players = int(r.fetchone()[0])
        e = self.get_event(int(eventid))
        return float(players) / e['capacity']

    def register(self, eventid):
        if self.check_capacity(eventid) >= 1.0:
            return {'error': 'Capacity full'}
        if self.userid in [x['userid'] for x in self.presence(eventid)['data']\
                if 'userid' in x]:
            return {'error': 'Already registered'}
        q = """INSERT INTO presence (eventid, userid) VALUES (?, ?);"""
        r = self.cursor.execute(q, (int(eventid), self.userid))
        self.conn.commit()
        return {'data': 'registered'}

    def unregister(self, eventid):
        # TODO: only user itself or admin!
        q = """DELETE FROM presence WHERE userid = ? AND eventid = ?"""
        r = self.cursor.execute(q, (self.userid, int(eventid)))
        self.conn.commit()
        return {'data': 'unregistered'}

    def default(self):
        return {'error': 'Unknown or missing method'}

    def get_event(self, eventid):
        q = """SELECT * FROM events WHERE id = ?"""
        r = self.cursor.execute(q, (int(eventid),)).fetchone()
        return {
            'id': r[0],
            'title': r[1],
            'starts': r[2],
            'duration': r[3],
            'location': r[4],
            'capacity': r[5],
            'courts': r[6]
        }

    def get_user(self, username='', userid=''):
        if username:
            q = 'SELECT * FROM users WHERE username = ?;'
            r = self.cursor.execute(q, (username.decode('utf-8'),)).fetchone()
        else:
            q = 'SELECT * FROM users WHERE id = ?;'
            r = self.cursor.execute(q, (int(userid),)).fetchone()
        return r and {
            'id': r[0],
            'username': r[1],
            'nickname': r[2],
            'admin': r[1].encode('utf-8') in self._admins
        } or {}

    def serve(self):
        form = cgi.FieldStorage()
        parse_url = os.getenv('PATH_INFO', '').strip().split('/')
        if len(parse_url) > 1:
            methodname = parse_url[1]
            method = getattr(self, methodname, self.default)
            username = os.getenv('REMOTE_USER', 'anonymous')
            self._is_admin = username in self._admins
            self.user = self.get_user(username)
            if not self.user:
                sys.stdout.write('Content-Type: application/json; charset=utf-8\n\n')
                sys.stdout.write(json.dumps({'error': 'Uzivatel %s neexistuje!' % username}))
                return
            self.userid = self.user['id']
            parameters = dict([(k, form.getvalue(k)) for k in form])
            response = apply(method, [], parameters)
            response['user'] = self.user
            sys.stdout.write('Content-Type: application/json; charset=utf-8\n\n')
            sys.stdout.write(json.dumps(response) + '\n')
        else:
            sys.stdout.write('Content-Type: text/html; charset=utf-8\n\n')
            sys.stdout.write(open('index.html').read())

    def late(self, t, hours=0):
        if not hours: hours = self.in_advance
        t1 = datetime.datetime.strptime(t, '%Y-%m-%d %H:%M:%S')
        now = datetime.datetime.now()
        delta = t1 - now
        return (delta.seconds//3600 + delta.days*24) < hours

    def get_cronevents(self):
        events = json.load(open(self._events_file))
        for ev in events["events"]:
            ev["restriction"] = self._parse_restriction(ev["restriction"])
        return {'data': events}

    def set_cronevents(self, data=''):
        from datetime import datetime
        now = datetime.now().strftime("%y_%m_%d")
        from shutil import copyfile
        copyfile(self._events_file, self._events_file + "_" + now)
        with open(self._events_file, "w") as f:
            f.write(data)
            return {'message': 'Cron updated successfully'}
        return {'error': 'Something went terrigly wrong...'}


if __name__ == '__main__':
    next_week = datetime.datetime.now() + datetime.timedelta(days=7)
    day = datetime.datetime.today().weekday()
    try:
        p = Presence(sys.argv[1], sys.argv[2])
        events = json.load(open(p._events_file))
        p._is_admin = True
        for e in events["events"]:
            if not day == e["day"]:
                continue
            new_start = next_week.strftime(e['starts'])
            p.create_event(title=e['title'].encode('utf-8'), starts=new_start,
                capacity=e['capacity'], location=e['location'].encode('utf-8'),
                courts=e['courts'], users=e['restriction'])
    except Exception, msg:
        print("Failed to create event", str(msg))
