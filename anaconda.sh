#!/usr/bin/env bash
set -e

# --- Detect architecture ---
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)   ARCH_URL="x86_64";;
    aarch64)  ARCH_URL="aarch64";;
    arm64)    ARCH_URL="aarch64";;
    *) echo "Unsupported architecture: $ARCH"; exit 1;;
esac

# --- Detect shell ---
SHELL_NAME=$(basename "$SHELL")
RC_FILE="$HOME/.bashrc"
if [ "$SHELL_NAME" = "zsh" ]; then
    RC_FILE="$HOME/.zshrc"
elif [ "$SHELL_NAME" = "fish" ]; then
    RC_FILE="$HOME/.config/fish/config.fish"
fi

# --- Install dir ---
INSTALL_DIR="$HOME/.local/anaconda3"

# --- Download anaconda ---
URL="https://repo.anaconda.com/archive/Anaconda3-latest-Linux-${ARCH_URL}.sh"
INSTALLER="/tmp/anaconda.sh"

echo "[*] Downloading Anaconda for $ARCH_URL ..."
curl -L "$URL" -o "$INSTALLER"

# --- Run installer ---
bash "$INSTALLER" -b -p "$INSTALL_DIR"

# --- Add to PATH ---
if ! grep -q "$INSTALL_DIR/bin" "$RC_FILE"; then
    echo "export PATH=\"$INSTALL_DIR/bin:\$PATH\"" >> "$RC_FILE"
    echo "[*] Added Anaconda to $RC_FILE"
fi

echo "[*] Installation complete. Run: source $RC_FILE"
