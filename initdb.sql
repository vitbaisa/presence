CREATE TABLE users (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    username    CHAR(20) NOT NULL UNIQUE,
    name        CHAR(50),
    last_access DATETIME DEFAULT CURRENT_TIMESTAMP,
    sessionid   CHAR(50),
    password    CHAR(50)
);

CREATE TABLE events (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    title       CHAR(50) NOT NULL,
    starts      DATETIME,
    ends        DATETIME,
    location    CHAR(50),
    maxplayers  INTEGER
);

CREATE TABLE presence (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    eventid     INTEGER NOT NULL,
    userid      INTEGER NOT NULL,
    guest       CHAR(20),
    time        DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (eventid) REFERENCES events(id),
    FOREIGN KEY (userid) REFERENCES users(id)
);
