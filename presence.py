#!/usr/bin/python3

import os
import json
import sqlite3
import functools
import datetime
import logging
import argparse

from wsgiref.simple_server import make_server
from urllib.parse import parse_qs
from typing import NamedTuple, Optional, Dict


def admin(method):
    @functools.wraps(method)
    def _impl(self, *method_args, **method_kwargs):
        if self.username in self.admins:
            return method(self, *method_args, **method_kwargs)
        return {"error": "Unauthorized"}

    return _impl


DEFAULT_LOCK_BEFORE = 36
HTML_HEADER = ("Content-type", "text/html; charset=utf-8")
JSON_HEADER = ("Content-type", "application/json; charset=utf-8")
JS_HEADER = ("Content-type", "text/javascript; charset=utf-8")


def utc2local(t):
    return t
    # TODO!
    t1 = datetime.datetime.strptime(t, "%Y-%m-%d %H:%M:%S")
    HERE = tz.tzlocal()
    UTC = tz.gettz("UTC")
    nt = t1.replace(tzinfo=UTC)
    return nt.astimezone(HERE).strftime("%Y-%m-%d %H:%M:%S")


def _late(t, in_advance=DEFAULT_LOCK_BEFORE):
    t1 = datetime.datetime.strptime(t, "%Y-%m-%d %H:%M:%S")
    now = datetime.datetime.now()
    delta = t1 - now
    return (delta.seconds // 3600 + delta.days * 24) < in_advance


def app(environ, start_response, cls=None):

    http_method = environ["REQUEST_METHOD"].lower()
    try:
        body_size = int(environ.get("CONTENT_LENGTH", 0))
    except ValueError:
        body_size = 0

    path = environ["PATH_INFO"].split("/")[1:]

    if http_method == "get":
        query = {k: v[0] for k, v in parse_qs(environ["QUERY_STRING"]).items()}
    else:
        query = json.loads(
            environ["wsgi.input"].read(body_size).decode("utf-8") or "{}"
        )

    status, headers, response = cls.serve(environ, http_method, path, query)
    start_response(status, headers)

    if isinstance(response, dict):
        return [bytes(json.dumps(response), encoding="utf-8")]
    elif isinstance(response, str):
        return [bytes(response, encoding="utf-8")]
    else:
        return [bytes(json.dumps({"error": "Unknown response type"}), encoding="utf-8")]


class Presence:
    def __init__(self, config):
        self.config = config
        if not os.path.exists(config["PRESENCE_DB_PATH"]):
            logging.warning("Initializing {config['PRESENCE_DB_PATH']}")
            self.conn, self.cursor = self._init_db()
        else:
            self.conn = sqlite3.connect(
                config["PRESENCE_DB_PATH"], isolation_level=None
            )
            self.conn.row_factory = sqlite3.Row
            self.cursor = self.conn.cursor()

        self.admins = self.config.get("PRESENCE_ADMINS", "").split(",")
        self.coaches = self.config.get("PRESENCE_COACHES", "").split(",")
        self.local_files = {}

    @functools.lru_cache
    def serve_local_file(self, path):
        with open(path) as f:
            self.local_files[path] = f.read()
            return self.local_files[path]

    def _init_db(self):
        conn = sqlite3.connect(config["PRESENCE_DB_PATH"], isolation_level=None)
        cursor = conn.cursor()
        cursor.execute("DROP TABLE IF EXISTS users;")
        cursor.execute(
            """
            CREATE TABLE users (
                username    CHAR(30) PRIMARY KEY,
                fullname    CHAR(30),
                attr        TEXT,
            );"""
        )
        cursor.execute("DROP TABLE IF EXISTS events;")
        cursor.execute(
            """
            CREATE TABLE events (
                id          INTEGER PRIMARY KEY,
                title       CHAR(50) NOT NULL,
                starts      DATETIME,
                ends        DATETIME,
                location    CHAR(50),
                attr        TEXT
            );"""
        )
        cursor.execute("DROP TABLE IF EXISTS recurrent_events;")
        cursor.execute(
            """
            CREATE TABLE recurrent_events (
                id          INTEGER PRIMARY KEY,
                title       CHAR(50) NOT NULL,
                starts      DATETIME,
                ends        DATETIME,
                location    CHAR(50),
                attr        TEXT
            );"""
        )
        cursor.execute("DROP TABLE IF EXISTS presence;")
        cursor.execute(
            """
            CREATE TABLE presence (
                id          INTEGER PRIMARY KEY,
                eventid     INTEGER NOT NULL,
                username    CHAR(30),
                guestname   CHAR(30),
                datetime    DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (eventid) REFERENCES events(id),
                FOREIGN KEY (username) REFERENCES users(username),
                UNIQUE (eventid, guestname) ON CONFLICT REPLACE
            );"""
        )
        cursor.execute("DROP TABLE IF EXISTS comments;")
        cursor.execute(
            """
            CREATE TABLE comments (
                id          INTEGER PRIMARY KEY,
                eventid     INTEGER NOT NULL,
                username    CHAR(30),
                datetime    DATETIME DEFAULT CURRENT_TIMESTAMP,
                text        TEXT,
                FOREIGN KEY (username) REFERENCES users(username),
                FOREIGN KEY (eventid) REFERENCES events(id)
            );"""
        )
        cursor.execute("DROP TABLE IF EXISTS sessions;")
        cursor.execute(
            """
            CREATE TABLE sessions (
                id          TEXT PRIMARY KEY,
                username    CHAR(30) NOT NULL,
                FOREIGN KEY (username) REFERENCES users(username)
            );"""
        )
        conn.commit()
        return conn, cursor

    def serve(self, environ, http_method, path, query):
        headers = [JSON_HEADER]
        username = environ.get("HTTP_X_REMOTE_USER", None)
        if path[0] == "":
            return ("200 OK", [HTML_HEADER], self.serve_local_file("index.html"))
        elif path[0] == "js":
            return ("200 OK", [JS_HEADER], self.serve_local_file(os.sep.join(path)))
        elif path[0] == "data":
            return (
                "403 Forbidden",
                [JSON_HEADER],
                json.dumps({"error": "Forbidden path"}),
            )
        clsmethod = getattr(self, http_method + "_" + path[0], None)
        status = "200 OK"
        if clsmethod is None:
            status = "404 Not found"
            ret = {}
        else:
            query["username"] = username
            ret = getattr(self, http_method + "_" + path[0])(**query)
        return (status, headers, ret)

    def get_user(self, username: str, **argv) -> dict:
        return {
            "username": username,
            "admin": username in self.admins,
            "coach": username in self.coaches,
        }

    @admin
    def post_user(self, **params) -> dict:
        q = "INSERT INTO users VALUES (?, ?, ?)"
        self.cursor.execute(q, (username, name, password))
        self.conn.commit()
        return {"msg": "User created"}

    @admin
    def delete_user(self, username) -> dict:
        q = "DELETE * FROM users WHERE username = ?"
        self.cursor.execute(q, (username,))
        self.conn.commit()
        return {"msg": "User deleted"}

    def get_events(self, username: str) -> dict:
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
            restr = row[7].split(",")
            if restr and self.username not in restr:
                continue
            o.append(
                {
                    **row,
                    "junior": "JUN" in row["name"],
                    "locked": "JUN" not in row["name"] and _late(row["starts"]),
                    "in_advance": DEFAULT_LOCK_BEFORE,
                    "restriction": restr,
                }
            )
        # TODO: put coaches at the end for junior events
        return {"data": o}

    def get_recurrent_events(self):
        q = "SELECT * FROM recurrent_events"
        events = json.load(open(EVENTSFILE))
        for ev in events["events"]:
            ev["restriction"] = ev["restriction"].split(",")
        return {"data": events}

    @admin
    def put_recurrent_event(self, data=None):
        if data is None:
            data = {}
        return {"message": "Repeating event updated"}

    @admin
    def post_recurrent_event(self, data=""):
        # TODO put recurrent_events into DB
        return {"error": "Something went terrigly wrong..."}

    @admin
    def put_courts(self, eventid, courts):
        q = """UPDATE events SET courts = ? WHERE id = ?"""
        self.cursor.execute(q, (int(courts), int(eventid)))
        self.conn.commit()
        return {"data": "Event updated"}

    @admin
    def put_capacity(self, eventid, capacity):
        q = """UPDATE events SET capacity = ? WHERE id = ?"""
        self.cursor.execute(q, (int(capacity), int(eventid)))
        self.conn.commit()
        return {"data": "Event updated"}

    def get_presence(self, eventid=-1):
        q = """SELECT users.username,
                    users.fullname,
                    presence.username,
                    presence.name,
                    presence.datetime,
                    presence.id,
                    users.coach
                FROM presence, users
                WHERE presence.eventid = ?
                AND presence.username = users.username
                ORDER BY presence.datetime"""
        r = self.cursor.execute(q, (int(eventid),))
        o = [
            {
                "username": row[0],
                "fullname": row[1],
                "name": row[3],
                "datetime": utc2local(row[4]),
                "coach": bool(row[6]),
                "id": row[5],
            }
            for row in r.fetchall()
        ]
        # guests
        q = """SELECT * FROM presence
            WHERE eventid = ?
            AND username IS NULL
            ORDER BY presence.datetime"""
        # TODO: put coaches at the end for junior events
        r = self.cursor.execute(q, (int(eventid),))
        for row in r.fetchall():
            o.append({"name": row[3], "datetime": utc2local(row[4]), "id": row[0]})
        return {"data": o}

    def delete_presence(self, id):
        q = """DELETE FROM presence WHERE id = ?"""
        self.cursor.execute(q, (int(id),))
        self.conn.commit()
        return {"message": "Presence deleted"}

    def post_comment(self, eventid, comment):
        q = "INSERT INTO comments (eventid, username, text) VALUES (?, ?, ?)"
        self.cursor.execute(q, (int(eventid), self.username, comment))
        self.conn.commit()
        return {"message": "OK"}

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
        return {
            "data": [
                {
                    "id": row[0],
                    "eventid": row[1],
                    "datetime": row[3],
                    "text": row[4],
                    "name": row[6] or row[5],
                }
                for row in r.fetchall()
            ]
        }

    @admin
    def delete_event(self, eventid):
        q = "DELETE FROM events WHERE id = ?"
        self.cursor.execute(q, (int(eventid),))
        self.conn.commit()
        q = "DELETE FROM presence WHERE eventid = ?"
        self.cursor.execute(q, (int(eventid),))
        self.conn.commit()
        return {"message": "Event removed"}

    @admin
    def post_restriction(self, eventid, restriction):
        q = "UPDATE events SET restriction = ? WHERE id = ?"
        r = self.cursor.execute(q, (restriction, int(eventid)))
        self.conn.commit()
        return {"data": "OK"}

    @admin
    def post_event(
        self,
        restriction: Optional[str] = "",
        title: Optional[str] = "",
        starts: Optional[str] = "",
        ends="",
        location="Zetor",
        capacity=0,
        courts=0,
        pinned=0,
    ):
        q = """INSERT INTO events
            (title, starts, ends, location, capacity, courts, restriction, pinned)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?);"""
        self.cursor.execute(
            q,
            (
                title,
                starts,
                ends,
                location,
                int(capacity),
                int(courts),
                restriction,
                int(pinned),
            ),
        )
        self.conn.commit()
        lastrowid = self.cursor.execute("SELECT last_insert_rowid();").fetchone()[0]
        return {"data": f"Event ID#{lastrowid} created"}

    @admin
    def put_event(self, name="", value=""):
        q = "UPDATE events SET ? = ?"
        self.cursor.execute(q, (name, value))
        self.conn.commit()
        return {"message": "Event updated"}

    @admin
    def post_guest(self, name, eventid):
        # TODO: test capacity?
        q = "INSERT INTO presence (eventid, name) VALUES (?, ?)"
        self.cursor.execute(q, (int(eventid), name))
        self.conn.commit()
        return {"message": "Guest added"}

    def post_register(self, eventid):
        # TODO: check if user is in restriction for the event
        if self._occupancy(eventid) <= 0:
            return {"error": "Capacity is full"}
        if self.username in [x["username"] for x in self.presence(eventid)["data"]]:
            return {"error": "Already registered"}
        q = """INSERT INTO presence
            (eventid, username)
            VALUES (%d, "%s")""" % (
            int(eventid),
            self.username,
        )
        self.cursor.execute(q)
        self.conn.commit()
        return {"data": "Registered"}

    def _occupancy(self, eventid):
        q = "SELECT count(*) FROM presence WHERE eventid = ?"
        r = self.cursor.execute(q, (int(eventid),)).fetchone()[0]
        q2 = "SELECT capacity FROM events WHERE eventid = ?"
        r2 = self.cursor.execute(q2, (int(eventid),)).fetchone()[0]
        return r2 - r

    def delete_register(self, eventid):
        q = """DELETE FROM presence WHERE username = ? AND eventid = ?"""
        self.cursor.execute(q, (self.username, int(eventid)))
        self.conn.commit()
        return {"unregistered": self.username}


if __name__ == "__main__":
    config = {k: v for k, v in os.environ.items() if k.startswith("PRESENCE_")}
    assert config.get("PRESENCE_DB_PATH")

    parser = argparse.ArgumentParser()
    parser.add_argument("--create", help="Create a new event", action="store_true")
    parser.add_argument("--port", help="Port", default=8000)
    args = parser.parse_args()

    if args.create:
        next_week = datetime.datetime.now() + datetime.timedelta(days=7)
        day = datetime.datetime.today().weekday()
        try:
            presence = Presence(config)
            for e in presence.get_recurrent_events()["data"]:
                if not day == e["day"]:
                    continue
                e["starts"] = next_week.strftime(e["starts"])
                presence.post_event(**e)
        except Exception as msg:
            logging.error("Failed to create event %s", str(msg))
    else:
        presence = Presence(config)
        with make_server("", args.port, functools.partial(app, cls=presence)) as httpd:
            httpd.serve_forever()
