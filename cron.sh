#/bin/bash

wget --quiet "https://vitek.baisa.net/presence/index.cgi/events" --user="Vít Baisa" --password="xxx" -O - | grep Baisa
