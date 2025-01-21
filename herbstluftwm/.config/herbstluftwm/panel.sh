#!/usr/bin/env bash

# Terminate already running bar instances
 pkill -q lemonbar

# Wait until the processes have been shut down
while pgrep -u $UID -x lemonbar >/dev/null; do sleep 1; done

for monitor in $(herbstclient list_monitors | cut -d: -f1) ; do
    ~/private/barpyrus/barpyrus.py $monitor &
done
