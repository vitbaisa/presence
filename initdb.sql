CREATE TABLE users (
    id          INTEGER PRIMARY KEY,
    username    CHAR(30) NOT NULL UNIQUE,
    nickname    CHAR(30) UNIQUE,
    email       CHAR(50) NOT NULL UNIQUE,
    password    CHAR(30) NOT NULL
);

CREATE TABLE events (
    id          INTEGER PRIMARY KEY,
    title       CHAR(50) NOT NULL,
    starts      DATETIME,
    duration    INTEGER DEFAULT 2,
    location    CHAR(50),
    capacity    INTEGER DEFAULT 16,
    courts      INTEGER DEFAULT 4,
    restriction CHAR(128),
    pinned      INTEGER DEFAULT 0
);

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

CREATE TABLE comments (
    id          INTEGER PRIMARY KEY,
    eventid     INTEGER NOT NULL,
    userid      INTEGER NOT NULL,
    datetime    DATETIME DEFAULT CURRENT_TIMESTAMP,
    text        TEXT,
    FOREIGN KEY (userid)  REFERENCES users(id),
    FOREIGN KEY (eventid) REFERENCES events(id)
);
