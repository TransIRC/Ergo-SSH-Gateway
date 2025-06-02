#!/bin/bash

set +m
trap '' SIGTSTP

# --- Configuration ---
TMUX_CONF="/usr/local/share/tmux.conf.restricted"
FIGLET_FONTS=("big" "block" "chunky" "colossal" "doom" "epic" "slant" "standard")
RESERVED_PORTS=(6667 6668 6697)

# --- Colors ---
COLOR_BLUE="\e[34m"
COLOR_MAGENTA="\e[35m"
COLOR_CYAN="\e[36m"
COLOR_BOLD="\e[1m"
COLOR_RESET="\e[0m"

# --- Width Detection ---
MAX_WIDTH=$(tput cols 2>/dev/null)
[ -z "$MAX_WIDTH" ] || [ "$MAX_WIDTH" -lt 100 ] && MAX_WIDTH=120

center_text() {
    local text="$1"
    local clean_text=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local text_len=${#clean_text}
    local padding=$(( (MAX_WIDTH - text_len) / 2 ))
    [ "$padding" -lt 0 ] && padding=0
    echo -e "$(printf "%*s" "$padding" "")$text"
}

# --- Banner ---
clear
echo -e "${COLOR_BLUE}${COLOR_BOLD}"
RANDOM_FONT="${FIGLET_FONTS[$RANDOM % ${#FIGLET_FONTS[@]}]}"
figlet -f "$RANDOM_FONT" -w "$MAX_WIDTH" "Ergo SSH Gateway" 2>/dev/null | while IFS= read -r line; do center_text "$line"; done
if [ $? -ne 0 ] || [ -z "$(figlet -f "$RANDOM_FONT" -w "$MAX_WIDTH" "Ergo SSH Gateway" 2>/dev/null)" ]; then
    center_text "Ergo SSH Gateway"
fi
echo -e "${COLOR_RESET}"

echo

# --- Validate NICK/PASS ---
if [ -z "$NICK" ] || [ -z "$PASS" ]; then
    echo -e "${COLOR_BOLD}${COLOR_MAGENTA}Error: NICK or PASS environment variables are not set. Exiting.${COLOR_RESET}"
    sleep 2
    exit 1
fi

# --- Export required variables ---
export NICK
export PASS
export REAL_IP

# --- Randomize IRC port (excluding reserved ones) ---
while :; do
    IRC_PORT=$(( (RANDOM % 1000) + 6600 ))
    if [[ ! " ${RESERVED_PORTS[*]} " =~ " ${IRC_PORT} " ]]; then
        break
    fi
done

sleep 3
clear

# --- Unique Session Name ---
RAND_ID=$RANDOM
SESSION="${NICK}"
export SESSION


tmux kill-session -t "$SESSION" 2>/dev/null
tmux -f "$TMUX_CONF" new-session -d -s "$SESSION" -n IRC

# Ensure that tmux session has access to variables
tmux set-environment -t "$SESSION" NICK "$NICK"
tmux set-environment -t "$SESSION" PASS "$PASS"
tmux set-environment -t "$SESSION" REAL_IP "$REAL_IP"

# === IRC Window ===
tmux send-keys -t "$SESSION":0.0 \
"export NICK=\"$NICK\" PASS=\"$PASS\" REAL_IP=\"$REAL_IP\" IRC_HOST=127.0.0.1 IRC_PORT=$IRC_PORT SESSION=\"$SESSION\"; /usr/local/bin/watchdog.sh /usr/local/bin/setup-weechat.sh \"$NICK\" \"$PASS\" \"$REAL_IP\" \"$SESSION\"" C-m


# === CREATE OTHER WINDOWS HERE ===


# === Attach to Session ===
tmux select-window -t "$SESSION":0
tmux select-pane -t "$SESSION":0.1
exec tmux -f "$TMUX_CONF" attach-session -t "$SESSION"
