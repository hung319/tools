#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────
# Komodo Periphery Installer (shell version)
# Supports: systemd, OpenRC, sysvinit, runit
# ──────────────────────────────────────────────

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Install init-system-managed Komodo Periphery.

Options:
  -v, --version VERSION        Install a specific Komodo version, like 'v2.0.0'
  -u, --user                   Install systemd '--user' service (systemd only)
  -r, --root-directory DIR     Specify a Periphery root directory (default: /etc/komodo)
  -c, --core-address ADDR      Komodo Core address for outbound connection.
                               Leave blank to enable inbound connection server.
  -n, --connect-as NAME        Server name to connect as (default: hostname)
  -k, --onboarding-key KEY     Onboarding key for automatic Server onboarding into Komodo Core.
  --force-service-file         Recreate the service file even if it already exists.
  --config-url URL             Use a custom config URL.
  --binary-url URL             Use alternate binary source.
  -h, --help                   Show this help message.
EOF
  exit 0
}

# ── Defaults ──
VERSION=""
USER_INSTALL=false
ROOT_DIR="/etc/komodo"
CORE_ADDRESS=""
CONNECT_AS="$(hostname)"
ONBOARDING_KEY=""
FORCE_SERVICE=false
CONFIG_URL="https://raw.githubusercontent.com/moghtech/komodo/refs/heads/main/config/periphery.config.toml"
BINARY_URL="https://github.com/moghtech/komodo/releases/download"
INIT_SYSTEM=""

# ── Parse args ──
while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--version)         VERSION="$2";         shift 2 ;;
    -u|--user)            USER_INSTALL=true;    shift   ;;
    -r|--root-directory)  ROOT_DIR="$2";        shift 2 ;;
    -c|--core-address)    CORE_ADDRESS="$2";    shift 2 ;;
    -n|--connect-as)      CONNECT_AS="$2";      shift 2 ;;
    -k|--onboarding-key)  ONBOARDING_KEY="$2";  shift 2 ;;
    --force-service-file) FORCE_SERVICE=true;   shift   ;;
    --config-url)         CONFIG_URL="$2";      shift 2 ;;
    --binary-url)         BINARY_URL="$2";      shift 2 ;;
    -h|--help)            usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

# ── Fetch latest version if not specified ──
if [[ -z "$VERSION" ]]; then
  # Use ?per_page=1 instead of /latest to avoid 302 redirect being cached by proxies
  github_api_url="https://api.github.com/repos/moghtech/komodo/releases?per_page=1"
  curl_opts=(-fsSL)

  # Use GH_TOKEN for authenticated requests (rate limit: 5000 vs 60 req/hour)
  if [[ -n "${GH_TOKEN:-}" ]]; then
    curl_opts+=(-H "Authorization: Bearer ${GH_TOKEN}")
  fi

  VERSION=$(curl "${curl_opts[@]}" "$github_api_url" \
    | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)

  if [[ -z "$VERSION" ]]; then
    echo "Error: Failed to fetch latest version from GitHub API."
    if [[ -z "${GH_TOKEN:-}" ]]; then
      echo "  Tip: Set GH_TOKEN for higher API rate limit (5000 req/hour):"
      echo "    export GH_TOKEN=ghp_..."
    fi
    echo "  Or specify version manually: $0 -v v2.3.1"
    exit 1
  fi
fi

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
  systemctl${user_flag} stop periphery 2>/dev/null || true
}

init_systemd_write_service() {
  local service_file="$1"
  local home_dir="$2" bin_dir="$3" config_dir="$4" service_dir="$5"

  cat > "$service_file" <<SVCEOF
[Unit]
Description=Agent to connect with Komodo Core

[Service]
Environment="HOME=${home_dir}"
ExecStart=/bin/sh -lc "${bin_dir}/periphery --config-path ${config_dir}/periphery.config.toml"
Restart=on-failure
TimeoutStartSec=0

[Install]
WantedBy=default.target
SVCEOF

  local user_flag=""
  [[ "$USER_INSTALL" == true ]] && user_flag=" --user"
  systemctl${user_flag} daemon-reload
}

init_systemd_start() {
  local user_flag=""
  [[ "$USER_INSTALL" == true ]] && user_flag=" --user"
  systemctl${user_flag} start periphery
}

init_systemd_enable() {
  local user_flag=""
  [[ "$USER_INSTALL" == true ]] && user_flag=" --user"
  systemctl${user_flag} enable periphery
}

init_systemd_service_path() {
  if [[ "$USER_INSTALL" == true ]]; then
    echo "$HOME/.config/systemd/user/periphery.service"
  else
    echo "/etc/systemd/system/periphery.service"
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
  echo "Note. Use \"systemctl${user_flag} status periphery\" to make sure Periphery is running"
  if [[ "$USER_INSTALL" == true ]]; then
    echo "Note. Use \"sudo loginctl enable-linger \$USER\" to make sure Periphery keeps running after user logs out"
  fi
}

# --- OpenRC ---
init_openrc_stop() {
  rc-service periphery stop 2>/dev/null || true
}

init_openrc_write_service() {
  local service_file="$1"
  local home_dir="$2" bin_dir="$3" config_dir="$4"

  cat > "$service_file" <<'OEOF'
#!/sbin/openrc-run

name="periphery"
description="Agent to connect with Komodo Core"

command="${BIN_DIR}/periphery"
command_args="--config-path ${CONFIG_DIR}/periphery.config.toml"
command_background=true
pidfile="/run/periphery.pid"
output_log="/var/log/periphery.log"
error_log="/var/log/periphery.log"

depend() {
    need net
    after firewall
}

start_pre() {
    export HOME="${HOME_DIR}"
}
OEOF

  # Substitute variables into the OpenRC script
  sed -i \
    -e "s|\${BIN_DIR}|${bin_dir}|g" \
    -e "s|\${CONFIG_DIR}|${config_dir}|g" \
    -e "s|\${HOME_DIR}|${home_dir}|g" \
    "$service_file"

  chmod +x "$service_file"
}

init_openrc_start() {
  rc-service periphery start
}

init_openrc_enable() {
  rc-update add periphery default
}

init_openrc_service_path() {
  echo "/etc/init.d/periphery"
}

init_openrc_service_dir() {
  echo "/etc/init.d"
}

init_openrc_note() {
  echo "Note. Use \"rc-service periphery status\" to check if Periphery is running"
  echo "Note. Use \"rc-update add periphery default\" is already configured."
}

# --- sysvinit ---
init_sysvinit_stop() {
  /etc/init.d/periphery stop 2>/dev/null || true
}

init_sysvinit_write_service() {
  local service_file="$1"
  local home_dir="$2" bin_dir="$3" config_dir="$4"

  cat > "$service_file" <<'SEOF'
#!/bin/sh
### BEGIN INIT INFO
# Provides:          periphery
# Required-Start:    $remote_fs $syslog $network
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Agent to connect with Komodo Core
### END INIT INFO

NAME="periphery"
DAEMON="${BIN_DIR}/periphery"
DAEMON_ARGS="--config-path ${CONFIG_DIR}/periphery.config.toml"
PIDFILE="/run/periphery.pid"
LOGFILE="/var/log/periphery.log"
export HOME="${HOME_DIR}"

. /lib/lsb/init-functions

case "$1" in
  start)
    log_daemon_msg "Starting $NAME"
    start-stop-daemon --start --quiet --background \
      --make-pidfile --pidfile "$PIDFILE" \
      --exec "$DAEMON" -- $DAEMON_ARGS \
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

  # Substitute variables
  sed -i \
    -e "s|\${BIN_DIR}|${bin_dir}|g" \
    -e "s|\${CONFIG_DIR}|${config_dir}|g" \
    -e "s|\${HOME_DIR}|${home_dir}|g" \
    "$service_file"

  chmod +x "$service_file"
}

init_sysvinit_start() {
  /etc/init.d/periphery start
}

init_sysvinit_enable() {
  if command -v update-rc.d &>/dev/null; then
    update-rc.d periphery defaults
  elif command -v chkconfig &>/dev/null; then
    chkconfig periphery on
  fi
}

init_sysvinit_service_path() {
  echo "/etc/init.d/periphery"
}

init_sysvinit_service_dir() {
  echo "/etc/init.d"
}

init_sysvinit_note() {
  echo "Note. Use \"/etc/init.d/periphery status\" to check if Periphery is running"
  echo "Note. Use \"update-rc.d periphery defaults\" to enable on boot (already configured)."
}

# --- runit ---
init_runit_stop() {
  if [[ -d /etc/sv/periphery ]]; then
    runsvctl stop periphery 2>/dev/null || true
    # Fallback: send TERM to the runsv process
    if [[ -f "/run/runit/periphery/supervise/control/t" ]]; then
      kill -TERM "$(cat /run/runit/periphery/supervise/pid 2>/dev/null)" 2>/dev/null || true
    fi
  fi
}

init_runit_write_service() {
  local service_dir="$1"
  local home_dir="$2" bin_dir="$3" config_dir="$4"

  local sv_dir="${service_dir}/periphery"
  mkdir -p "${sv_dir}/log"

  cat > "${sv_dir}/run" <<REOF
#!/bin/sh
export HOME="${home_dir}"
exec chpst -u nobody \
  ${bin_dir}/periphery \
  --config-path ${config_dir}/periphery.config.toml
REOF
  chmod +x "${sv_dir}/run"

  cat > "${sv_dir}/log/run" <<'LREOF'
#!/bin/sh
exec svlogd -tt /var/log/runit/periphery/
LREOF
  chmod +x "${sv_dir}/log/run"
}

init_runit_start() {
  runsv /etc/sv/periphery &
  disown
}

init_runit_enable() {
  # runit: symlink to /var/service (or /run/runit/service)
  local svc_link="/var/service/periphery"
  local sv_dir="/etc/sv/periphery"
  if [[ ! -L "$svc_link" ]]; then
    ln -sf "$sv_dir" "$svc_link"
  fi
}

init_runit_service_path() {
  echo "/etc/sv/periphery/run"
}

init_runit_service_dir() {
  echo "/etc/sv"
}

init_runit_note() {
  echo "Note. Use \"sv status periphery\" to check if Periphery is running"
  echo "Note. Periphery is linked to /var/service/periphery and starts on boot automatically."
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

  cat > "$service_file" <<PLEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.komodo.periphery</string>

    <key>ProgramArguments</key>
    <array>
        <string>${bin_dir}/periphery</string>
        <string>--config-path</string>
        <string>${config_dir}/periphery.config.toml</string>
    </array>

    <key>EnvironmentVariables</key>
    <dict>
        <key>HOME</key>
        <string>${home_dir}</string>
    </dict>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>StandardOutPath</key>
    <string>/var/log/periphery.log</string>

    <key>StandardErrorPath</key>
    <string>/var/log/periphery.log</string>
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
    echo "$HOME/Library/LaunchAgents/com.komodo.periphery.plist"
  else
    echo "/Library/LaunchDaemons/com.komodo.periphery.plist"
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
  echo "Note. Use \"launchctl list com.komodo.periphery\" to check if Periphery is running"
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

# ── Load paths ──
HOME_DIR="$HOME"
SERVICE_DIR_PATH=$(svc_service_path)
SERVICE_DIR=$(svc_service_dir)

if [[ "$USER_INSTALL" == true ]]; then
  BIN_DIR="$HOME/.local/bin"
  if [[ "$INIT_SYSTEM" == "launchd" ]]; then
    CONFIG_DIR="$HOME/Library/Application Support/komodo"
  else
    CONFIG_DIR="$HOME/.config/komodo"
  fi
else
  BIN_DIR="/usr/local/bin"
  CONFIG_DIR="/etc/komodo"
fi

# ── Print info ──
echo "====================="
echo " PERIPHERY INSTALLER "
echo "====================="
echo "init system: $INIT_SYSTEM"
echo "version: $VERSION"
echo "core address: ${CORE_ADDRESS:-(inbound)}"
echo "connect as: $CONNECT_AS"
echo "user install: $USER_INSTALL"
echo "home dir: $HOME_DIR"
echo "bin dir: $BIN_DIR"
echo "config dir: $CONFIG_DIR"
echo "service dir: $SERVICE_DIR"

# ── Download binary ──
svc_stop

mkdir -p "$BIN_DIR"

BIN_PATH="$BIN_DIR/periphery"
[[ -f "$BIN_PATH" ]] && rm -f "$BIN_PATH"

# Detect OS and architecture
ARCH="$(uname -m | tr '[:upper:]' '[:lower:]')"
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"

if [[ "$OS" == "darwin" ]]; then
  echo "apple/macOS detected"
  PERIPHERY_BIN="periphery-apple"
elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
  echo "aarch64 detected"
  PERIPHERY_BIN="periphery-aarch64"
else
  echo "using x86_64 binary"
  PERIPHERY_BIN="periphery-x86_64"
fi

echo "Downloading ${BINARY_URL}/${VERSION}/${PERIPHERY_BIN} ..."
if ! curl -fsSL "${BINARY_URL}/${VERSION}/${PERIPHERY_BIN}" -o "$BIN_PATH"; then
  echo "Failed to download binary from ${BINARY_URL}/${VERSION}/${PERIPHERY_BIN}"
  echo ""
  echo "Did you provide a valid tag for '--version'? Check here for valid version tags:"
  echo "https://github.com/moghtech/komodo/tags"
  exit 1
fi

chmod +x "$BIN_PATH"

# ── Write config ──
CONFIG_FILE="${CONFIG_DIR}/periphery.config.toml"

if [[ -f "$CONFIG_FILE" ]]; then
  echo "Config at ${CONFIG_FILE} already exists, skipping..."
else
  echo "creating config at ${CONFIG_FILE}"
  mkdir -p "$CONFIG_DIR"

  # Download template
  CONFIG_TEMPLATE=$(curl -fsSL "$CONFIG_URL")

  # Apply mappings via sed
  OUTPUT="$CONFIG_TEMPLATE"

  # root_directory
  if [[ -n "$ROOT_DIR" ]]; then
    OUTPUT=$(echo "$OUTPUT" | sed "s|^root_directory = .*|root_directory = \"${ROOT_DIR}\"|")
  elif [[ "$USER_INSTALL" == true ]]; then
    OUTPUT=$(echo "$OUTPUT" | sed "s|^root_directory = .*|root_directory = \"${HOME_DIR}/komodo\"|")
  fi

  # core_address (uncomment + set)
  if [[ -n "$CORE_ADDRESS" ]]; then
    OUTPUT=$(echo "$OUTPUT" | sed "s|^# core_address = .*|core_address = \"${CORE_ADDRESS}\"|")
  fi

  # connect_as (uncomment + set)
  if [[ -n "$CONNECT_AS" ]]; then
    OUTPUT=$(echo "$OUTPUT" | sed "s|^# connect_as = .*|connect_as = \"${CONNECT_AS}\"|")
  fi

  # onboarding_key (uncomment + set)
  if [[ -n "$ONBOARDING_KEY" ]]; then
    OUTPUT=$(echo "$OUTPUT" | sed "s|^# onboarding_key = .*|onboarding_key = \"${ONBOARDING_KEY}\"|")
  fi

  echo "$OUTPUT" > "$CONFIG_FILE"
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

# ── Start & enable periphery ──
echo "Starting Periphery..."
svc_start

echo "Enabling Periphery on boot..."
svc_enable

echo ""
echo "Finished Periphery setup."
echo ""
svc_note
