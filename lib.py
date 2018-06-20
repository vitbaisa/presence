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
        msg['From'] = 'Kometa Zetor <' + sender + '>'
        msg['To'] = ','.join(addresses)
        server = smtplib.SMTP('localhost', timeout=10)
        server.sendmail(sender, addresses, msg.as_string())
        server.quit()

    def events(self):
        q = """SELECT * FROM events
                WHERE date(starts) >= date('now', '+2 hours')
                AND date(starts) < date('now', '+8 days')
                ORDER BY starts ASC LIMIT 4"""
        r = self.cursor.execute(q)
        o = []
        for row in r.fetchall():
            restr = row[7]
            if restr and str(self.userid) not in restr.split(','):
                continue
            o.append({
                'id': row[0],
                'title': row[1],
                'starts': row[2],
                'lasts': row[3],
                'location': row[4],
                'capacity': row[5],
                'courts': row[6],
                'locked': self.soon(row[2])
            })
        return {'data': o}

    def courts(self, eventid, courts):
        if self.is_admin:
            q = """UPDATE events SET courts = %d
                    WHERE id = %d""" % (int(courts), int(eventid))
            r = self.cursor.execute(q)
            self.conn.commit()
            return {'data': 'Event updated'}
        else:
            return {'error': 'You are not admin'}


    def capacity(self, eventid, capacity):
        if self.is_admin:
            q = """UPDATE events SET capacity = %d
                    WHERE id = %d""" % (int(capacity), int(eventid))
            r = self.cursor.execute(q)
            self.conn.commit()
            return {'data': 'Event updated'}
        else:
            return {'error': 'You are not admin'}

    def users(self):
        q = "SELECT id, username, nickname, email FROM users;"
        r = self.cursor.execute(q)
        o = []
        for row in r.fetchall():
            o.append({
                'id': int(row[0]),
                'username': row[1],
                'nickname': row[2],
                'email': row[3]
            })
        return {'data': o}

    def presence(self, eventid):
        q = """SELECT users.username,
                      users.nickname,
                      presence.userid,
                      presence.name,
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
                'nickname': row[1],
                'userid': row[2],
                'name': row[3],
                'datetime': utc2local(row[4])
            })
        # guests
        q = """SELECT * FROM presence
               WHERE eventid = %d
               AND userid = -1;""" % int(eventid)
        r = self.cursor.execute(q)
        for row in r.fetchall():
            o.append({
                'name': row[3],
                'datetime': utc2local(row[4])
            })
        return {'data': o}

    def add_comment(self, eventid, comment, announce="0"):
        q = """INSERT INTO comments
                (eventid, userid, text)
                VALUES (%d, %d, "%s")""" % (int(eventid), self.userid, comment)
        if int(announce):
            ev = self.get_event(int(eventid))
            subject = "%s komentoval(a) událost %s (%s)" %\
                    (self.user['username'].encode('utf-8'), ev['title'].encode('utf-8'), ev['starts'].encode('utf-8'))
            self.sendmail(comment, self.admin_mails, subject)
        self.cursor.execute(q)
        self.conn.commit()
        # TODO: send comment id
        return {'data': 'OK'}

    def comments(self, eventid):
        q = """SELECT comments.id,
                    comments.eventid,
                    comments.userid,
                    comments.datetime,
                    comments.text,
                    users.username
                FROM comments, users
                WHERE eventid = %d
                AND users.id = comments.userid
                ORDER BY datetime DESC;""" % int(eventid)
        r = self.cursor.execute(q)
        o = []
        for row in r.fetchall():
            o.append({
                'id': row[0],
                'eventid': row[1],
                'userid': row[2],
                'datetime': row[3],
                'text': row[4],
                'name': row[5]
            })
        return {'data': o}

    def create_event(self, users="", title="", starts="", duration=2,
            location="Zetor", capacity=0, courts=0, announce=0):
        if not self.is_admin:
            return {'error': 'Only admin can create an event'}
        q = """INSERT INTO events
               (title, starts, duration, location, capacity, courts, restriction)
               VALUES ("%s", "%s", %d, "%s", %d, %d, "%s");""" %\
               (title, starts, int(duration), location, int(capacity), int(courts), users)
        self.cursor.execute(q)
        self.conn.commit()
        lastrowid = self.cursor.execute("SELECT last_insert_rowid();").fetchone()[0]
        if int(announce):
            emails = []
            if not users:
                emails = [x['email'] for x in self.users()['data']]
            else:
                d = dict([(x['id'], x['email']) for x in self.users()['data']])
                for uid in users.split(','):
                    emails.append(d.get(int(uid), ''))
            body = """%s, %s, %s<br /><br />
<a href="https://vitek.baisa.net/presence/#ev%d" target="_blank">Přihlas se</a> nejpozději 24 hodin předem.<br /><br />
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
        q = """SELECT count(*) FROM presence WHERE eventid = %d""" % int(eventid)
        r = self.cursor.execute(q)
        players = int(r.fetchone()[0])
        e = self.get_event(int(eventid))
        return float(players) / e['capacity']

    def register(self, eventid, redirect='0'):
        if self.check_capacity(eventid) >= 1.0:
            return {'error': 'Capacity full'}
        if self.userid in [x['userid'] for x in self.presence(eventid)['data']]:
            return {'error': 'Already registered'}
        q = """INSERT INTO presence (eventid, userid) VALUES (%d, %d);""" %\
                (int(eventid), self.userid)
        r = self.cursor.execute(q)
        # TODO: last_insert_rowid
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
            'duration': r[3],
            'location': r[4],
            'capacity': r[5],
            'courts': r[6]
        }

    def get_user(self, username='', userid=''):
        if username:
            q = 'SELECT * FROM users WHERE username = "%s";' % username
        else:
            q = 'SELECT * FROM users WHERE id = %d;' % int(userid)
        r = self.cursor.execute(q).fetchone()
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
                sys.stdout.write(open('redirect.html').read() % str(parameters['eventid']))
            else:
                sys.stdout.write('Content-Type: application/json; charset=utf-8\n\n')
                sys.stdout.write(json.dumps(response) + '\n')
        else:
            sys.stdout.write('Content-Type: text/html; charset=utf-8\n\n')
            sys.stdout.write(open('index.html').read())

    def soon(self, t):
        try:
            t1 = datetime.datetime.strptime(t, '%Y-%m-%d %H:%M:%S')
            now = datetime.datetime.now()
            delta = t1 - now
            if delta.days < 1:
                return True
            return False
        except ValueError:
            return False

if __name__ == '__main__':
    next_week = datetime.datetime.now() + datetime.timedelta(days=7)
    day = datetime.datetime.today().weekday()
    if day not in [0, 3, 6]:
        exit(0)
    titles = {
        0: 'Pondělí, volná hra',
        3: 'Čtvrtek, volná hra',
        6: 'Neděle, volná hra'
    }
    volnahra_lide = "1,2,3,4,5,6,7,8,9,10,11,12,13,14,16,17,18,19,20,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,42,45,46"
    emailto = {
        0: volnahra_lide,
        3: volnahra_lide,
        6: volnahra_lide
    }
    capacity = {0: 12, 3: 12, 6: 8}
    courts = {0: 3, 3: 3, 6: 2}
    event = {
        'title': titles[day],
        'location': 'Zetor Líšeň',
        'starts': next_week.strftime('%Y-%m-%d 19:00:00'),
        'duration': 2,
        'capacity': capacity[day],
        'courts': courts[day]
    }
    try:
        p = Presence(sys.argv[1])
        p.is_admin = True
        p.create_event(title=event['title'], starts=event['starts'],
            capacity=event['capacity'], location="Zetor",
            courts=event['courts'], announce=1, users=emailto[day])
        print "Event created", event
    except:
        print "Failed to create event", event
