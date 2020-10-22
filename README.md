# Presence

A simple sport event management.

## Requirements

* nginx
* Python 3
* sqlite3 and binding for Python
* cron

## Installation

1. Clone this repo or copy all its files into a directory.
1. Setup nginx.
1. Setup cronjob.

## Configuration

The configuration is done using environment variables.

* `PRESENCE_DB_PATH`: path to DB file (default: `./data/presence.db`)
* `PRESENCE_IN_ADVANCE`: how many hours before an event registration is allowed (default: 36)
* `PRESENCE_ADMIN_IDS`: user ids of admins
* `PRESENCE_COACH_IDS`: user ids of coaches
* `PRESENCE_EVENTS_PATH`: path to json file with regular events = "data/events.json"

## Coaches

Coaches are highlighted and sorted at the end of the list of participants.

## Regular events (cronjob)

`python3 presence.py --create` will read `PRESENCE_EVENTS_PATH` file and will create events accordingly.
