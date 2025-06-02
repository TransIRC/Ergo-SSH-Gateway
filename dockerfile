FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    weechat \
    bash \
    tmux \
    figlet \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Create a dedicated 'nickgate' system user with UID 1000 (so tmux uses /home/nickgate/.tmux/tmux-1000)
RUN useradd -u 1000 -m -s /bin/bash nickgate

# Supervisor config directory
RUN mkdir -p /etc/supervisor/conf.d

# Create TempFS mountpoint for IRC configuration; owned by nickgate
RUN mkdir -p /mnt/sessions && \
    chown nickgate:nickgate /mnt/sessions && \
    chmod 755 /mnt/sessions

# Copy SSH host keys into /etc/ssh/ssh_host_keys, owned by root:sshkeys group
COPY ssh_host_keys/ /etc/ssh/ssh_host_keys/
RUN groupadd sshkeys && \
    chown -R root:sshkeys /etc/ssh/ssh_host_keys && \
    find /etc/ssh/ssh_host_keys -type f ! -name "*.pub" -exec chmod 640 {} \; && \
    find /etc/ssh/ssh_host_keys -type f -name "*.pub" -exec chmod 644 {} \; && \
    usermod -aG sshkeys nickgate

# Copy Nickgate (the SSH server) and its config, owned by nickgate
COPY nickgate /usr/local/bin/nickgate
COPY nickgate.conf /usr/local/bin/nickgate.conf
RUN chmod 750 /usr/local/bin/nickgate && \
    chown nickgate:sshkeys /usr/local/bin/nickgate /usr/local/bin/nickgate.conf

# Copy Nickgate entrypoint for TMUX session startup, owned by nickgate
COPY nickgate-entrypoint.sh /usr/local/bin/nickgate-entrypoint.sh
RUN chmod 750 /usr/local/bin/nickgate-entrypoint.sh && \
    chown nickgate:nickgate /usr/local/bin/nickgate-entrypoint.sh

# Copy tmux session cleanup script, owned by nickgate
COPY session_cleanup.sh /usr/local/bin/session_cleanup.sh
RUN chmod 750 /usr/local/bin/session_cleanup.sh && \
    chown nickgate:nickgate /usr/local/bin/session_cleanup.sh

# Log files—owned by nickgate so it can read/write
RUN mkdir -p /var/log && \
    touch /var/log/nickgate.log /var/log/tinyiproxy.log && \
    chown nickgate:nickgate /var/log/nickgate.log /var/log/tinyiproxy.log && \
    chmod 640 /var/log/nickgate.log /var/log/tinyiproxy.log

# Copy watchdog script, owned by nickgate
COPY watchdog.sh /usr/local/bin/watchdog.sh
RUN chmod 750 /usr/local/bin/watchdog.sh && \
    chown nickgate:nickgate /usr/local/bin/watchdog.sh

# Copy TinyiProxy binary, owned by nickgate
COPY tinyiproxy /usr/local/bin/tinyiproxy
RUN chmod 750 /usr/local/bin/tinyiproxy && \
    chown nickgate:nickgate /usr/local/bin/tinyiproxy

# Weechat Setup Script, owned by nickgate
COPY setup-weechat.sh /usr/local/bin/setup-weechat.sh
RUN chmod 750 /usr/local/bin/setup-weechat.sh && \
    chown nickgate:nickgate /usr/local/bin/setup-weechat.sh

# Copy Tmux config; owned by nickgate
COPY tmux.conf.restricted /usr/local/share/tmux.conf.restricted
RUN chown nickgate:nickgate /usr/local/share/tmux.conf.restricted && \
    chmod 640 /usr/local/share/tmux.conf.restricted

# Supervisor configuration: ensure each [program:x] has “user=nickgate”
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose NickGate SSH port
EXPOSE 2222

# Start supervisord (which will launch the nickgate SSH server as user=nickgate)
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
