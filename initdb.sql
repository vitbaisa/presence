CREATE TABLE users (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    username    CHAR(30) NOT NULL UNIQUE,
    email       CHAR(50) NOT NULL
);

CREATE TABLE events (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    title       CHAR(50) NOT NULL,
    starts      DATETIME,
    ends        DATETIME,
    location    CHAR(50),
    capacity    INTEGER,
    courts      INTEGER
);

CREATE TABLE presence (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    eventid     INTEGER NOT NULL,
    userid      INTEGER,
    guestname   CHAR(20),
    datetime    DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (eventid) REFERENCES events(id),
    FOREIGN KEY (userid) REFERENCES users(id)
);

CREATE TABLE comments (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    eventid     INTEGER NOT NULL,
    userid      INTEGER NOT NULL,
    datetime    DATETIME DEFAULT CURRENT_TIMESTAMP,
    text        TEXT,
    FOREIGN KEY (userid) REFERENCES users(id)
);
