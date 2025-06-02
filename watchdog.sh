#!/bin/bash

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 command [args...]"
    exit 1
fi

# Extract current tmux session ID from the environment
TMUX_SESSION=$(tmux display-message -p '#S' 2>/dev/null)

if [[ -z "$TMUX_SESSION" ]]; then
    echo "Not inside a tmux session. Exiting."
    exit 2
fi

trap '' SIGINT SIGHUP SIGTERM

while tmux has-session -t "$TMUX_SESSION" 2>/dev/null; do
    script -q -c "$*" /dev/null
    EXIT_CODE=$?
    sleep 1
done

echo "Tmux session $TMUX_SESSION is gone. Exiting watchdog."
exit 0
