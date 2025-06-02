#!/bin/bash
clear

NICK="$1"
PASS="$2"
REAL_IP="$3"
SESSION="$4"
IRC_PORT="${IRC_PORT:-6669}"  # fallback if not set

export NICK
export PASS
export REAL_IP
export SESSION

TMPROOT="/mnt/sessions"
TMPDIR="$TMPROOT/$SESSION"

mkdir -p "$TMPDIR"

export HOME="$TMPDIR"

# Create Directories for Weechat
mkdir -p "$HOME/.weechat"

# Run proxy to pass real IP to IRC server
/usr/local/bin/tinyiproxy 127.0.0.1:${IRC_PORT} 172.17.0.1:6665 "${REAL_IP}" &

# Create WeeChat configuration (secure and locked down)
cat > "$HOME/.weechat/weechat.conf" <<EOF
[look]
buffer_time_format = "%H:%M"

[startup]
command_after_plugins = "/mute /plugin unload *; /mute /alias del exec; /mute /set weechat.plugin.autoload \"\""

[plugin]
autoload = ""

[env]
TERM = "$TERM"
EOF


cat > "$HOME/.weechat/irc.conf" <<EOF
[look]
server_buffer = independent

[server]
TransIRC.addresses = "127.0.0.1/$IRC_PORT"
TransIRC.ssl = off
TransIRC.nicks = "$NICK"
TransIRC.username = "$NICK"
TransIRC.realname = "$NICK"
TransIRC.autoconnect = on
TransIRC.sasl_mechanism = plain
TransIRC.sasl_username = "$NICK"
TransIRC.sasl_password = "$PASS"

[network]
TransIRC = on
EOF

# Launch WeeChat
exec weechat
