#!/usr/bin/python3

from bottle import route, run, static_file, request, response
import json
import sqlite3

def utc2local(t):
    t1 = datetime.datetime.strptime(t, '%Y-%m-%d %H:%M:%S')
    HERE = tz.tzlocal()
    UTC = tz.gettz('UTC')
    nt = t1.replace(tzinfo=UTC)
    return nt.astimezone(HERE).strftime('%Y-%m-%d %H:%M')

# TODO: favicon

connection = sqlite3.connect('presence.db')
cursor = connection.cursor()
events_file = 'events.json'
IN_ADVANCE = 36

@route('add_user')
def add_user():
    username = request.query.username
    fullname = request.query.fullname
    password = request.query.password
    import subprocess as sp
    if not is_admin:
        return {'error': 'You are not admin'}
    if get_user(username):
        return {'error': "Username already in use"}
    q = "INSERT INTO users (username, nickname, email) VALUES (?, ?, ?)"
    self.cursor.execute(q, (username, fullname.decode('utf-8'), username + '@dummymail.cz'))
    self.conn.commit()
    pf = getattr(self, "passfile", None)
    command = ["htpasswd", "-i", pf, username]
    p = sp.Popen(command, stdin=sp.PIPE, stdout=sp.PIPE)
    p.communicate(input=password)
    if p.returncode == 0:
        return {'message': "User %s created" % username}
    return {'error': 'User not created'}

def _parse_restriction(s):
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

def _late(t, hours=IN_ADVANCE):
    t1 = datetime.datetime.strptime(t, '%Y-%m-%d %H:%M:%S')
    now = datetime.datetime.now()
    delta = t1 - now
    return (delta.seconds//3600 + delta.days*24) < hours

def get_user(req):
    username = req.headers.get('X-Remote-User', 'anonym')
    return username
    username = req.environ.get("REMOTE_USER", req.environ.get('USER', 'anonym'))
    q = 'SELECT * FROM users WHERE username = ?;'
    r = cursor.execute(q, (username,)).fetchone()
    return username
    return r and {
        'x': username,
        'id': r[0],
        'username': r[1],
        'nickname': r[2],
        'admin': r[1].encode('utf-8') in self.admins
    } or {}

@route('/js/<filename>')
def serve_js(filename=''):
    return static_file(filename, root='./js')

@route('/<filename>')
def serve_static(filename='index.html'):
    return static_file(filename, root='.')

@route('/')
def serve_index():
    return serve_static()

@route('/events')
def events():
    user = get_user(request)
    return user
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
    r = cursor.execute(q)
    o = []
    for row in r.fetchall():
        restr = _parse_restriction(row[7])
        if restr and user["id"] not in restr:
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
            'locked': 'JUN' not in row[1] and _late(row[2], IN_ADVANCE),
            'in_advance': IN_ADVANCE,
            'restriction': restr
        })
    return {'data': o}

if __name__ == '__main__':
    run(host='localhost', port=8000, debug=True)
