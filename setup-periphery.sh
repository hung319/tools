#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────
# Komodo Periphery Installer (shell version)
# Supports: systemd, OpenRC, sysvinit, runit, launchd
#
# Patched extras:
#   --core-public-keys KEY  Pin the Core public key explicitly in the config
#                           (upstream PR #1524). If the config already exists,
#                           the line is updated in place, and the stale TOFU
#                           pin (keys/core.pub) is cleared so the new pin takes
#                           effect — fixes handshake failures ("Periphery
#                           failed to validate Core public key") without
#                           wiping the install.
#   --clean                 Remove the old install (service, binary, config,
#                           keys/ dir) BEFORE installing fresh. Selective:
#                           never touches stacks/repos/builds.
#   --uninstall             Same removal as --clean, then exit (no reinstall).
#
#   Download resilience:
#     - Every fetch (version, binary, config) is proxy-first: the first
#       reachable proxy in the list is used; if it fails, the same fetch
#       falls back to direct GitHub automatically. No mode flags.
#     - Binary download uses HTTP/1.1 + partial-download resume (-C -) with
#       --retry-all-errors, so a dropped HTTP/2 stream over flaky transit
#       (curl exit 92) retries and resumes instead of hanging/restarting.
#     - With multiple proxies listed they are speed-ranked by a 2MB ranged
#       probe of the real binary (skipped for a single proxy).
#     - Every binary download is integrity-gated: the result must be a valid
#       ELF/Mach-O executable of plausible size, rejecting mirrors that
#       return HTTP 200 with a challenge/suspension page instead of the file.
#     - The config template falls back to the jsDelivr CDN, then direct
#       raw.githubusercontent.com, if the primary route fails (repo files
#       <20MB, no prefix required).
#
# GitHub access routing (works in China AND internationally):
#   Proxy-first with direct fallback: probe the proxy list at install time,
#   use the first reachable proxy for every fetch; if a fetch fails through
#   it (dead proxy, stalled stream, bad content), fall back to direct
#   GitHub. --config-url/--binary-url still override the resolved route.
#
#   Version detection no longer uses api.github.com (most proxies refuse to
#   relay it): it follows the releases/latest redirect, which works both
#   direct and through proxies.
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
  --core-public-keys KEY       Core public key(s) to pin, comma separated
                               (SPKI base64 DER, PEM, or file:/path/to/key.pub).
                               Updates in place if the config already exists;
                               also clears the stale TOFU pin (keys/core.pub).
  --clean                      Remove old install (service, binary, config, keys/)
                               before installing fresh.
  --uninstall                  Remove old install and exit (no reinstall).
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
CORE_PUBLIC_KEYS=""
CLEAN=false
UNINSTALL=false
FORCE_SERVICE=false
CONFIG_URL="https://raw.githubusercontent.com/moghtech/komodo/refs/heads/main/config/periphery.config.toml"
BINARY_URL="https://github.com/moghtech/komodo/releases/download"
INIT_SYSTEM=""

# ── GitHub access routing ──
CONFIG_URL_SET=false
BINARY_URL_SET=false
PROXY_BASE=""
ORIG_BINARY_URL=""
ORIG_CONFIG_URL=""
REACHABLE_PROXIES=()   # every proxy that passed the reachability probe
# Proxy in use (2026-08): gh.bibica.net — Cloudflare Pages reverse proxy for
# GitHub. Path-based, NOT prefix-based like the older mirrors:
#   github.com/…                          → https://gh.bibica.net/…
#   raw.githubusercontent.com/…           → https://gh.bibica.net/_raw/…
#   api.github.com/…                      → https://gh.bibica.net/_api/…
#   release-assets.githubusercontent.com/… → https://gh.bibica.net/_release-assets/…
#   codeload.github.com/…                 → https://gh.bibica.net/_codeload/…
# (how it's built: https://bibica.net/su-dung-cloudflare-pages-lam-reverse-proxy-cho-github-v2/)
# Cloudflare edge → fast/stable from China. Verified byte-identical to direct
# GitHub (sha256 match) for release binaries, HTTP Range supported (resume).
# If it ever dies, add a backup mirror here (trailing-slash bases are treated
# as prefix proxies, slash-less bases as path-based) or pass --binary-url.
PROXY_LIST=(
  "https://gh.bibica.net"
)
# Small, version-independent canary used to probe reachability
RAW_CANARY="https://raw.githubusercontent.com/moghtech/komodo/refs/heads/main/config/periphery.config.toml"

# ── Parse args ──
while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--version)         VERSION="$2";         shift 2 ;;
    -u|--user)            USER_INSTALL=true;    shift   ;;
    -r|--root-directory)  ROOT_DIR="$2";        shift 2 ;;
    -c|--core-address)    CORE_ADDRESS="$2";    shift 2 ;;
    -n|--connect-as)      CONNECT_AS="$2";      shift 2 ;;
    -k|--onboarding-key)  ONBOARDING_KEY="$2";  shift 2 ;;
    --core-public-keys)   CORE_PUBLIC_KEYS="$2"; shift 2 ;;
    --clean)              CLEAN=true;           shift   ;;
    --uninstall)          UNINSTALL=true;       shift   ;;
    --force-service-file) FORCE_SERVICE=true;   shift   ;;
    --config-url)         CONFIG_URL="$2"; CONFIG_URL_SET=true; shift 2 ;;
    --binary-url)         BINARY_URL="$2"; BINARY_URL_SET=true; shift 2 ;;
    -h|--help)            usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

# ══════════════════════════════════════════════
# GitHub access routing (direct vs proxy)
# ══════════════════════════════════════════════
probe_ok() { # $1=url $2=max-time(s)
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 --max-time "${2:-8}" "$1" 2>/dev/null) || return 1
  [[ "$code" =~ ^[23] ]]
}

# Rewrite a GitHub URL through a proxy. Prefix proxies (trailing slash, e.g.
# https://gh-proxy.com/) take the URL appended as-is; path-based proxies
# (slash-less, e.g. https://gh.bibica.net) map each GitHub host to a path.
rewrite_github_url() { # $1 = GitHub URL, $2 = proxy base (defaults to PROXY_BASE)
  local url="$1" base="${2:-$PROXY_BASE}"
  [[ -z "$base" ]] && { echo "$url"; return 0; }
  case "$base" in
    */) echo "${base}${url}" ;;  # prefix-style proxy
    *)  case "$url" in
          https://raw.githubusercontent.com/*)
            echo "${base}/_raw/${url#https://raw.githubusercontent.com/}" ;;
          https://api.github.com/*)
            echo "${base}/_api/${url#https://api.github.com/}" ;;
          https://github.com/*)
            echo "${base}/${url#https://github.com/}" ;;
          *) echo "${base}/${url#https://}" ;;
        esac ;;
  esac
}

choose_proxy() {
  local p
  for p in "${PROXY_LIST[@]}"; do
    if probe_ok "$(rewrite_github_url "$RAW_CANARY" "$p")" 8; then
      REACHABLE_PROXIES+=("$p")
      if [[ -z "$PROXY_BASE" ]]; then
        PROXY_BASE="$p"
        echo "→ using GitHub proxy: $p"
      fi
    else
      echo "→ proxy unreachable: $p"
    fi
  done
  [[ -n "$PROXY_BASE" ]]
}

select_github_route() {
  # Proxy-first: use the first reachable proxy as the primary route; every
  # fetch (version, binary, config) falls back to direct GitHub automatically
  # if the proxy fails. Proxies that don't answer the canary are skipped.
  choose_proxy || {
    echo "→ no GitHub proxy reachable — falling back to direct GitHub"
  }

  # Keep the un-rewritten bases so the download/config steps can build
  # fallback candidates (other proxies / direct) if the chosen route fails.
  ORIG_BINARY_URL="$BINARY_URL"
  ORIG_CONFIG_URL="$CONFIG_URL"

  # Rewrite the download targets to go through the proxy (unless overridden)
  if [[ -n "$PROXY_BASE" ]]; then
    [[ "$CONFIG_URL_SET" == false ]] && CONFIG_URL="$(rewrite_github_url "$CONFIG_URL")"
    [[ "$BINARY_URL_SET" == false ]] && BINARY_URL="$(rewrite_github_url "$BINARY_URL")"
  fi
}

# ── Pick route (probe + rewrite CONFIG_URL/BINARY_URL) ──
select_github_route

# ── Fetch latest version if not specified ──
if [[ -z "$VERSION" ]]; then
  # Follows the releases/latest redirect (302 → Location .../releases/tag/vX.Y.Z).
  # Works direct AND through proxies (api.github.com is not proxied by most mirrors).
  fetch_latest_version() { # $1 = releases/latest URL
    curl -sI --connect-timeout 4 --max-time 8 "$1" 2>/dev/null \
      | sed -n 's|.*releases/tag/\(v[^/" ]*\).*|\1|p' \
      | tr -d '\r' | head -1   # HTTP headers are CRLF — strip the trailing \r
  }

  if [[ -n "$PROXY_BASE" ]]; then
    VERSION=$(fetch_latest_version "$(rewrite_github_url "https://github.com/moghtech/komodo/releases/latest" "$PROXY_BASE")") || true
  fi
  if [[ -z "$VERSION" ]]; then
    VERSION=$(fetch_latest_version "https://github.com/moghtech/komodo/releases/latest") || true
  fi
  if [[ -z "$VERSION" ]]; then
    echo "Error: Failed to detect latest version (GitHub unreachable)."
    echo "  Or specify version manually: $0 -v v2.3.1"
    exit 1
  fi
  echo "latest version: $VERSION"
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

init_systemd_disable() {
  local user_flag=""
  [[ "$USER_INSTALL" == true ]] && user_flag=" --user"
  systemctl${user_flag} disable periphery 2>/dev/null || true
}

init_systemd_write_service() {
  local service_file="$1"
  local home_dir="$2" bin_dir="$3" config_dir="$4" service_dir="$5"

  cat > "$service_file" <<SVCEOF
[Unit]
Description=Agent to connect with Komodo Core

[Service]
Environment="HOME=${home_dir}"
ExecStart=/bin/sh -lc "\"${bin_dir}/periphery\" --config-path \"${config_dir}/periphery.config.toml\""
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

init_openrc_disable() {
  rc-update del periphery 2>/dev/null || true
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

init_sysvinit_disable() {
  if command -v update-rc.d &>/dev/null; then
    update-rc.d -f periphery remove 2>/dev/null || true
  elif command -v chkconfig &>/dev/null; then
    chkconfig --del periphery 2>/dev/null || true
  fi
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

init_runit_disable() {
  # runit: remove the service symlink
  local svc_link="/var/service/periphery"
  [[ -L "$svc_link" ]] && rm -f "$svc_link"
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

init_launchd_disable() {
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
svc_disable()     { init_${INIT_SYSTEM}_disable "$(svc_service_path)"; }
svc_write()       { init_${INIT_SYSTEM}_write_service "$@"; }
svc_start()       { init_${INIT_SYSTEM}_start "$(svc_service_path)"; }
svc_enable()      { init_${INIT_SYSTEM}_enable "$(svc_service_path)"; }
svc_service_path(){ init_${INIT_SYSTEM}_service_path "$@"; }
svc_service_dir() { init_${INIT_SYSTEM}_service_dir "$@"; }
svc_note()        { init_${INIT_SYSTEM}_note "$@"; }

# ── Portable in-place sed (GNU vs BSD/macOS) ──
sed_inplace() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# ══════════════════════════════════════════════
# Cleanup: remove old install (selective)
# ══════════════════════════════════════════════
cleanup() {
  echo "── Cleaning old Periphery install ──"

  svc_stop
  svc_disable

  local svc_file
  svc_file="$(svc_service_path)"
  if [[ -f "$svc_file" ]]; then
    rm -f "$svc_file"
    echo "removed service file: $svc_file"
  fi

  if [[ -f "$BIN_DIR/periphery" ]]; then
    rm -f "$BIN_DIR/periphery"
    echo "removed binary: $BIN_DIR/periphery"
  fi

  if [[ -f "$CONFIG_FILE" ]]; then
    rm -f "$CONFIG_FILE"
    echo "removed config: $CONFIG_FILE"
  fi

  # keys dir holds the pinned Core key (core.pub) and Periphery's own key
  # (periphery.key). Removing it forces a fresh TOFU pin / key regeneration
  # on next start. stacks/repos/builds are left untouched.
  if [[ -d "$EFFECTIVE_ROOT_DIR/keys" ]]; then
    rm -rf "$EFFECTIVE_ROOT_DIR/keys"
    echo "removed keys dir: $EFFECTIVE_ROOT_DIR/keys"
  fi

  echo "── Cleanup done ──"
}

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

# ── Effective root directory (mirrors config-generation logic) ──
if [[ -n "$ROOT_DIR" ]]; then
  EFFECTIVE_ROOT_DIR="$ROOT_DIR"
elif [[ "$USER_INSTALL" == true ]]; then
  EFFECTIVE_ROOT_DIR="$HOME_DIR/komodo"
else
  EFFECTIVE_ROOT_DIR="/etc/komodo"
fi

# Config file path (needed by cleanup before the install section runs)
CONFIG_FILE="${CONFIG_DIR}/periphery.config.toml"

# ── Print info ──
echo "====================="
echo " PERIPHERY INSTALLER "
echo "====================="
echo "init system: $INIT_SYSTEM"
echo "version: $VERSION"
echo "github route: ${PROXY_BASE:-direct}"
echo "core address: ${CORE_ADDRESS:-(inbound)}"
echo "connect as: $CONNECT_AS"
echo "user install: $USER_INSTALL"
echo "home dir: $HOME_DIR"
echo "bin dir: $BIN_DIR"
echo "config dir: $CONFIG_DIR"
echo "service dir: $SERVICE_DIR"

# ── Uninstall mode: clean and exit ──
if [[ "$UNINSTALL" == true ]]; then
  cleanup
  echo ""
  echo "Periphery has been uninstalled."
  echo "Note: stacks/repos/builds under ${EFFECTIVE_ROOT_DIR} were left intact."
  exit 0
fi

# ── Clean mode: remove old install before installing fresh ──
if [[ "$CLEAN" == true ]]; then
  cleanup
fi

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

# Feature-detect --retry-all-errors (curl >= 7.71). Older curl (Debian 10,
# Ubuntu 18/20, CentOS 8) lacks it — without it, default --retry may not
# retry HTTP/2 stream errors (exit 92), so the download dies on the first
# dropped stream.
RETRY_ALL_FLAGS=()
if curl --help all 2>/dev/null | grep -q -- '--retry-all-errors'; then
  RETRY_ALL_FLAGS+=(--retry-all-errors)
fi

# Ordered candidate URLs: the primary route (chosen proxy, or direct when
# no proxy is reachable) first, then the remaining reachable proxies ranked
# by real throughput (a 2MB ranged probe of the actual binary — on CN
# transit proxies that stall large transfers sink to the bottom of the
# list; skipped when only one proxy is configured), then direct GitHub as
# the final fallback. If a flaky transit kills a stream mid-transfer (curl
# exit 92), the next candidate takes over instead of aborting the install.
DIRECT_URL="${ORIG_BINARY_URL}/${VERSION}/${PERIPHERY_BIN}"
DL_URLS=()
if [[ -n "$PROXY_BASE" ]]; then
  DL_URLS+=("${BINARY_URL}/${VERSION}/${PERIPHERY_BIN}")
else
  DL_URLS+=("$DIRECT_URL")
fi
if [[ "$BINARY_URL_SET" != true && "${#REACHABLE_PROXIES[@]}" -gt 1 ]]; then
  while read -r _ _ p; do
    [[ -z "$p" ]] && continue
    url="$(rewrite_github_url "${ORIG_BINARY_URL}/${VERSION}/${PERIPHERY_BIN}" "$p")"
    # Skip candidates that duplicate the primary route (the first reachable
    # proxy may already be BINARY_URL, and direct may already be primary).
    [[ "$url" == "${DL_URLS[0]}" || "$url" == "$DIRECT_URL" ]] && continue
    DL_URLS+=("$url")
  done < <(for p in "${REACHABLE_PROXIES[@]}"; do
             t0=$(date +%s)
             bytes=$(curl -fsSL --http1.1 -r 0-2097151 --connect-timeout 5 --max-time 20 \
                    -o /dev/null -w '%{size_download}' \
                    "$(rewrite_github_url "${ORIG_BINARY_URL}/${VERSION}/${PERIPHERY_BIN}" "$p")" 2>/dev/null || true)
             echo "${bytes:-0} $(( $(date +%s) - t0 )) $p"
           done | sort -t' ' -k1,1 -rn)
fi
# Direct GitHub as the final fallback (unless --binary-url overrode the source).
if [[ "$BINARY_URL_SET" != true && "${DL_URLS[0]}" != "$DIRECT_URL" ]]; then
  DL_URLS+=("$DIRECT_URL")
fi

# Integrity gate: a mirror can return HTTP 200 with garbage instead of the
# binary (gh.con.sh serves a 48-byte suspension notice, ghproxy.cn serves an
# HTML challenge page). curl -f only rejects HTTP error codes, not wrong
# content - so require a plausible size + valid ELF/Mach-O magic before
# accepting a download as successful.
verify_binary() { # $1 = path; returns 0 if it looks like a real executable
  local f="$1" size magic
  size=$(wc -c < "$f" 2>/dev/null || echo 0)
  [[ "$size" -gt 1048576 ]] || return 1        # real binary is ~25MB; reject tiny garbage
  magic=$(od -An -t x1 -N4 "$f" 2>/dev/null | tr -d ' \n')
  if [[ "$OS" == "darwin" ]]; then
    case "$magic" in
      cffaedfe|cefaedfe|cafebabe) return 0 ;;  # Mach-O 64/32 LE, fat binary
      *) return 1 ;;
    esac
  else
    [[ "$magic" == "7f454c46" ]] || return 1  # 0x7F 'E' 'L' 'F'
  fi
  return 0
}

DL_OK=false
for url in "${DL_URLS[@]}"; do
  echo "Downloading $url ..."
  # --http1.1: HTTP/2 streams die on flaky transit ("stream not closed
  # cleanly"); HTTP/1.1 is far more forgiving. -C -: resume partial
  # downloads so retries make progress instead of restarting ~25MB from
  # zero. One retry only, short max-time: a proxy that stalls large
  # transfers is abandoned quickly instead of burning 4x180s before the
  # next (speed-ranked) candidate is tried. -S: surface curl's own error
  # text (a stalled transfer with -s looks like a hang).
  if curl -fSL --http1.1 -C - --retry 1 --retry-delay 2 "${RETRY_ALL_FLAGS[@]}" \
       --connect-timeout 10 --max-time 90 -S "$url" -o "$BIN_PATH" && verify_binary "$BIN_PATH"; then
    DL_OK=true
    break
  fi
  echo "  download failed via $url (or failed integrity check) — trying next source..."
  rm -f "$BIN_PATH"
done

if [[ "$DL_OK" != true ]]; then
  echo "Failed to download binary."
  echo ""
  echo "Did you provide a valid tag for '--version'? Check here for valid version tags:"
  echo "https://github.com/moghtech/komodo/tags"
  echo "Or retry later, or pass --binary-url to a mirror that works for you."
  exit 1
fi

chmod +x "$BIN_PATH"

# ── Write config ──
if [[ -f "$CONFIG_FILE" ]]; then
  if [[ -n "$CORE_PUBLIC_KEYS" ]]; then
    echo "Updating core_public_keys in existing config at ${CONFIG_FILE}"
    if grep -q '^core_public_keys' "$CONFIG_FILE"; then
      sed_inplace "s|^core_public_keys = .*|core_public_keys = \"${CORE_PUBLIC_KEYS}\"|" "$CONFIG_FILE"
    elif grep -q '^# core_public_keys' "$CONFIG_FILE"; then
      sed_inplace "s|^# core_public_keys = .*|core_public_keys = \"${CORE_PUBLIC_KEYS}\"|" "$CONFIG_FILE"
    else
      printf '\ncore_public_keys = "%s"\n' "$CORE_PUBLIC_KEYS" >> "$CONFIG_FILE"
    fi
  else
    echo "Config at ${CONFIG_FILE} already exists, skipping..."
  fi
else
  echo "creating config at ${CONFIG_FILE}"
  mkdir -p "$CONFIG_DIR"

  # Download template (same hardening as the binary: HTTP/1.1 + retry-all).
  # jsDelivr CDN fallback: serves repo files <20MB with no prefix needed, and
  # is reachable where raw.githubusercontent.com (and the proxy prefixes) are
  # not. Only used for the built-in config URL, not --config-url overrides.
  CONFIG_TEMPLATE=""
  if ! CONFIG_TEMPLATE=$(curl -fsSL --http1.1 --retry 1 --retry-delay 2 "${RETRY_ALL_FLAGS[@]}" --connect-timeout 10 --max-time 30 "$CONFIG_URL" 2>/dev/null); then
    if [[ "$CONFIG_URL_SET" == false ]]; then
      echo "→ config fetch failed via $CONFIG_URL — trying jsDelivr CDN..."
      CONFIG_TEMPLATE=$(curl -fsSL --http1.1 --retry 1 --retry-delay 2 "${RETRY_ALL_FLAGS[@]}" --connect-timeout 10 --max-time 30 "https://cdn.jsdelivr.net/gh/moghtech/komodo@main/config/periphery.config.toml" 2>/dev/null) || true
      if [[ -z "$CONFIG_TEMPLATE" ]]; then
        echo "→ jsDelivr failed too — trying direct raw.githubusercontent.com..."
        CONFIG_TEMPLATE=$(curl -fsSL --http1.1 --retry 1 --retry-delay 2 "${RETRY_ALL_FLAGS[@]}" --connect-timeout 10 --max-time 30 "$ORIG_CONFIG_URL" 2>/dev/null) || true
      fi
    fi
  fi
  if [[ -z "$CONFIG_TEMPLATE" ]]; then
    echo "Error: failed to download config template from $CONFIG_URL"
    exit 1
  fi

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

  # core_public_keys (uncomment + set)
  if [[ -n "$CORE_PUBLIC_KEYS" ]]; then
    OUTPUT=$(echo "$OUTPUT" | sed "s|^# core_public_keys = .*|core_public_keys = \"${CORE_PUBLIC_KEYS}\"|")
  fi

  echo "$OUTPUT" > "$CONFIG_FILE"
fi

# ── Stale TOFU pin cleanup ──
# keys/core.pub holds the previously pinned Core public key (the default
# trust-on-first-use pin when the config doesn't pin one explicitly). A
# stale pin keeps failing the handshake ("Periphery failed to validate Core
# public key") until the file is cleared AND Periphery restarts — the
# installer already stopped the service before downloading and starts it at
# the end, so the restart is guaranteed. Only core.pub is touched:
# periphery.key is Periphery's own identity and must be preserved.
if [[ -n "$CORE_PUBLIC_KEYS" && -f "$EFFECTIVE_ROOT_DIR/keys/core.pub" ]]; then
  rm -f "$EFFECTIVE_ROOT_DIR/keys/core.pub"
  echo "removed stale Core public key pin: $EFFECTIVE_ROOT_DIR/keys/core.pub"
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
