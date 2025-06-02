# Ergo SSH Gateway

**Ergo SSH Gateway** is a lightweight Dockerized SSH environment that lets users securely log in using their **Ergo IRC credentials via NickServ**, automatically launching an IRC client inside a locked-down `tmux` session.

It includes:
- [NickGate](https://github.com/transirc/nickgate): a custom SSH server authenticating against Ergo's NickServ API.
- [TinyiProxy](https://github.com/transirc/tinyiproxy): forwards IRC traffic to Ergo's IRCd using **PROXY protocol**, preserving the user's real IP.
- A preconfigured memory-only environment using `tmpfs` and environment variables for a secure, ephemeral session.

---

## 🔒 Features

- SSH login with IRC credentials via Ergo's NickServ API.
- Supports **PROXY protocol** to forward real IPs to Ergo.
- Minimal, isolated environment (runs under non-root `nickgate` user).
- In-memory config using `tmpfs` -- nothing is written to disk.
- Launches a secure, stripped-down WeeChat IRC session.
- Easily customizable `tmux`-based environment.
- SSH runs on port **2225** by default (can be changed).

---

## 🧠 How It Works

When a user connects over SSH:
1. NickGate verifies credentials using Ergo's `/v1/check_auth` API.
2. Upon success, the user is dropped into a custom `tmux` session.
3. A proxy is created between the user and the IRC server at `localhost:6665`.
4. `nickgate-entrypoint.sh` uses `setup-weechat.sh` to create a minimal WeeChat config with SASL auth and disables plugins and `/exec`.

---

## 🧰 Repository Contents

```

.\
├── build_ergo_ssh_gateway_container.sh # Build script (sets SSH port to 2225)\
├── dockerfile # Runs as unprivileged user 'nickgate'\
├── nickgate # Custom SSH server binary\
├── nickgate-entrypoint.sh # Entrypoint script for setting up IRC session\
├── nickgate.conf # Config: API endpoint and bearer token\
├── session_cleanup.sh # Cleans up sessions on disconnect\
├── setup-weechat.sh # Sets up secure WeeChat config\
├── ssh_host_keys/ # SSH host keys (required: rsa key!)\
├── supervisord.conf # Supervisor config for service startup\
├── tinyiproxy # Lightweight PROXY-protocol-aware IRC proxy\
├── tmux.conf.restricted # Restricts tmux capabilities\
└── watchdog.sh # Restarts scripts if they crash

```

---

## ⚙️ Setup Instructions

1.  **Update `nickgate.conf`**:

    ```
    [auth]
    api_url = http://172.17.0.1:8089/v1/check_auth
    bearer_token = YOUR_SECRET_TOKEN

    ```

2.  **Place your SSH host keys in `ssh_host_keys/`** (required):

    -   `ssh_host_rsa_key` (REQUIRED)

    -   `ssh_host_ed25519_key` *(optional)*

    -   `ssh_host_ecdsa_key` *(optional)*

3.  **Edit `nickgate-entrypoint.sh`** if you'd like to:

    -   Add more `tmux` windows or utilities.

    -   Change the ASCII art welcome message (`figlet` title).

    -   Launch different IRC clients or games.

4.  **Ensure your Ergo IRC server has a plain-text listener on `6665` with PROXY support.**

5. **Build the container**:
   ```bash
   ./build_ergo_ssh_gateway_container.sh

* * * * *

🔧 Example Ergo Config Snippet (for PROXY support)
--------------------------------------------------

In your Ergo `config.yaml`, add:

```
listeners:
  - port: 6665
    tls: false
    proxy_protocol: true
    bind: 0.0.0.0
    allowed_proxy_ips:
      - 172.17.0.1  # IP of the Docker host or container

accounts:
  require_sasl: true

```

Make sure your Ergo instance allows plaintext auth and proxy protocol on that port.

* * * * *

🛡 Security Notes
-----------------

-   Everything runs as the **unprivileged user `nickgate`** inside the container.

-   Uses `tmpfs` to avoid writing any sensitive data to disk.

-   WeeChat config disables plugin loading, script execution, and `/exec` alias.

-   Users are sandboxed in `tmux`, with customization permitted only through `nickgate-entrypoint.sh`.

* * * * *

📦 Default Ports
----------------

| Service | Port |
| --- | --- |
| SSH Gateway | 2225 |

To change the SSH port, edit `build_ergo_ssh_gateway_container.sh`.

* * * * *

💬 Example Usage
----------------

```
ssh -p 2225 yournick@your.gateway.host
# Enter your NickServ password when prompted

```

* * * * *

❤️ Credits
----------

-   [Ergo IRC Server](https://ergo.chat/)

-   [NickGate](https://github.com/transirc/nickgate)

-   Custom tooling and environment by TransIRC
```
