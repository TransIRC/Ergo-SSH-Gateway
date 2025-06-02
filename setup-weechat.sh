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
ErgoIRC.addresses = "127.0.0.1/$IRC_PORT"
ErgoIRC.ssl = off
ErgoIRC.nicks = "$NICK"
ErgoIRC.username = "$NICK"
ErgoIRC.realname = "$NICK"
ErgoIRC.autoconnect = on
ErgoIRC.sasl_mechanism = plain
ErgoIRC.sasl_username = "$NICK"
ErgoIRC.sasl_password = "$PASS"

[network]
ErgoIRC = on
EOF

# Launch WeeChat
exec weechat
