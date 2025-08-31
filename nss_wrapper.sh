#!/usr/bin/env bash
set -e

# ==============================
# Config
# ==============================
APP_NAME="fakeuser"                         # tên folder cài đặt
INSTALL_DIR="$HOME/.local/$APP_NAME"        # nơi cài đặt
SRC_DIR="$INSTALL_DIR/src"                  # source code
FAKE_USER="fakeuser"                        # tên user giả
FAKE_HOME="$HOME"                           # home giả
SHELL_CONFIG=""

# ==============================
# Detect shell config
# ==============================
case "$SHELL" in
  */bash)
    SHELL_CONFIG="$HOME/.bashrc"
    ;;
  */zsh)
    SHELL_CONFIG="$HOME/.zshrc"
    ;;
  *)
    SHELL_CONFIG="$HOME/.profile"
    ;;
esac

echo "🔎 Using shell config: $SHELL_CONFIG"

# ==============================
# Prepare dirs
# ==============================
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# ==============================
# Get nss_wrapper
# ==============================
if [ ! -d "nss_wrapper" ]; then
  git clone https://git.samba.org/nss_wrapper.git
else
  cd nss_wrapper && git pull && cd ..
fi

cd nss_wrapper

# ==============================
# Build
# ==============================
mkdir -p build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR"
make -j"$(nproc)"
make install

# ==============================
# Generate passwd & group file
# ==============================
uid=$(id -u)
gid=$(id -g)

PASSWD_FILE="$INSTALL_DIR/etc_passwd"
GROUP_FILE="$INSTALL_DIR/etc_group"
mkdir -p "$(dirname "$PASSWD_FILE")"

cat > "$PASSWD_FILE" <<EOF
$FAKE_USER:x:$uid:$gid:Fake User:$FAKE_HOME:/bin/bash
EOF

cat > "$GROUP_FILE" <<EOF
$FAKE_USER:x:$gid:
EOF

# ==============================
# Add env to shell config
# ==============================
if ! grep -q "nss_wrapper setup ($APP_NAME)" "$SHELL_CONFIG"; then
cat >> "$SHELL_CONFIG" <<EOF

# >>> nss_wrapper setup ($APP_NAME) >>>
export LD_PRELOAD="$INSTALL_DIR/lib/libnss_wrapper.so"
export NSS_WRAPPER_PASSWD="$PASSWD_FILE"
export NSS_WRAPPER_GROUP="$GROUP_FILE"
# <<< nss_wrapper setup ($APP_NAME) <<<
EOF
fi

echo "✅ Installed successfully!"
echo "👉 Run: source $SHELL_CONFIG"
echo "👉 Test: whoami (should print: $FAKE_USER)"
echo "👉 To uninstall: rm -rf $INSTALL_DIR && sed -i '/nss_wrapper setup ($APP_NAME)/,/^# <<< nss_wrapper setup ($APP_NAME) <<</d' $SHELL_CONFIG"
