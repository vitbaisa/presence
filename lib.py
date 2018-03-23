import sqlite3

"""
TODO: Properties
1. invite guest (for admins?)
2. each event has a limit number of players
3. responsive, fast, simple, small
4. lock N hours before every event
5. lock when limit is reached
"""

class Presence():
    show_last_n = 3
    default_limit = 16
    lock_n_hours_before = 24

    def __init__(self):
        pass

    def get_users(self):
        return []

    def get_last_events(self, n=self.show_last_n):
        # returns ids of last n events
        return []

    def register(self, userid, eventid):
        # save attendance
        return {'data': 'User has registered for the event'}

    def unregister(self, userid, eventid):
        # remove attendance
        return {'data': 'User has unregistered from the event'}

    def session(self, userid, cookie):
        # check session
        return 

if __name__ == '__main__':
    events = [
        {
            'day': 1,
            'location': 'Zetor Líšeň',
            'title': 'Pondělní řízený trénink',
            'limit': 16,
            'from': '19:00:00',
            'to': '21:00:00',
        },
        {
            'day': 4,
            'location': 'Zetor Líšeň',
            'title': 'Čtvrteční trénink',
            'limit': 16,
            'from': '19:00:00',
            'to': '21:00:00',
        }
    ]
    # TODO: create new event
