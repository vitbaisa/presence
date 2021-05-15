#!/usr/bin/python3

import os
import json
import sqlite3
import functools
import datetime
import logging
import argparse
import subprocess

from wsgiref.simple_server import make_server
from urllib.parse import parse_qs
from typing import Optional, List, Union, Tuple


def admin(method):
    @functools.wraps(method)
    def _impl(self, *method_args, **method_kwargs):
        if method_kwargs.get("username", None) in self.admins:
            return method(self, *method_args, **method_kwargs)
        return {"error": "Unauthorized"}

    return _impl


HTML_HEADER = ("Content-type", "text/html; charset=utf-8")
JSON_HEADER = ("Content-type", "application/json; charset=utf-8")
JS_HEADER = ("Content-type", "text/javascript; charset=utf-8")


def app(environ, start_response, cls=None) -> List[bytes]:
    http_method = environ["REQUEST_METHOD"].lower()
    try:
        size = int(environ.get("CONTENT_LENGTH", 0))
    except ValueError:
        size = 0
    path = environ["PATH_INFO"].split("/")[1:]
    if http_method == "get":
        query = {k: v[0] for k, v in parse_qs(environ["QUERY_STRING"]).items()}
    else:
        query = json.loads(
            environ["wsgi.input"].read(size).decode("utf-8") or "{}"
        )
    username = environ.get("HTTP_X_REMOTE_USER", None)
    status, headers, response = cls.serve(
        environ, http_method, path, {**query, "username": username}
    )
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
        self.in_advance = self.config["PRESENCE_IN_ADVANCE"]
        self.passwd_file = self.config["PRESENCE_PASSWD_FILE"]
        self.events_file = self.config["PRESENCE_EVENTS_FILE"]

    @functools.lru_cache
    def serve_local_file(self, path):
        with open(path) as f:
            return f.read()

    def _init_db(self):
        conn = sqlite3.connect(config["PRESENCE_DB_PATH"], isolation_level=None)
        cursor = conn.cursor()
        cursor.execute("DROP TABLE IF EXISTS users;")
        cursor.execute(
            """
            CREATE TABLE users (
                id          INTEGER PRIMARY KEY,
                username    CHAR(30) NOT NULL UNIQUE,
                nickname    CHAR(30) UNIQUE,
                email       CHAR(50) NOT NULL UNIQUE
            );
            """
        )
        cursor.execute("DROP TABLE IF EXISTS events;")
        cursor.execute(
            """
            CREATE TABLE events (
                id          INTEGER PRIMARY KEY,
                title       CHAR(50) NOT NULL,
                starts      DATETIME,
                duration    INTEGER DEFAULT 2,
                location    CHAR(50) DEFAULT "Zetor",
                capacity    INTEGER DEFAULT 16,
                courts      INTEGER DEFAULT 4,
                restriction CHAR(128),
                class       CHAR(1),
                pinned      INTEGER
            );
            """
        )
        cursor.execute("DROP TABLE IF EXISTS presence;")
        cursor.execute(
            """
            CREATE TABLE presence (
                id          INTEGER PRIMARY KEY,
                eventid     INTEGER NOT NULL,
                userid      INTEGER DEFAULT -1,
                name        CHAR(30),
                datetime    DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (eventid) REFERENCES events(id),
                FOREIGN KEY (userid) REFERENCES users(id),
                UNIQUE (eventid, name) ON CONFLICT REPLACE
            );
            """
        )
        cursor.execute("DROP TABLE IF EXISTS comments;")
        cursor.execute(
            """
            CREATE TABLE comments (
                id          INTEGER PRIMARY KEY,
                eventid     INTEGER NOT NULL,
                userid      INTEGER NOT NULL,
                datetime    DATETIME DEFAULT CURRENT_TIMESTAMP,
                text        TEXT,
                FOREIGN KEY (userid)  REFERENCES users(id),
                FOREIGN KEY (eventid) REFERENCES events(id)
            """
        )
        conn.commit()
        return conn, cursor

    def serve(
        self, environ: dict, http_method: str, path: List[str], query: dict,
    ) -> Tuple[str, List[Tuple[str, str]], Union[dict, str]]:

        headers = [JSON_HEADER]
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
            ret = getattr(self, http_method + "_" + path[0])(**query)
        return (status, headers, ret)

    def get_user(self, username: str, **argv) -> dict:
        q = "SELECT * FROM users WHERE username = ?"
        row = self.cursor.execute(q, (username, )).fetchone()
        return {
            **row,
            "username": username,
            "admin": username in self.admins,
            "coach": username in self.coaches,
        }

    @admin
    def post_user(
        self, newusername: str, nickname: str, password: str, **argv
    ) -> dict:
        q = "SELECT username FROM users WHERE username = ?"
        r = self.cursor.execute(q, (newusername,)).fetchone()
        logging.warning("POST USER CHECK EXISTING: %s", repr(r))
        if r is None:
            p = subprocess.Popen(
                ["htpasswd", "-i", self.passwd_file, newusername],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
            )
            p.communicate(input=password.encode('utf-8'))
            if p.returncode == 0:
                q = "INSERT INTO users (username, nickname) VALUES (?, ?)"
                self.cursor.execute(q, (newusername, nickname))
                self.conn.commit()
                return {'message': "User %s created" % newusername}
            return {'error': "Failed to add user %s" % newusername}
        return {'error': "User %s already exists" % newusername}


    @admin
    def delete_user(self, delusername: str, **argv) -> dict:
        p = subprocess.Popen(["htpasswd", "-D", self.passwd_file, delusername])
        q = "DELETE * FROM users WHERE username = ?"
        self.cursor.execute(q, (delusername,))
        self.conn.commit()
        return {'message': f"User {delusername} removed"}

    def get_events(self, username: str, **argv) -> dict:
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
        o = []
        u = self.get_user(username)
        logging.warning(u)
        r = self.cursor.execute(q)
        for row in r:
            restr = [int(x) for x in row["restriction"].split(",") if x.strip()]
            logging.warning(restr)
            if restr and u["id"] not in restr:
                logging.warning(
                    f"User {username} should not see event #{row['id']}"
                )
                continue
            t1 = datetime.datetime.strptime(row["starts"], "%Y-%m-%d %H:%M:%S")
            now = datetime.datetime.now()
            delta = t1 - now
            o.append(
                {
                    **row,
                    "junior": row["class"] == "J",
                    "locked": row["class"] == "J" and (
                        delta.seconds // 3600 + delta.days * 24
                    ) < self.in_advance,
                    "in_advance": self.in_advance,
                    "restriction": restr,
                }
            )
        # TODO: put coaches at the end for junior events
        return {"data": o}

    def get_recurrent_events(self, **argv) -> dict:
        with open(self.events_file) as f:
            events = json.load(f)
            for ev in events["events"]:
                ev["restriction"] = ev["restriction"].split(",")
            return {"data": events}

    @admin
    def post_recurrent_events(self, data: dict, **argv) -> dict:
        assert isinstance(data, dict)
        logging.warning("Changing recurrent events")
        with open(self.events_file, "w") as f:
            json.dump(data, f)
        return data

    @admin
    def put_courts(self, eventid: int, courts: int, **argv) -> dict:
        q = "UPDATE events SET courts = ? WHERE id = ?"
        self.cursor.execute(q, (courts, eventid))
        self.conn.commit()
        return {"data": "Update event #%d, courts: %d" % (eventid, courts)}

    @admin
    def put_capacity(self, eventid: int, capacity: int, **argv) -> dict:
        q = "UPDATE events SET capacity = ? WHERE id = ?"
        self.cursor.execute(q, (capacity, eventid))
        self.conn.commit()
        return {"data": "Update event #%d, capacity: %d" % (eventid, capacity)}

    def get_presence(self, eventid: int, **argv) -> dict:
        q = """SELECT users.username as username,
                    users.nickname as nickname,
                    presence.username,
                    presence.name as name,
                    presence.datetime as datetime,
                    presence.id as id,
                    users.coach as coach
                FROM presence, users
                WHERE presence.eventid = ?
                AND presence.username = users.username
                ORDER BY presence.datetime"""
        o = self.cursor.execute(q, (eventid,)).fetchall()
        # guests
        q = """SELECT * FROM presence
            WHERE eventid = ?
            AND username IS NULL
            ORDER BY presence.datetime"""
        # TODO: put coaches at the end for junior events
        o.extend(self.cursor.execute(q, (eventid,)).fetchall())
        return {"data": o}

    def delete_presence(self, id_: int, **argv) -> dict:
        q = "DELETE FROM presence WHERE id = ?"
        self.cursor.execute(q, (id_,))
        self.conn.commit()
        return {"message": "Presence #%d deleted" % id_}

    def post_comment(
        self, eventid: int, comment: str, username: str, **argv
    ) -> dict:
        q = "INSERT INTO comments (eventid, username, text) VALUES (?, ?, ?)"
        self.cursor.execute(q, (eventid, username, comment))
        self.conn.commit()
        return {"message": "Comment by %s successfully added" % username}

    def get_comments(self, eventid: int, **argv) -> dict:
        q = """SELECT comments.id as id,
                    comments.eventid as eventid,
                    comments.username,
                    comments.datetime as datetime,
                    comments.text as text,
                    users.username,
                    users.nickname
                FROM comments, users
                WHERE eventid = ?
                AND users.username = comments.username
                ORDER BY datetime DESC;"""
        r = self.cursor.execute(q, (eventid,))
        return {"data": r.fetchall()}

    @admin
    def delete_event(self, eventid: int, **argv) -> dict:
        q = "DELETE FROM events WHERE id = ?"
        self.cursor.execute(q, (eventid,))
        self.conn.commit()
        q = "DELETE FROM presence WHERE eventid = ?"
        self.cursor.execute(q, (eventid,))
        self.conn.commit()
        return {"message": "Event #%d removed" % eventid}

    @admin
    def post_restriction(self, eventid: int, restriction: str, **argv) -> dict:
        q = "UPDATE events SET restriction = ? WHERE id = ?"
        r = self.cursor.execute(q, (restriction, eventid))
        self.conn.commit()
        return {
            "data": "Update event #%d, restriction: %s" % (eventid, restriction)
        }

    @admin
    def post_event(
        self,
        title: str,
        restriction: Optional[str] = "",
        starts: Optional[str] = "",
        duration: Optional[int] = 2,
        location: Optional[str] = "Zetor",
        capacity: Optional[int] = 0,
        courts: Optional[int] = 0,
        pinned: Optional[int] = 0,
        junior: Optional[int] = 0,
        **argv,
    ) -> dict:
        q = """INSERT INTO events
            (title, starts, duration, location, capacity, courts, restriction, pinned, class)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);"""
        self.cursor.execute(
            q,
            (
                title,
                starts,
                duration,
                location,
                capacity,
                courts,
                restriction,
                pinned,
                junior and "J" or ""
            ),
        )
        self.conn.commit()
        lastrowid = self.cursor.execute("SELECT last_insert_rowid();").fetchone()[0]
        return {"data": f"Event #{lastrowid} created"}

    @admin
    def put_event(self, eventid: int, name: str, value: int, **argv) -> dict:
        q = f"UPDATE events SET {name} = ?"
        self.cursor.execute(q, (value,))
        self.conn.commit()
        return {"message": f"Event #{eventid} updated, pinned: {value}"}

    @admin
    def post_guest(self, name: str, eventid: int, **argv) -> dict:
        # TODO: test capacity
        q = "INSERT INTO presence (eventid, name) VALUES (?, ?)"
        self.cursor.execute(q, (eventid, name))
        self.conn.commit()
        return {"message": f"Guest {name} added to event #{eventid}"}

    def post_register(self, eventid: int, username: str, **argv) -> dict:
        # TODO: check if user is in restriction for the event
        if self._occupancy(eventid) <= 0:
            return {"error": "Capacity is full!"}

        if username in [
            x["username"] for x in self.get_presence(eventid)["data"]
        ]:
            return {"error": "Already registered"}

        q = "INSERT INTO presence (eventid, username) VALUES (?, ?)"
        self.cursor.execute(q, (eventid, username))
        self.conn.commit()
        return {"data": f"{username} registered for event #{eventid}"}

    def _occupancy(self, eventid: int) -> int:
        q = "SELECT count(*) FROM presence WHERE eventid = ?"
        r = self.cursor.execute(q, (eventid,)).fetchone()[0]
        q2 = "SELECT capacity FROM events WHERE eventid = ?"
        r2 = self.cursor.execute(q2, (eventid,)).fetchone()["capacity"]
        return r2 - r

    def delete_register(self, eventid: int, username: str, **argv) -> dict:
        q = "DELETE FROM presence WHERE username = ? AND eventid = ?"
        self.cursor.execute(q, (username, eventid))
        self.conn.commit()
        return {"message": f"{username} unregistered from event #{eventid}"}


if __name__ == "__main__":
    config = {k: v for k, v in os.environ.items() if k.startswith("PRESENCE_")}

    parser = argparse.ArgumentParser()
    parser.add_argument("--db", help="Path to SQLite DB file", required=True)
    parser.add_argument(
        "--create", help="Create a new event", action="store_true"
    )
    parser.add_argument("--port", help="Port", default=8000)
    parser.add_argument(
        "--in_advance", help="Lock event X minutes in advance", default=36
    )
    parser.add_argument(
        "--eventsfile", help="JSON file with recurrent events", required=True,
    )
    parser.add_argument(
        "--passwdfile", help="BasicAuth passwd file", required=True,
    )
    args = parser.parse_args()

    config["PRESENCE_DB_PATH"] = args.db
    config["PRESENCE_IN_ADVANCE"] = args.in_advance
    config["PRESENCE_EVENTS_FILE"] = args.eventsfile
    config["PRESENCE_PASSWD_FILE"] = args.passwdfile

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
