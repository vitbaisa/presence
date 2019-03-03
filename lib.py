#!/usr/bin/env python
#coding=utf-8

import os
import sys
import cgi
import sqlite3
import json
import datetime
import smtplib
from email.mime.text import MIMEText
from dateutil import tz

# TODO: decorator is_admin

def utc2local(t):
    t1 = datetime.datetime.strptime(t, '%Y-%m-%d %H:%M:%S')
    HERE = tz.tzlocal()
    UTC = tz.gettz('UTC')
    nt = t1.replace(tzinfo=UTC)
    return nt.astimezone(HERE).strftime('%Y-%m-%d %H:%M')

class Presence():
    "A lightweight event-presence manager"

    is_admin = False

    def __init__(self, database):
        self.conn = sqlite3.connect(database)
        self.cursor = self.conn.cursor()

    def sendmail(self, text="", addresses=[], subject=""):
        sender = 'noreply@sketchengine.co.uk'
        msg = MIMEText(text, 'html')
        msg['Subject'] = subject
        msg['From'] = 'Kometa <' + sender + '>'
        msg['To'] = 'kometabadec@seznam.cz'
        server = smtplib.SMTP('localhost', timeout=10)
        server.sendmail(sender, addresses, msg.as_string())
        server.quit()

    def _parse_restriction(self, s):
        if not s.strip():
            return []
        l = []
        items = s.split(',')
        for i in items:
            if '-' in i:
                a, b = i.split('-')
                l.extend(range(int(a), int(b)+1))
            else:
                l.append(int(i))
        return l

    def events(self):
        q = """SELECT * FROM events
                WHERE datetime(starts) >= datetime('now', 'localtime', '-2 hours')
                AND datetime(starts) < datetime('now', 'localtime', '+8 days')
                ORDER BY starts ASC"""
        r = self.cursor.execute(q)
        o = []
        for row in r.fetchall():
            restr = self._parse_restriction(row[7])
            if restr and self.userid not in restr:
                continue
            # TODO: add column "before"
            if row[1].startswith('Ned'):
                h = 33
            else:
                h = 24
            o.append({
                'id': row[0],
                'title': row[1],
                'starts': row[2],
                'lasts': row[3],
                'location': row[4],
                'capacity': row[5],
                'courts': row[6],
                'junior': 'JUN' in row[1],
                'locked': 'JUN' not in row[1] and self.late(row[2], h)
            })
        return {'data': o}

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

    def courts(self, eventid, courts):
        if self.is_admin:
            q = """UPDATE events SET courts = ? WHERE id = ?"""
            r = self.cursor.execute(q, (int(courts), int(eventid)))
            self.conn.commit()
            return {'data': 'Event updated'}
        else:
            return {'error': 'You are not admin'}

    def capacity(self, eventid, capacity):
        if self.is_admin:
            q = """UPDATE events SET capacity = ? WHERE id = ?"""
            r = self.cursor.execute(q, (int(capacity), int(eventid)))
            self.conn.commit()
            return {'data': 'Event updated'}
        else:
            return {'error': 'You are not admin'}

    def users(self, full=0):
        q = "SELECT id, username, nickname, email FROM users ORDER BY nickname, username;"
        r = self.cursor.execute(q)
        o = []
        for row in r.fetchall():
            i = {
                'id': int(row[0]),
                'username': row[1],
                'nickname': row[2]
            }
            if full: i['email'] = row[3]
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
                'coach': row[2] in getattr(self, 'coach_ids', []),
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

    def add_comment(self, eventid, comment, announce="0"):
        q = """INSERT INTO comments (eventid, userid, text) VALUES (?, ?, ?);"""
        if int(announce):
            ev = self.get_event(int(eventid))
            subject = "%s komentoval(a) událost %s (%s)" %\
                    (self.user['username'].encode('utf-8'), ev['title'].encode('utf-8'), ev['starts'].encode('utf-8'))
            self.sendmail(comment, self.admin_mails, subject)
        self.cursor.execute(q, (int(eventid), self.userid, comment))
        self.conn.commit()
        # TODO: send comment id
        return {'data': 'OK'}

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

    def remove_event(self, eventid):
        if not self.is_admin:
            return {'error': 'Only admin can remove an event'}
        q = """DELETE FROM events WHERE id = ?"""
        self.cursor.execute(q, (int(eventid),))
        self.conn.commit()
        q = """DELETE FROM presence WHERE eventid = ?"""
        self.cursor.execute(q, (int(eventid),))
        self.conn.commit()
        return {'message': 'Event removed'}

    def create_event(self, users="", title="", starts="", duration=2,
            location="Zetor", capacity=0, courts=0, announce=0):
        if not self.is_admin:
            return {'error': 'Only admin can create an event'}
        q = """INSERT INTO events
               (title, starts, duration, location, capacity, courts, restriction)
               VALUES (?, ?, ?, ?, ?, ?, ?);"""
        self.cursor.execute(q, (title.decode('utf-8'), starts, int(duration),
                location.decode('utf-8'), int(capacity), int(courts), users))
        self.conn.commit()
        lastrowid = self.cursor.execute("SELECT last_insert_rowid();").fetchone()[0]
        if int(announce):
            emails = []
            if not users:
                emails = [x['email'] for x in self.users(1)['data']\
                        if not x['email'].startswith('_')]
            else:
                d = dict([(x['id'], x['email']) for x in self.users(1)['data']\
                        if not x['email'].startswith('_')])
                for uid in self._parse_restriction(users):
                    if d.get(uid, ''):
                        emails.append(d[uid])
            body = """%s, %s, %s<br /><br />
<a href="https://vitek.baisa.net/presence/#ev%d" target="_blank">Přihlaste se</a>
nejpozději 24 hodin předem.<br /><br />
Na tento email neodpovídejte.<br /><br />
Tým Kometa Badminton""" % (title, starts, location, lastrowid)
            self.sendmail(body, emails, 'Nezapomeňte se přihlásit')
        return {'data': 'Event ID#%d created' % lastrowid}

    def register_guest(self, name, eventid):
        if self.check_capacity(eventid) >= 1.0:
            return {'error': 'Capacity is full'}
        if not self.is_admin:
            return {'data': 'You are not admin!'}
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

    def register(self, eventid, redirect='0'):
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
        q = """DELETE FROM presence
                WHERE userid = ?
                AND eventid = ?"""
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
        if r:
            return {
                'id': r[0],
                'username': r[1],
                'nickname': r[2],
                'email': r[3],
                'admin': r[1].encode('utf-8') in self.admins
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
            self.user = self.get_user(username)
            if not self.user:
                sys.stdout.write('Content-Type: application/json; charset=utf-8\n\n')
                sys.stdout.write(json.dumps({'error': 'Uzivatel %s neexistuje!' % username}))
                return
            self.userid = self.user['id']
            parameters = dict([(k, form.getvalue(k)) for k in form])
            response = apply(method, [], parameters)
            response['user'] = self.user
            if 'redirect' in parameters and 'eventid' in parameters:
                sys.stdout.write('Content-Type: text/html; charset=utf-8\n\n')
                sys.stdout.write(open('redirect.html').read() %\
                        str(parameters['eventid']))
            else:
                sys.stdout.write('Content-Type: application/json; charset=utf-8\n\n')
                sys.stdout.write(json.dumps(response) + '\n')
        else:
            sys.stdout.write('Content-Type: text/html; charset=utf-8\n\n')
            sys.stdout.write(open('index.html').read())

    def late(self, t, hours=24):
        t1 = datetime.datetime.strptime(t, '%Y-%m-%d %H:%M:%S')
        now = datetime.datetime.now()
        delta = t1 - now
        return (delta.seconds//3600 + delta.days*24) < hours

if __name__ == '__main__':
    next_week = datetime.datetime.now() + datetime.timedelta(days=7)
    day = datetime.datetime.today().weekday()
    events = {
        0: [
            {
                'title': 'Pondělí, JUNIOŘI',
                'location': 'Zetor',
                'starts': next_week.strftime('%Y-%m-%d 17:30:00'),
                'duration': 1.5,
                'capacity': 30,
                'courts': 4,
                'emailto': '4,5,26,30,49,54-60,63-64,67-74,77,81-84'
            },
            {
                'title': 'Pondělí, trénink',
                'location': 'Zetor',
                'starts': next_week.strftime('%Y-%m-%d 19:00:00'),
                'duration': 2,
                'capacity': 24,
                'courts': 6,
                'emailto': "1-6,8-12,14,16-25,27,30,34,35,37,39,40,42,45,49,75,76,78"
            }],
        2: [{
                'title': 'Středa, JUNIOŘI',
                'location': 'Zetor',
                'starts': next_week.strftime('%Y-%m-%d 17:00:00'),
                'duration': 2,
                'capacity': 30,
                'courts': 4,
                'emailto': '4,5,24,26,30,37,39,45,54-61,64,68-77,81,82,84'
            },
            {
                'title': 'Středa s Vojtou',
                'location': 'Sprint',
                'starts': next_week.strftime('%Y-%m-%d 07:30:00'),
                'duration': 2,
                'capacity': 8,
                'courts': 2,
                'emailto': '1,2,3,4,5,9,14,21,28,36,43,45,79,80'
            }],
        3: [{
                'title': 'Čtvrtek, volná hra',
                'location': 'Zetor',
                'starts': next_week.strftime('%Y-%m-%d 19:00:00'),
                'duration': 2,
                'capacity': 20,
                'courts': 5,
                'emailto': "1-14,16-42,44-51,53,75-79"
            }],
        6: [{
                'title': 'Neděle, volná hra',
                'location': 'Zetor',
                'starts': next_week.strftime('%Y-%m-%d 19:00:00'),
                'duration': 2,
                'capacity': 16,
                'courts': 4,
                'emailto': "1-14,16-42,44-51,53,75-79"
            }]
    }
    if '--ucast' in sys.argv:
        # selong.v@seznam.cz
        pass
    else:
        if day not in events.keys():
            exit(0)
        try:
            p = Presence(sys.argv[1])
            p.is_admin = True
            for e in events[day]:
                p.create_event(title=e['title'], starts=e['starts'],
                    capacity=e['capacity'], location=e['location'],
                    courts=e['courts'], announce=1, users=e['emailto'])
        except Exception, e:
            print "Failed to create event", str(e)
