#!/usr/bin/env bash
set -e

# --- Xác định kiến trúc ---
ARCH=$(uname -m)
case "$ARCH" in
  x86_64) GUIX_ARCH="x86_64-linux" ;;
  i686)   GUIX_ARCH="i686-linux" ;;
  aarch64|arm64) GUIX_ARCH="aarch64-linux" ;;
  *) echo "Kiến trúc $ARCH chưa được hỗ trợ trực tiếp"; exit 1 ;;
esac

# --- Lấy phiên bản mới nhất ---
LATEST_URL=$(curl -s https://ftp.gnu.org/gnu/guix/ | \
grep -Eo "guix-binary-[0-9]+\.[0-9]+\.[0-9]+\.${GUIX_ARCH}\.tar\.xz" | \
sort -V | tail -n1)
GUIX_VERSION=$(echo "$LATEST_URL" | sed -E "s/guix-binary-([0-9]+\.[0-9]+\.[0-9]+)\.${GUIX_ARCH}\.tar\.xz/\1/")
PREFIX="$HOME/.local/guix"

echo "🔹 Kiến trúc: $ARCH → gói: $GUIX_ARCH"
echo "🔹 Phiên bản Guix mới nhất: $GUIX_VERSION"

# --- Tải Guix binary ---
mkdir -p "$PREFIX"
cd /tmp
wget -c "https://ftp.gnu.org/gnu/guix/$LATEST_URL"

# --- Giải nén vào ~/.local/guix ---
tar -xf "$LATEST_URL"
cd "guix-binary-${GUIX_VERSION}.${GUIX_ARCH}"
./install --prefix="$PREFIX"

# --- Thiết lập PATH và profile ---
CONFIG_DIR="$HOME/.config/guix"
ENV_FILE="$CONFIG_DIR/env"
mkdir -p "$CONFIG_DIR"

cat <<'EOF' > "$ENV_FILE"
export PATH="$HOME/.local/guix/.guix-profile/bin:$PATH"
export GUIX_PROFILE="$HOME/.local/guix/.guix-profile"
source "$GUIX_PROFILE/etc/profile"
# Luôn dùng cache server chính thức
export GUIX_SUBSTITUTE_URLS="https://ci.guix.gnu.org"
EOF

# --- Tự động detect shell config ---
SHELL_NAME=$(basename "$SHELL")
if [ "$SHELL_NAME" = "bash" ]; then
    RC_FILE="$HOME/.bashrc"
elif [ "$SHELL_NAME" = "zsh" ]; then
    RC_FILE="$HOME/.zshrc"
else
    RC_FILE="$HOME/.profile"
fi

if ! grep -q 'source \$HOME/.config/guix/env' "$RC_FILE" 2>/dev/null; then
    echo "source \$HOME/.config/guix/env" >> "$RC_FILE"
    echo "Đã thêm vào $RC_FILE để tự động load env"
else
    echo "Env đã có trong $RC_FILE"
fi

# --- Load env ngay ---
source "$ENV_FILE"

echo "✅ Guix $GUIX_VERSION ($GUIX_ARCH) đã được cài vào $PREFIX"
echo "Mở terminal mới để dùng Guix luôn nha Yuu Onii-chan 💻✨"
