#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────
# Hawser (Dockhand Agent) Installer
# Mirror of setup-periphery.sh (Komodo) but for
# https://github.com/Finsys/hawser
# Supports: systemd, OpenRC, sysvinit, runit, launchd
# ──────────────────────────────────────────────

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Install init-system-managed Hawser (Dockhand remote Docker agent).

Connection modes:
  edge      (default) Agent initiates an outbound WebSocket to Dockhand.
                     Works behind NAT/firewalls/dynamic IP. No inbound ports.
  standard           Agent listens for inbound connections (LAN / static IP).

Options:
  -v, --version VERSION        Install a specific Hawser version, like 'v0.1.0'
  -u, --user                   Install systemd '--user' service (systemd only)
  -m, --mode MODE              Connection mode: edge | standard (default: edge)
  -s, --stacks-dir DIR         Stacks directory for compose stacks (default: /data/stacks)
  -c, --dockhand-url URL       Dockhand WebSocket endpoint for outbound connection.
                               Edge mode. Example: wss://dockhand.example.com/api/hawser/connect
  -t, --token TOKEN            Agent token generated in Dockhand UI
                               (Settings -> Environments -> Hawser - Edge). REQUIRED for edge mode.
  -n, --connect-as NAME        Agent name shown in Dockhand (default: hostname)
      --port PORT              Listen port, standard mode (default: 2376)
      --bind-address ADDR      Edge: default 127.0.0.1 (localhost-only healthcheck).
                               Standard: default 0.0.0.0 (all interfaces, requires --token).
      --ca-cert PATH           Trust a self-signed CA for the Dockhand cert (edge mode)
      --tls-skip-verify        Insecure: skip TLS verification of Dockhand (test only, edge mode)
      --tls-cert PATH          TLS server certificate (standard mode)
      --tls-key PATH           TLS server key (standard mode)
      --skip-df                Set SKIP_DF_COLLECTION=1 (NAS with many mounts)
      --force-service-file     Recreate the service file even if it already exists.
      --binary-url URL         Use alternate binary download base URL.
  -h, --help                   Show this help message.
EOF
  exit 0
}

# ── Defaults ──
VERSION=""
USER_INSTALL=false
MODE="edge"
STACKS_DIR=""
DOCKHAND_SERVER_URL=""
TOKEN=""
AGENT_NAME="$(hostname)"
PORT="2376"
BIND_ADDRESS=""
CA_CERT=""
TLS_SKIP_VERIFY=false
TLS_CERT=""
TLS_KEY=""
SKIP_DF=false
FORCE_SERVICE=false
BINARY_URL="https://github.com/Finsys/hawser/releases/download"
DOCKER_SOCKET="/var/run/docker.sock"
INIT_SYSTEM=""

# ── Parse args ──
while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--version)         VERSION="$2";            shift 2 ;;
    -u|--user)            USER_INSTALL=true;       shift   ;;
    -m|--mode)            MODE="$2";               shift 2 ;;
    -s|--stacks-dir)      STACKS_DIR="$2";         shift 2 ;;
    -c|--dockhand-url)    DOCKHAND_SERVER_URL="$2"; shift 2 ;;
    -t|--token)           TOKEN="$2";              shift 2 ;;
    -n|--connect-as)      AGENT_NAME="$2";         shift 2 ;;
    --port)               PORT="$2";               shift 2 ;;
    --bind-address)       BIND_ADDRESS="$2";       shift 2 ;;
    --ca-cert)            CA_CERT="$2";            shift 2 ;;
    --tls-skip-verify)    TLS_SKIP_VERIFY=true;    shift   ;;
    --tls-cert)           TLS_CERT="$2";           shift 2 ;;
    --tls-key)            TLS_KEY="$2";            shift 2 ;;
    --skip-df)            SKIP_DF=true;            shift   ;;
    --force-service-file) FORCE_SERVICE=true;      shift   ;;
    --binary-url)         BINARY_URL="$2";         shift 2 ;;
    -h|--help)            usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

# ── Validate mode ──
case "$MODE" in
  edge|standard) ;;
  *) echo "Error: invalid mode '$MODE'. Use 'edge' or 'standard'."; exit 1 ;;
esac

if [[ "$MODE" == "edge" ]]; then
  if [[ -z "$DOCKHAND_SERVER_URL" ]]; then
    echo "Error: edge mode requires --dockhand-url (the Dockhand wss:// endpoint)."
    echo "  Example: $0 -c wss://dockhand.example.com/api/hawser/connect -t <token>"
    exit 1
  fi
  if [[ -z "$TOKEN" ]]; then
    echo "Error: edge mode requires --token."
    echo "  Generate it in Dockhand UI: Settings -> Environments -> Add Environment -> Hawser - Edge."
    echo "  Note: the token is shown only once."
    exit 1
  fi
elif [[ -z "$TOKEN" && -z "$BIND_ADDRESS" ]]; then
  echo "Error: standard mode binds 0.0.0.0 (all interfaces) and requires a TOKEN."
  echo "  Pass --token, or add --bind-address 127.0.0.1 for a local-only agent."
  exit 1
fi

# ── Fetch latest version if not specified ──
if [[ -z "$VERSION" ]]; then
  VERSION=$(curl -fsSL "https://api.github.com/repos/Finsys/hawser/releases/latest" \
    | sed -n 's/.*"tag_name": *"v\?\([^"]*\)".*/\1/p' | head -1)
  if [[ -z "$VERSION" ]]; then
    echo "Error: Failed to fetch latest version from GitHub API."
    echo "  Or specify version manually: $0 -v v0.1.0"
    exit 1
  fi
fi
VERSION_NUM="${VERSION#v}"

# ══════════════════════════════════════════════
# Init system detection
# ══════════════════════════════════════════════
detect_init_system() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    INIT_SYSTEM="launchd"
  elif command -v systemctl &>/dev/null && [[ -d /run/systemd/system ]]; then
    INIT_SYSTEM="systemd"
  elif [[ -d /etc/init.d ]] && command -v rc-service &>/dev/null; then
    INIT_SYSTEM="openrc"
  elif [[ -d /etc/runit ]] || command -v runsv &>/dev/null; then
    INIT_SYSTEM="runit"
  elif command -v update-rc.d &>/dev/null || command -v chkconfig &>/dev/null; then
    INIT_SYSTEM="sysvinit"
  else
    echo "Error: No supported init system detected."
    echo "Supported: systemd, openrc, sysvinit, runit, launchd"
    exit 1
  fi
}

# ══════════════════════════════════════════════
# Init system abstraction layer
# ══════════════════════════════════════════════

# --- systemd ---
init_systemd_stop() {
  local user_flag=""
  [[ "$USER_INSTALL" == true ]] && user_flag=" --user"
  systemctl${user_flag} stop hawser 2>/dev/null || true
}

init_systemd_write_service() {
  local service_file="$1"
  local home_dir="$2" bin_dir="$3" config_dir="$4" service_dir="$5"

  if [[ "$USER_INSTALL" == true ]]; then
    cat > "$service_file" <<SVCEOF
[Unit]
Description=Agent to connect with Dockhand

[Service]
Type=simple
Environment="HOME=${home_dir}"
EnvironmentFile=${config_dir}/config
ExecStart=${bin_dir}/hawser
Restart=always
RestartSec=10
TimeoutStartSec=0

[Install]
WantedBy=default.target
SVCEOF
  else
    cat > "$service_file" <<SVCEOF
[Unit]
Description=Hawser - Remote Docker Agent for Dockhand
Documentation=https://github.com/Finsys/hawser
After=network-online.target docker.service
Wants=network-online.target

[Service]
Type=simple
EnvironmentFile=${config_dir}/config
ExecStart=${bin_dir}/hawser
Restart=always
RestartSec=10
TimeoutStartSec=0

# Security hardening
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=${DOCKER_SOCKET} ${STACKS_DIR}

[Install]
WantedBy=multi-user.target
SVCEOF
  fi

  local user_flag=""
  [[ "$USER_INSTALL" == true ]] && user_flag=" --user"
  systemctl${user_flag} daemon-reload
}

init_systemd_start() {
  local user_flag=""
  [[ "$USER_INSTALL" == true ]] && user_flag=" --user"
  systemctl${user_flag} start hawser
}

init_systemd_enable() {
  local user_flag=""
  [[ "$USER_INSTALL" == true ]] && user_flag=" --user"
  systemctl${user_flag} enable hawser
}

init_systemd_service_path() {
  if [[ "$USER_INSTALL" == true ]]; then
    echo "$HOME/.config/systemd/user/hawser.service"
  else
    echo "/etc/systemd/system/hawser.service"
  fi
}

init_systemd_service_dir() {
  if [[ "$USER_INSTALL" == true ]]; then
    echo "$HOME/.config/systemd/user"
  else
    echo "/etc/systemd/system"
  fi
}

init_systemd_note() {
  local user_flag=""
  [[ "$USER_INSTALL" == true ]] && user_flag=" --user"
  echo "Note. Use \"systemctl${user_flag} status hawser\" to make sure Hawser is running"
  if [[ "$USER_INSTALL" == true ]]; then
    echo "Note. Use \"sudo loginctl enable-linger \$USER\" to make sure Hawser keeps running after user logs out"
  fi
}

# --- OpenRC ---
init_openrc_stop() {
  rc-service hawser stop 2>/dev/null || true
}

init_openrc_write_service() {
  local service_file="$1"
  local home_dir="$2" bin_dir="$3" config_dir="$4"

  # Wrapper that sources /etc/hawser/config (EnvironmentFile equivalent)
  cat > "${bin_dir}/hawser-wrapper" <<'WOEOF'
#!/bin/sh
# Wrapper for Hawser: loads config from /etc/hawser/config
CONFIG_FILE="${CONFIG_FILE:-/etc/hawser/config}"
if [ -f "$CONFIG_FILE" ]; then
    set -a
    . "$CONFIG_FILE"
    set +a
fi
exec "${BIN_DIR}/hawser" "$@"
WOEOF
  sed -i \
    -e "s|\${BIN_DIR}|${bin_dir}|g" \
    -e "s|\${CONFIG_FILE}|${config_dir}/config|g" \
    "${bin_dir}/hawser-wrapper"
  chmod +x "${bin_dir}/hawser-wrapper"

  cat > "$service_file" <<'OEOF'
#!/sbin/openrc-run

name="hawser"
description="Hawser - Remote Docker Agent for Dockhand"
command="${BIN_DIR}/hawser-wrapper"
command_background=true
pidfile="/run/${RC_SVCNAME}.pid"
output_log="/var/log/hawser.log"
error_log="/var/log/hawser.log"

depend() {
    need net docker
    after docker
}
OEOF

  sed -i \
    -e "s|\${BIN_DIR}|${bin_dir}|g" \
    "$service_file"

  chmod +x "$service_file"
}

init_openrc_start() {
  rc-service hawser start
}

init_openrc_enable() {
  rc-update add hawser default
}

init_openrc_service_path() {
  echo "/etc/init.d/hawser"
}

init_openrc_service_dir() {
  echo "/etc/init.d"
}

init_openrc_note() {
  echo "Note. Use \"rc-service hawser status\" to check if Hawser is running"
  echo "Note. Use \"rc-update add hawser default\" is already configured."
}

# --- sysvinit ---
init_sysvinit_stop() {
  /etc/init.d/hawser stop 2>/dev/null || true
}

init_sysvinit_write_service() {
  local service_file="$1"
  local home_dir="$2" bin_dir="$3" config_dir="$4"

  cat > "$service_file" <<'SEOF'
#!/bin/sh
### BEGIN INIT INFO
# Provides:          hawser
# Required-Start:    $remote_fs $syslog $network
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Hawser - Remote Docker Agent for Dockhand
### END INIT INFO

NAME="hawser"
DAEMON="${BIN_DIR}/hawser"
PIDFILE="/run/hawser.pid"
LOGFILE="/var/log/hawser.log"

# Load Hawser configuration (KEY=VALUE)
if [ -f "${CONFIG_DIR}/config" ]; then
    set -a
    . "${CONFIG_DIR}/config"
    set +a
fi

. /lib/lsb/init-functions

case "$1" in
  start)
    log_daemon_msg "Starting $NAME"
    start-stop-daemon --start --quiet --background \
      --make-pidfile --pidfile "$PIDFILE" \
      --exec "$DAEMON" \
      >> "$LOGFILE" 2>&1
    log_end_msg $?
    ;;
  stop)
    log_daemon_msg "Stopping $NAME"
    start-stop-daemon --stop --quiet --pidfile "$PIDFILE"
    log_end_msg $?
    ;;
  restart)
    $0 stop
    sleep 1
    $0 start
    ;;
  status)
    status_of_proc -p "$PIDFILE" "$DAEMON" "$NAME" && exit 0 || exit $?
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status}"
    exit 1
esac

exit 0
SEOF

  sed -i \
    -e "s|\${BIN_DIR}|${bin_dir}|g" \
    -e "s|\${CONFIG_DIR}|${config_dir}|g" \
    "$service_file"

  chmod +x "$service_file"
}

init_sysvinit_start() {
  /etc/init.d/hawser start
}

init_sysvinit_enable() {
  if command -v update-rc.d &>/dev/null; then
    update-rc.d hawser defaults
  elif command -v chkconfig &>/dev/null; then
    chkconfig hawser on
  fi
}

init_sysvinit_service_path() {
  echo "/etc/init.d/hawser"
}

init_sysvinit_service_dir() {
  echo "/etc/init.d"
}

init_sysvinit_note() {
  echo "Note. Use \"/etc/init.d/hawser status\" to check if Hawser is running"
  echo "Note. Use \"update-rc.d hawser defaults\" to enable on boot (already configured)."
}

# --- runit ---
init_runit_stop() {
  if [[ -d /etc/sv/hawser ]]; then
    runsvctl stop hawser 2>/dev/null || true
    if [[ -f "/run/runit/hawser/supervise/control/t" ]]; then
      kill -TERM "$(cat /run/runit/hawser/supervise/pid 2>/dev/null)" 2>/dev/null || true
    fi
  fi
}

init_runit_write_service() {
  local service_dir="$1"
  local home_dir="$2" bin_dir="$3" config_dir="$4"

  local sv_dir="${service_dir}/hawser"
  mkdir -p "${sv_dir}/log"

  cat > "${sv_dir}/run" <<REOF
#!/bin/sh
# Load Hawser configuration (KEY=VALUE)
if [ -f ${config_dir}/config ]; then
    set -a
    . ${config_dir}/config
    set +a
fi
exec ${bin_dir}/hawser
REOF
  chmod +x "${sv_dir}/run"

  cat > "${sv_dir}/log/run" <<'LREOF'
#!/bin/sh
exec svlogd -tt /var/log/runit/hawser/
LREOF
  chmod +x "${sv_dir}/log/run"
}

init_runit_start() {
  runsv /etc/sv/hawser &
  disown
}

init_runit_enable() {
  local svc_link="/var/service/hawser"
  local sv_dir="/etc/sv/hawser"
  if [[ ! -L "$svc_link" ]]; then
    ln -sf "$sv_dir" "$svc_link"
  fi
}

init_runit_service_path() {
  echo "/etc/sv/hawser/run"
}

init_runit_service_dir() {
  echo "/etc/sv"
}

init_runit_note() {
  echo "Note. Use \"sv status hawser\" to check if Hawser is running"
  echo "Note. Hawser is linked to /var/service/hawser and starts on boot automatically."
}

# --- launchd (macOS) ---
init_launchd_stop() {
  local plist="$1"
  if [[ -f "$plist" ]]; then
    launchctl unload "$plist" 2>/dev/null || true
  fi
}

init_launchd_write_service() {
  local service_file="$1"
  local home_dir="$2" bin_dir="$3" config_dir="$4" service_dir="$5"

  mkdir -p "$service_dir"

  # Wrapper that sources the config (plist has no EnvironmentFile equivalent)
  cat > "${bin_dir}/hawser-wrapper" <<'WOEOF'
#!/bin/sh
# Wrapper for Hawser: loads config
CONFIG_FILE="${CONFIG_FILE:-/etc/hawser/config}"
if [ -f "$CONFIG_FILE" ]; then
    set -a
    . "$CONFIG_FILE"
    set +a
fi
exec "${BIN_DIR}/hawser" "$@"
WOEOF
  sed -i \
    -e "s|\${BIN_DIR}|${bin_dir}|g" \
    -e "s|\${CONFIG_FILE}|${config_dir}/config|g" \
    "${bin_dir}/hawser-wrapper"
  chmod +x "${bin_dir}/hawser-wrapper"

  local label
  if [[ "$USER_INSTALL" == true ]]; then
    label="com.hawser.agent.user"
  else
    label="com.hawser.agent"
  fi

  local log_path="/var/log/hawser.log"
  [[ "$USER_INSTALL" == true ]] && log_path="$HOME/Library/Logs/hawser.log"

  cat > "$service_file" <<PLEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${label}</string>

    <key>ProgramArguments</key>
    <array>
        <string>${bin_dir}/hawser-wrapper</string>
    </array>

    <key>EnvironmentVariables</key>
    <dict>
        <key>HOME</key>
        <string>${home_dir}</string>
        <key>CONFIG_FILE</key>
        <string>${config_dir}/config</string>
    </dict>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>StandardOutPath</key>
    <string>${log_path}</string>

    <key>StandardErrorPath</key>
    <string>${log_path}</string>
</dict>
</plist>
PLEOF
}

init_launchd_start() {
  local plist="$1"
  launchctl load "$plist"
}

init_launchd_enable() {
  # launchd services are enabled by being in the right directory (RunAtLoad=true)
  return 0
}

init_launchd_service_path() {
  if [[ "$USER_INSTALL" == true ]]; then
    echo "$HOME/Library/LaunchAgents/com.hawser.agent.user.plist"
  else
    echo "/Library/LaunchDaemons/com.hawser.agent.plist"
  fi
}

init_launchd_service_dir() {
  if [[ "$USER_INSTALL" == true ]]; then
    echo "$HOME/Library/LaunchAgents"
  else
    echo "/Library/LaunchDaemons"
  fi
}

init_launchd_note() {
  echo "Note. Use \"launchctl list com.hawser.agent\" to check if Hawser is running"
  echo "Note. Use \"launchctl unload <plist>\" to stop / \"launchctl load <plist>\" to start"
}
svc_stop()        { init_${INIT_SYSTEM}_stop "$(svc_service_path)"; }
svc_write()       { init_${INIT_SYSTEM}_write_service "$@"; }
svc_start()       { init_${INIT_SYSTEM}_start "$(svc_service_path)"; }
svc_enable()      { init_${INIT_SYSTEM}_enable "$(svc_service_path)"; }
svc_service_path(){ init_${INIT_SYSTEM}_service_path "$@"; }
svc_service_dir() { init_${INIT_SYSTEM}_service_dir "$@"; }
svc_note()        { init_${INIT_SYSTEM}_note "$@"; }

# ══════════════════════════════════════════════
# Main
# ══════════════════════════════════════════════

# ── Detect init system ──
detect_init_system

# ── Validate user install support ──
if [[ "$USER_INSTALL" == true && "$INIT_SYSTEM" != "systemd" && "$INIT_SYSTEM" != "launchd" ]]; then
  echo "Warning: --user is only supported with systemd and launchd. Ignoring --user flag."
  USER_INSTALL=false
fi

# ── Root check (system installs only) ──
if [[ "$USER_INSTALL" != true && "$(id -u)" -ne 0 ]]; then
  echo "Error: system-wide install requires root. Re-run as root or use 'sudo $0 ...'."
  echo "  For a per-user install: $0 --user ..."
  exit 1
fi

# ── Load paths ──
HOME_DIR="$HOME"
SERVICE_DIR_PATH=$(svc_service_path)
SERVICE_DIR=$(svc_service_dir)

if [[ "$USER_INSTALL" == true ]]; then
  BIN_DIR="$HOME/.local/bin"
  if [[ "$INIT_SYSTEM" == "launchd" ]]; then
    CONFIG_DIR="$HOME/Library/Application Support/hawser"
  else
    CONFIG_DIR="$HOME/.config/hawser"
  fi
  STACKS_DIR="${STACKS_DIR:-$HOME/hawser-stacks}"
else
  BIN_DIR="/usr/local/bin"
  CONFIG_DIR="/etc/hawser"
  STACKS_DIR="${STACKS_DIR:-/data/stacks}"
fi
CONFIG_FILE="${CONFIG_DIR}/config"

# ── Print info ──
echo "====================="
echo "  HAWSER INSTALLER   "
echo "====================="
echo "init system: $INIT_SYSTEM"
echo "mode: $MODE"
echo "version: $VERSION"
echo "dockhand url: ${DOCKHAND_SERVER_URL:-(standard mode)}"
echo "connect as: $AGENT_NAME"
echo "user install: $USER_INSTALL"
echo "home dir: $HOME_DIR"
echo "bin dir: $BIN_DIR"
echo "config dir: $CONFIG_DIR"
echo "stacks dir: $STACKS_DIR"
echo "service dir: $SERVICE_DIR"

# ── Download binary ──
svc_stop

mkdir -p "$BIN_DIR"

BIN_PATH="$BIN_DIR/hawser"
[[ -f "$BIN_PATH" ]] && rm -f "$BIN_PATH"

# Detect OS and architecture (same mapping as official install.sh)
ARCH="$(uname -m | tr '[:upper:]' '[:lower:]')"
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"

case "$ARCH" in
  x86_64)            ARCH="amd64" ;;
  aarch64|arm64)     ARCH="arm64" ;;
  armv7l|armv7|arm)  ARCH="arm" ;;
  *) echo "Error: Unsupported architecture: $ARCH"; exit 1 ;;
esac

DOWNLOAD_URL="${BINARY_URL}/v${VERSION_NUM}/hawser_${VERSION_NUM}_${OS}_${ARCH}.tar.gz"
echo "Downloading ${DOWNLOAD_URL} ..."
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

if ! curl -fsSL "$DOWNLOAD_URL" -o "$TMP_DIR/hawser.tar.gz"; then
  echo "Failed to download binary from ${DOWNLOAD_URL}"
  echo ""
  echo "Did you provide a valid tag for '--version'? Check here for valid version tags:"
  echo "https://github.com/Finsys/hawser/tags"
  exit 1
fi
tar -xzf "$TMP_DIR/hawser.tar.gz" -C "$TMP_DIR"
install -m 755 "$TMP_DIR/hawser" "$BIN_PATH"

# ── Write config ──
if [[ -f "$CONFIG_FILE" ]]; then
  echo "Config at ${CONFIG_FILE} already exists, skipping..."
else
  echo "Creating config at ${CONFIG_FILE}"
  mkdir -p "$CONFIG_DIR" "$STACKS_DIR"
  chmod 700 "$CONFIG_DIR"

  if [[ "$MODE" == "edge" ]]; then
    cat > "$CONFIG_FILE" <<EOF
# Hawser Configuration
# See https://github.com/Finsys/hawser
#
# Mode: edge - the agent initiates an outbound WebSocket connection to Dockhand.
# Works behind NAT / firewalls / dynamic IP. No inbound ports are required.

# Docker socket path
DOCKER_SOCKET=${DOCKER_SOCKET}

# Stacks directory (host path). For compose stacks with relative bind mounts
# (e.g. ./data:/app/data) the path inside the container must match the host path.
STACKS_DIR=${STACKS_DIR}

################# Edge Mode #################
DOCKHAND_SERVER_URL=${DOCKHAND_SERVER_URL}
TOKEN=${TOKEN}

# Agent name shown in Dockhand UI (optional)
AGENT_NAME=${AGENT_NAME}

# Edge mode only needs port 2376 open for Docker's HEALTHCHECK directive.
# Restrict it to localhost so the host has no externally-reachable surface:
BIND_ADDRESS=${BIND_ADDRESS:-127.0.0.1}
EOF
    # Optional Edge-mode TLS settings
    if [[ -n "$CA_CERT" ]]; then
      echo "" >> "$CONFIG_FILE"
      echo "# Trust a self-signed CA for the Dockhand certificate" >> "$CONFIG_FILE"
      echo "CA_CERT=${CA_CERT}" >> "$CONFIG_FILE"
    fi
    if [[ "$TLS_SKIP_VERIFY" == true ]]; then
      echo "" >> "$CONFIG_FILE"
      echo "# WARNING: test-only, vulnerable to MITM" >> "$CONFIG_FILE"
      echo "TLS_SKIP_VERIFY=true" >> "$CONFIG_FILE"
    fi
  else
    cat > "$CONFIG_FILE" <<EOF
# Hawser Configuration
# See https://github.com/Finsys/hawser
#
# Mode: standard - the agent listens for inbound connections (LAN / static IP).

# Docker socket path
DOCKER_SOCKET=${DOCKER_SOCKET}

# Stacks directory (host path)
STACKS_DIR=${STACKS_DIR}

################# Standard Mode #################
PORT=${PORT}
TOKEN=${TOKEN}

# Local-only agent: set BIND_ADDRESS=127.0.0.1 (then TOKEN may be left unset)
BIND_ADDRESS=${BIND_ADDRESS:-0.0.0.0}
EOF
    # Optional Standard-mode TLS settings
    if [[ -n "$TLS_CERT" || -n "$TLS_KEY" ]]; then
      echo "" >> "$CONFIG_FILE"
      echo "# TLS configuration (Standard mode only)" >> "$CONFIG_FILE"
      [[ -n "$TLS_CERT" ]] && echo "TLS_CERT=${TLS_CERT}" >> "$CONFIG_FILE"
      [[ -n "$TLS_KEY" ]]  && echo "TLS_KEY=${TLS_KEY}"  >> "$CONFIG_FILE"
    fi
  fi

  if [[ "$SKIP_DF" == true ]]; then
    echo "" >> "$CONFIG_FILE"
    echo "# Skip filesystem collection (NAS with many mounts)" >> "$CONFIG_FILE"
    echo "SKIP_DF_COLLECTION=1" >> "$CONFIG_FILE"
  fi

  # The config can hold a TOKEN, so it must not be world-readable.
  chmod 600 "$CONFIG_FILE"
fi

# ── Write service file ──
if [[ "$FORCE_SERVICE" == true ]]; then
  echo "forcing service file recreation"
  if [[ -f "$SERVICE_DIR_PATH" ]]; then
    echo "deleting existing service file"
    rm -f "$SERVICE_DIR_PATH"
  fi
fi

if [[ -f "$SERVICE_DIR_PATH" ]]; then
  echo "service file already exists at ${SERVICE_DIR_PATH}, skipping..."
else
  echo "creating service file at ${SERVICE_DIR_PATH}"
  mkdir -p "$SERVICE_DIR"

  svc_write "$SERVICE_DIR_PATH" "$HOME_DIR" "$BIN_DIR" "$CONFIG_DIR" "$SERVICE_DIR"
fi

# ── Start & enable hawser ──
echo "Starting Hawser..."
svc_start

echo "Enabling Hawser on boot..."
svc_enable

echo ""
echo "Finished Hawser setup."
echo ""
svc_note

# ── Mode-specific verification hint ──
echo ""
if [[ "$MODE" == "edge" ]]; then
  echo "Verify the agent is connected to Dockhand:"
  echo "  curl http://127.0.0.1:2376/_hawser/health"
  echo "  # expected: {\"status\":\"healthy\",\"mode\":\"edge\",\"connected\":true}"
  echo ""
  echo "The environment should show as online in Dockhand UI"
  echo "(Settings -> Environments). No inbound ports are required on this host."
else
  echo "Standard mode. Point Dockhand at this host:"
  echo "  Settings -> Environments -> Add Environment -> Hawser"
  echo "  host: <this-host-ip>, port: ${PORT}, token: ${TOKEN}"
fi
