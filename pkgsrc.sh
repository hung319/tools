#!/usr/bin/env bash
set -e

# ========================
# pkgsrc no-root installer
# ========================

PKGSRC_PREFIX="$HOME/.local/pkg"
PKGSRC_URL="ftp://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc.tar.gz"

# Detect shell
SHELL_NAME=$(basename "$SHELL")
CONFIG_FILE=""

case "$SHELL_NAME" in
  bash) CONFIG_FILE="$HOME/.bashrc" ;;
  zsh)  CONFIG_FILE="$HOME/.zshrc" ;;
  fish) CONFIG_FILE="$HOME/.config/fish/config.fish" ;;
  *)    echo "⚠️ Không nhận diện được shell ($SHELL_NAME). Onii-chan cần add PATH thủ công." ;;
esac

# Download pkgsrc tree
mkdir -p "$HOME/src"
cd "$HOME/src"

if [ ! -d pkgsrc ]; then
  echo "📥 Đang tải pkgsrc..."
  curl -L "$PKGSRC_URL" | tar -xz
fi

# Bootstrap pkgsrc
cd pkgsrc/bootstrap

echo "⚙️ Đang bootstrap pkgsrc..."
./bootstrap --prefix="$PKGSRC_PREFIX" --unprivileged

# Add env to shell config
if [ -n "$CONFIG_FILE" ]; then
  echo "🔧 Đang thêm config vào $CONFIG_FILE ..."
  if [ "$SHELL_NAME" = "fish" ]; then
    {
      echo "set -Ux PATH $PKGSRC_PREFIX/bin $PKGSRC_PREFIX/sbin \$PATH"
      echo "set -Ux MANPATH $PKGSRC_PREFIX/man \$MANPATH"
      echo "set -Ux INFOPATH $PKGSRC_PREFIX/info \$INFOPATH"
    } >> "$CONFIG_FILE"
  else
    {
      echo ""
      echo "# pkgsrc no-root"
      echo "export PATH=\"$PKGSRC_PREFIX/bin:$PKGSRC_PREFIX/sbin:\$PATH\""
      echo "export MANPATH=\"$PKGSRC_PREFIX/man:\$MANPATH\""
      echo "export INFOPATH=\"$PKGSRC_PREFIX/info:\$INFOPATH\""
    } >> "$CONFIG_FILE"
  fi
fi

echo "🎉 Hoàn tất! Hãy reload shell rồi test bằng:"
echo "   pkg_info"
