INSERT INTO users (username, email) VALUES ('Vít Baisa', 'vit.baisa@gmail.com');
INSERT INTO users (username, email) VALUES ('Jan Vodák', 'jan@vodak.net');
INSERT INTO users (username, email) VALUES ('Zdeněk Mejzlík', 'vit.baisa+3@gmail.com');
INSERT INTO users (username, nickname, email) VALUES ('Hana Pospíšilová', 'Hanka Pospíšilová', 'vit.baisa+4@gmail.com');
INSERT INTO users (username, nickname, email) VALUES ('Martin Svoboda', 'Máca', 'vit.baisa+5@gmail.com');

INSERT INTO events (title, starts) VALUES ('Čtvrtek, volná hra',      '2018-04-12 19:00:00');
INSERT INTO events (title, starts) VALUES ('Neděle, volná hra',       '2018-04-15 19:00:00');
INSERT INTO events (title, starts) VALUES ('Pondělí, řízený trénink', '2018-04-16 19:00:00');
INSERT INTO events (title, starts, restriction) VALUES ('Středa, Vojta', '2018-04-18 07:30:00', '1,2,3');
INSERT INTO events (title, starts) VALUES ('Čtvrtek, volná hra',      '2018-04-19 19:00:00');

INSERT INTO presence (eventid, userid) VALUES (1, 1);
INSERT INTO presence (eventid, userid) VALUES (1, 2);
INSERT INTO presence (eventid, userid) VALUES (1, 3);
INSERT INTO presence (eventid, userid) VALUES (1, 4);
INSERT INTO presence (eventid, userid) VALUES (2, 2);
INSERT INTO presence (eventid, userid) VALUES (2, 3);
INSERT INTO presence (eventid, userid) VALUES (3, 1);
INSERT INTO presence (eventid, userid) VALUES (3, 2);
INSERT INTO presence (eventid, userid) VALUES (3, 3);
INSERT INTO presence (eventid, userid) VALUES (3, 4);
INSERT INTO presence (eventid, userid) VALUES (4, 1);
INSERT INTO presence (eventid, userid) VALUES (5, 1);
INSERT INTO presence (eventid, userid) VALUES (5, 2);

INSERT INTO comments (eventid, userid, text) VALUES (1, 2, 'Sorry, bolí mě noha, nejdu');
INSERT INTO comments (eventid, userid, text) VALUES (1, 3, 'Zapomněl jsem.');
INSERT INTO comments (eventid, userid, text) VALUES (2, 2, 'Sorry, bolí mě noha, nejdu');
INSERT INTO comments (eventid, userid, text) VALUES (3, 2, 'Sorry, bolí mě noha, nejdu');
INSERT INTO comments (eventid, userid, text) VALUES (3, 3, 'Zaspal jsem!');
INSERT INTO comments (eventid, userid, text) VALUES (3, 4, 'Beru nové míče na odkoušení!');
