INSERT INTO users (username, email) VALUES ('Vít Baisa', 'vit.baisa@gmail.com');
INSERT INTO users (username, email) VALUES ('Jan Vodák', 'vit.baisa+2@gmail.com');
INSERT INTO users (username, email) VALUES ('Zdeněk Mejzlík', 'vit.baisa+3@gmail.com');
INSERT INTO users (username, email) VALUES ('Hana Pospíšilová', 'vit.baisa+4@gmail.com');
INSERT INTO users (username, email) VALUES ('Martin Svoboda', 'vit.baisa+5@gmail.com');

INSERT INTO events (title, starts, ends, location, capacity, courts) VALUES ('Čtvrtek, volná hra', '2018-03-22 19:00:00', '2018-03-22 21:00:00', 'Zetor', 20, 4);
INSERT INTO events (title, starts, ends, location, capacity, courts) VALUES ('Neděle, volná hra', '2018-03-25 19:00:00', '2018-03-25 21:00:00', 'Zetor', 16, 4);
INSERT INTO events (title, starts, ends, location, capacity, courts) VALUES ('Pondělí, řízený trénink', '2018-03-26 19:00:00', '2018-03-26 21:00:00', 'Zetor', 20, 4);
INSERT INTO events (title, starts, ends, location, capacity, courts) VALUES ('Čtvrtek, volná hra', '2018-03-29 19:00:00', '2018-03-22 21:00:00', 'Zetor', 16, 4);
INSERT INTO events (title, starts, ends, location, capacity, courts) VALUES ('Neděle, volná hra', '2018-04-01 19:00:00', '2018-03-25 21:00:00', 'Zetor', 16, 4);
INSERT INTO events (title, starts, ends, location, capacity, courts) VALUES ('Pondělí, trénink', '2018-04-02 19:00:00', '2018-03-25 21:00:00', 'Zetor', 20, 5);

INSERT INTO presence (eventid, userid) VALUES (1, 1);
INSERT INTO presence (eventid, userid) VALUES (1, 2);
INSERT INTO presence (eventid, userid) VALUES (1, 3);
INSERT INTO presence (eventid, userid) VALUES (1, 4);
INSERT INTO presence (eventid, userid) VALUES (1, 1);
INSERT INTO presence (eventid, userid) VALUES (1, 2);
INSERT INTO presence (eventid, userid) VALUES (2, 3);
INSERT INTO presence (eventid, userid) VALUES (3, 1);
INSERT INTO presence (eventid, userid) VALUES (3, 2);
INSERT INTO presence (eventid, userid) VALUES (3, 3);
INSERT INTO presence (eventid, userid) VALUES (3, 4);
INSERT INTO presence (eventid, userid) VALUES (4, 1);
INSERT INTO presence (eventid, userid) VALUES (4, 2);

INSERT INTO comments (eventid, userid, text) VALUES (1, 2, 'Sorry, bolí mě noha, nejdu');
INSERT INTO comments (eventid, userid, text) VALUES (1, 3, 'Zapomněl jsem.');
INSERT INTO comments (eventid, userid, text) VALUES (2, 2, 'Sorry, bolí mě noha, nejdu');
INSERT INTO comments (eventid, userid, text) VALUES (3, 2, 'Sorry, bolí mě noha, nejdu');
INSERT INTO comments (eventid, userid, text) VALUES (3, 3, 'Zaspal jsem!');
INSERT INTO comments (eventid, userid, text) VALUES (3, 4, 'Beru nové míče na odkoušení!');
