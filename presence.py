#!/usr/bin/python3

import os
import sys
import json
import sqlite3
from http.cookies import SimpleCookie
import datetime
from urllib.parse import parse_qs
from functools import partial
import logging
import hashlib
import uuid
# TODO: remove superfluous imports

#from dateutil import tz
from wsgiref.simple_server import make_server, WSGIRequestHandler
from functools import lru_cache

# TODO: favicon
# look at: https://nlp.fi.muni.cz/trac/propaganda/browser/editor_static/docsrv.py

COOKIE_EXPIRES_FMT = "Date: %a, %d %b %Y %H:%M:%S GMT"
DEFAULT_IN_ADVANCE = 36

SQL_CREATE_USERS = ["DROP TABLE IF EXISTS users;", """
CREATE TABLE users (
    username    CHAR(30) PRIMARY KEY,
    fullname    CHAR(30),
    admin       INTEGER DEFAULT 0,
    coach       INTEGER DEFAULT 0,
    password    TEXT NOT NULL
);"""]

# TODO: salt?

SQL_CREATE_EVENTS = ["DROP TABLE IF EXISTS events;", """
CREATE TABLE events (
    id          INTEGER PRIMARY KEY,
    title       CHAR(50) NOT NULL,
    starts      DATETIME,
    ends        DATETIME,
    location    CHAR(50),
    capacity    INTEGER DEFAULT 16,
    courts      INTEGER DEFAULT 4,
    restriction TEXT,
    pinned      INTEGER DEFAULT 0
);"""]

SQL_CREATE_CRON_EVENTS = ["DROP TABLE IF EXISTS cronevents;", """
CREATE TABLE cronevents (
    id          INTEGER PRIMARY KEY,
    title       CHAR(50) NOT NULL,
    starts      DATETIME,
    ends        DATETIME,
    location    CHAR(50),
    capacity    INTEGER DEFAULT 16,
    courts      INTEGER DEFAULT 4,
    restriction TEXT
);"""]

SQL_CREATE_PRESENCE = ["DROP TABLE IF EXISTS presence;", """
CREATE TABLE presence (
    id          INTEGER PRIMARY KEY,
    eventid     INTEGER NOT NULL,
    username    CHAR(30),
    name        CHAR(30),
    datetime    DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (eventid) REFERENCES events(id),
    FOREIGN KEY (username) REFERENCES users(username),
    UNIQUE (eventid, name) ON CONFLICT REPLACE
);"""]

SQL_CREATE_COMMENTS = ["DROP TABLE IF EXISTS comments;", """
CREATE TABLE comments (
    id          INTEGER PRIMARY KEY,
    eventid     INTEGER NOT NULL,
    username    CHAR(30),
    datetime    DATETIME DEFAULT CURRENT_TIMESTAMP,
    text        TEXT,
    FOREIGN KEY (username) REFERENCES users(username),
    FOREIGN KEY (eventid) REFERENCES events(id)
);"""]

SQL_CREATE_SESSIONS = ["DROP TABLE IF EXISTS sessions;", """
CREATE TABLE sessions (
    id          TEXT PRIMARY KEY,
    username    CHAR(30) NOT NULL,
    FOREIGN KEY (username) REFERENCES users(username)
);"""]

def utc2local(t):
    return t
    # TODO!
    t1 = datetime.datetime.strptime(t, '%Y-%m-%d %H:%M:%S')
    HERE = tz.tzlocal()
    UTC = tz.gettz('UTC')
    nt = t1.replace(tzinfo=UTC)
    return nt.astimezone(HERE).strftime('%Y-%m-%d %H:%M:%S')

def _late(t, in_advance=DEFAULT_IN_ADVANCE):
    t1 = datetime.datetime.strptime(t, '%Y-%m-%d %H:%M:%S')
    now = datetime.datetime.now()
    delta = t1 - now
    return (delta.seconds//3600 + delta.days*24) < in_advance

HTML_HEADER = ('Content-type', 'text/html; charset=utf-8')
JSON_HEADER = ('Content-type', 'application/json; charset=utf-8')
JS_HEADER =   ('Content-type', 'text/javascript; charset=utf-8')

def app(environ, start_response, cls=None):
    http_method = environ["REQUEST_METHOD"].lower()
    try:
        request_body_size = int(environ.get('CONTENT_LENGTH', 0))
    except (ValueError):
        request_body_size = 0
    if http_method == "get":
        query = {
            k: v[0]
            for k, v in parse_qs(environ["QUERY_STRING"]).items()
        }
    else:
        query = {
            k.decode('utf-8'): v[0].decode('utf-8')
            for k, v in parse_qs(environ['wsgi.input'].read(request_body_size)).items()
        }
    path = environ["PATH_INFO"].split("/")[1:]
    status, headers, response = cls.serve(environ, http_method, path, query)
    start_response(status, headers)
    if type(response) == type({}):
        return [bytes(json.dumps(response), encoding="utf-8")]
    return [bytes(response, encoding="utf-8")]

class Presence():
    def __init__(self, config):
        self.config = config
        if not os.path.exists(config["PRESENCE_DB_PATH"]):
            self.conn, self.cursor = self._init_db()
        else:
            self.conn = sqlite3.connect(config["PRESENCE_DB_PATH"], isolation_level=None)
            self.cursor = self.conn.cursor()

    # TODO: load into memory
    def serve_local_file(self, path):
        with open(path) as f:
            return f.read()

    def _init_db(self):
        conn = sqlite3.connect(config["PRESENCE_DB_PATH"], isolation_level=None)
        cursor = conn.cursor()
        for item in [
                SQL_CREATE_USERS,
                SQL_CREATE_EVENTS,
                SQL_CREATE_CRON_EVENTS,
                SQL_CREATE_PRESENCE,
                SQL_CREATE_COMMENTS,
                SQL_CREATE_SESSIONS
            ]:
            for command in item:
                logging.warning("INIT WITH" + command)
                cursor.execute(command)
                conn.commit()
        return conn, cursor

    def serve(self, environ, http_method, path, query):
        headers = [JSON_HEADER]
        cookie = SimpleCookie(environ.get("HTTP_COOKIE", "")).get(config["PRESENCE_COOKIE_NAME"], None).value
        logging.warning(f"QUERY {repr(query)}")
        if not cookie:
            username = self._check_login(**query)
            if http_method == "post" and path[0] == "login" and username:
                sessionid = str(uuid.uuid4()).replace('-', '')
                logging.warning(f"Created sessionid {sessionid}")
                self._store_session(sessionid, username)
                cookie_name = config["PRESENCE_COOKIE_NAME"]
                domain = config["PRESENCE_DOMAIN"]
                in_one_year = datetime.datetime.now() + datetime.timedelta(days=365)
                expires = in_one_year.strftime(COOKIE_EXPIRES_FMT)
                headers.append(("Location", domain))
                headers.append(("Set-Cookie", f"{cookie_name}={sessionid}; Domain={domain}; Expires={expires}"))
                return ("307 Temporary redirect", headers, json.dumps({"logged": True}))
            return ("401 Unauthorized", [HTML_HEADER], self.serve_local_file("login.html"))
        else:
            if not path[0]:
                return ("200 OK", [HTML_HEADER], self.serve_local_file("index.html"))
            if path[0] == "js":
                return ("200 OK", [JS_HEADER], self.serve_local_file(os.sep.join(path)))
            if path[0] == "data":
                return ("403 Forbidden", [JSON_HEADER], json.dumps({"error": "Forbidden path"}))
            user = self._get_user_from_session(cookie)
            if not user:
                return ("401 Unauthorized", headers, {"error": "Unauthorized, unknown session"}) # for debugging!
        clsmethod = getattr(self, http_method + "_" + path[0], None)
        status = '200 OK'
        if clsmethod is None:
            status = "404 Not found"
            ret = {}
        else:
            ret = getattr(self, http_method + "_" + path[0])(**query)
        return (status, headers, ret)

    def _check_login(self, username="", password=""):
        q = "SELECT username FROM users WHERE username = ? AND password = ?"
        h = hashlib.sha256()
        h.update(password.encode("utf-8"))

        #self.cursor.execute("INSERT INTO users VALUES (?, ?, ?, ?, ?)", (username, "Vít Baisa", 1, 0, h.hexdigest()))
        #self.conn.commit()

        return self.cursor.execute(q, (username, h.hexdigest())).fetchone()[0]

    def _get_user_from_session(self, cookie):
        q = f"SELECT username FROM sessions WHERE id = ?;"
        username = self.cursor.execute(q, (cookie,)).fetchall()
        if username and len(username) == 1 and username[0] and username[0][0]:
            q = "SELECT * FROM users WHERE username = ?;"
            try:
                username, fullname, admin, coach, _ = self.cursor.execute(q, (username[0][0],)).fetchone()
                self.username = username
                self.fullname = fullname
                self.coach = bool(coach)
                self.admin = bool(admin)
                return username[0][0]
            except Exception as e:
                logging.warning("USER FROM SESSION EXCEPTION " + repr(e))
                return None
        return None

    def _store_session(self, sessionid, username):
        q = "INSERT INTO sessions VALUES (?, ?);"
        self.cursor.execute(q, (sessionid, username))
        self.conn.commit()
        return True

    def get_user(self):
        q = "SELECT * FROM users WHERE username = ?"
        r = self.cursor.execute(q, (self.username,)).fetchone()
        return r and {
            'username': r[0],
            'fullname': r[1],
            'admin': bool(r[2]),
            'coach': bool(r[3]),
        } or {}

    # admin
    def post_user(self, **params):
        q = "INSERT INTO users VALUES (?, ?, ?)"
        self.cursor.execute(q, (username, name, password))
        self.conn.commit()
        return {'msg': 'User created'}

    def stats(self):
        q = """SELECT userid, count(*) as sum
                FROM presence
                WHERE userid > -1
                GROUP BY userid
                ORDER by sum DESC"""
        r = self.cursor.execute(q)
        o = []
        for row in r.fetchall():
            u = get_user(userid=row[0])
            o.append({
                'name': u['fullname'] or u['username'],
                'attended': row[1]
            })
        return {'data': o}

    def get_events(self):
        user = self.get_user()
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
            restr = row[7].split(',')
            if restr and user["username"] not in restr:
                continue
            o.append({
                'id': row[0],
                'title': row[1],
                'starts': row[2],
                'lasts': row[3],
                'location': row[4],
                'capacity': row[5],
                'courts': row[6],
                'junior': 'JUN' in row[1],
                'locked': 'JUN' not in row[1] and _late(row[2], int(self.config["PRESENCE_IN_ADVANCE"])),
                'in_advance': int(self.config.get("PRESENCE_IN_ADVANCE", DEFAULT_IN_ADVANCE)),
                'restriction': restr,
            })
        return {'data': o}

    def get_cronevents(self):
        # TODO put cronevents into DB
        events = json.load(open(EVENTSFILE))
        for ev in events["events"]:
            ev["restriction"] = ev["restriction"].split(',')
        return {'data': events}

    def post_cronevents(self, data=''):
        from datetime import datetime
        now = datetime.now().strftime("%y_%m_%d")
        import shutil
        shutil.copyfile(EVENTSFILE, EVENTSFILE + "_" + now)
        with open(EVENTSFILE, "w") as f:
            f.write(json.dumps(json.loads(data), indent=4, ensure_ascii=False))
            return {'message': 'Cron updated successfully'}
        return {'error': 'Something went terrigly wrong...'}

    def get_courts(self, eventid, courts):
        q = """UPDATE events SET courts = ? WHERE id = ?"""
        self.cursor.execute(q, (int(courts), int(eventid)))
        self.conn.commit()
        return {'data': 'Event updated'}

    def get_capacity(self, eventid, capacity):
        q = """UPDATE events SET capacity = ? WHERE id = ?"""
        self.cursor.execute(q, (int(capacity), int(eventid)))
        self.conn.commit()
        return {'data': 'Event updated'}

    def get_users(self):
        q = "SELECT username, fullname FROM users ORDER BY fullname, username;"
        return {'data': [{
            'username': row[0],
            'fullname': row[1]
            } for row in self.cursor.execute(q).fetchall()
        ]}

    def get_presence(self, eventid=-1):
        q = """SELECT users.username,
                    users.fullname,
                    presence.username,
                    presence.name,
                    presence.datetime,
                    presence.id
                FROM presence, users
                WHERE eventid = ?
                AND presence.username = users.username
                ORDER BY presence.datetime"""
        r = self.cursor.execute(q, (int(eventid),))
        o = []
        for row in r.fetchall():
            o.append({
                'username': row[0],
                'fullname': row[1],
                'name': row[3],
                'datetime': utc2local(row[4]),
                'coach': row[2] in getattr(self, '_coach_ids', []),
                'id': row[5]
            })
        # guests
        q = """SELECT * FROM presence
            WHERE eventid = ?
            AND username = ""
            ORDER BY presence.datetime"""
        r = self.cursor.execute(q, (int(eventid),))
        for row in r.fetchall():
            o.append({
                'name': row[3],
                'datetime': utc2local(row[4]),
                'id': row[0]
            })
        return {'data': o}

    def delete_user(self, id):
        q = """DELETE FROM presence WHERE id = ?"""
        self.cursor.execute(q, (int(id),))
        self.conn.commit()
        return {'data': 'OK'}

    def post_comment(self, eventid, comment):
        q = """INSERT INTO comments (eventid, username, text) VALUES (?, ?, ?);"""
        try:
            self.cursor.execute(q, (int(eventid), username, comment.decode('utf-8')))
            self.conn.commit()
        except:
            return {'error': 'Comment not saved'}
        return {'message': 'OK'}

    def get_comments(self, eventid):
        q = """SELECT comments.id,
                    comments.eventid,
                    comments.username,
                    comments.datetime,
                    comments.text,
                    users.username,
                    users.fullname
                FROM comments, users
                WHERE eventid = ?
                AND users.username = comments.username
                ORDER BY datetime DESC;"""
        r = self.cursor.execute(q, (int(eventid),))
        o = []
        return {'data': [
            {
                'id': row[0],
                'eventid': row[1],
                'datetime': row[3],
                'text': row[4],
                'name': row[6] or row[5]
            }
            for row in r.fetchall()]
        }

    def delete_event(self, eventid):
        q = """DELETE FROM events WHERE id = ?"""
        self.cursor.execute(q, (int(eventid),))
        self.conn.commit()
        q = """DELETE FROM presence WHERE eventid = ?"""
        self.cursor.execute(q, (int(eventid),))
        self.conn.commit()
        return {'message': 'Event removed'}

    def post_restriction(self, eventid, restriction):
        q = "UPDATE events SET restriction = ? WHERE id = ?"
        r = self.cursor.execute(q, (restriction, int(eventid)))
        self.conn.commit()
        return {"data": "OK"}

    def post_event(self, restriction="", title="", starts="", duration=2,
            location="Zetor", capacity=0, courts=0, pinned=0):
        q = """INSERT INTO events
            (title, starts, duration, location, capacity, courts, restriction, pinned)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?);"""
        self.cursor.execute(q, (title.decode('utf-8'), starts, int(duration),
                location.decode('utf-8'), int(capacity), int(courts), users, int(pinned)))
        conn.commit()
        lastrowid = self.cursor.execute("SELECT last_insert_rowid();").fetchone()[0]
        return {'data': 'Event ID#%d created' % lastrowid}

    def post_register(self, name, eventid, guest=False):
        if self._check_capacity(eventid) >= 1.0:
            return {'error': 'Capacity is full'}
        q = """INSERT INTO presence
            (eventid, name)
            VALUES (%d, "%s")""" % (int(eventid), name)
        self.cursor.execute(q)
        self.conn.commit()
        return {'data': 'Guest registered'}

    def _check_capacity(self, eventid):
        q = """SELECT count(*) FROM presence WHERE eventid = ?"""
        r = self.cursor.execute(q, (int(eventid),))
        return float(int(r.fetchone()[0])) / self.get_event(int(eventid))['capacity']

    def post_register(self, eventid):
        if self._check_capacity(eventid) >= 1.0:
            return {'error': 'Capacity full'}
        if username in [x['username'] for x in presence(eventid)['data']\
                if 'username' in x]:
            return {'error': 'Already registered'}
        q = """INSERT INTO presence (eventid, userid) VALUES (?, ?);"""
        self.cursor.execute(q, (int(eventid), userid))
        self.conn.commit()
        return {'data': 'registered'}

    # TODO: only user itself or admin!
    def delete_register(self, eventid):
        q = """DELETE FROM presence WHERE userid = ? AND eventid = ?"""
        self.cursor.execute(q, (userid, int(eventid)))
        self.conn.commit()
        return {'data': 'unregistered'}

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


if __name__ == '__main__':
    config = {
        k: v
        for k, v in os.environ.items()
        if k.startswith("PRESENCE_")
    }
    assert config.get("PRESENCE_DB_PATH")

    if '--create' in sys.argv:
        next_week = datetime.datetime.now() + datetime.timedelta(days=7)
        day = datetime.datetime.today().weekday()
        try:
            events = json.load(open(os.environment.get("PRESENCE_EVENTS_PATH")))
            for e in events["events"]:
                if not day == e["day"]:
                    continue
                e["starts"] = next_week.strftime(e['starts'])
                create_event(**e)
        except Exception as msg:
            print("Failed to create event", str(msg))
            exit(1)
    else:
        presence = Presence(config)
        with make_server('', int(config.get("PRESENCE_PORT", 8000)),
                partial(app, cls=presence)) as httpd:
            httpd.serve_forever()
