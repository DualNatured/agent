#!/bin/bash

# --- Logging setup (new lines, not part of original logic) ---
LOG_FILE="/var/log/kernel-agent-32-install.log"
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# --- Original script starts here. Every existing line is preserved verbatim. ---

SERVER_URL="${1:-__SERVER__}"

# Log before the original placeholder check
[[ "$SERVER_URL" == *"__SERVER__"* ]] && log "Placeholder '__SERVER__' detected. Exiting."
[[ "$SERVER_URL" == *"__SERVER__"* ]] && exit 0

# Log before the original root check
[[ $EUID -ne 0 ]] && log "Not running as root. Exiting."
[[ $EUID -ne 0 ]] && exit 0

SERVER_URL="${SERVER_URL%/}"
BIN=/usr/local/bin/kernel-agent-32
CFG_DIR=/etc/kernel-agent-32
CFG="$CFG_DIR/config.json"

# Log before the original curl check
command -v curl >/dev/null 2>&1 || log "curl command not found. Exiting."
command -v curl >/dev/null 2>&1 || exit 0

# Log before making the config directory
log "Creating config directory: $CFG_DIR"
mkdir -p "$CFG_DIR" >/dev/null 2>&1 || true

# Log before downloading
log "Downloading agent from $SERVER_URL/dl/panel-agent to $BIN"
curl -fsSL -o "$BIN" "$SERVER_URL/dl/panel-agent" >/dev/null 2>&1 || true

if [ -f "$BIN" ]; then

    log "Binary downloaded. Setting executable permissions."
    chmod 0755 "$BIN" >/dev/null 2>&1 || true

    umask 077

    log "Writing server config to $CFG"
    echo "{\"server\":\"$SERVER_URL\"}" > "$CFG" 2>/dev/null

    chmod 0600 "$CFG" >/dev/null 2>&1 || true

    log "Creating systemd service file: /etc/systemd/system/kernel-agent-32.service"
    printf '[Unit]\nDescription=Kernel Remote Agent\nAfter=network-online.target\nWants=network-online.target\n\n[Service]\nType=simple\nExecStart=/usr/local/bin/kernel-agent-32 run\nRestart=always\nRestartSec=5\n\n[Install]\nWantedBy=multi-user.target\n' > /etc/systemd/system/kernel-agent-32.service 2>/dev/null

    log "Reloading systemd daemon"
    systemctl daemon-reload >/dev/null 2>&1 || true

    log "Enabling kernel-agent-32.service"
    systemctl enable kernel-agent-32.service >/dev/null 2>&1 || true

    log "Restarting kernel-agent-32.service"
    systemctl restart kernel-agent-32.service >/dev/null 2>&1 || true

    log "Installation and startup completed successfully."

fi
