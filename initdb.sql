CREATE TABLE users (
    INTEGER id,
    VARCHAR username,
    VARCHAR name,
    DATE created,
    DATE last_access,
    VARCHAR cookie,
    VARCHAR password
);

CREATE TABLE events (
    INTEGER id,
    VARCHAR title,
    DATETIME from,
    DATETIME to,
    VARCHAR location,
    INTEGER limit
)

CREATE TABLE presence (
    INTEGER id,
    INTEGER users_id,
    INTEGER events_id,
    VARCHAR guest,
    DATE datetime
)
