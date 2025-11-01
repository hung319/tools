#!/usr/bin/env bash
set -e

# ========================
# Homebrew no-root installer + .local integration
# ========================

LOCAL_BASE="$HOME/.local"
BREW_PREFIX="$LOCAL_BASE/homebrew"
BREW_REPO_TARBALL="https://github.com/Homebrew/brew/tarball/main"

# Custom cache/temp/logs
HOMEBREW_CACHE="$BREW_PREFIX/homebrew-cache"
HOMEBREW_TEMP="$BREW_PREFIX/homebrew-tmp"
HOMEBREW_LOGS="$BREW_PREFIX/homebrew-logs"

# Đường dẫn prefix thật mà brew sẽ cài gói vào
HOMEBREW_PREFIX="$LOCAL_BASE"
HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"

# Cài đặt Homebrew (tarball)
if [ ! -f "$BREW_PREFIX/bin/brew" ]; then
  echo "🍺 Đang cài Homebrew (tarball) vào $BREW_PREFIX ..."
  mkdir -p "$BREW_PREFIX"
  curl -L "$BREW_REPO_TARBALL" \
    | tar xz --strip-components 1 -C "$BREW_PREFIX" \
    || { echo "❌ Không thể tải & giải nén Homebrew"; exit 1; }
else
  echo "✅ Homebrew đã tồn tại tại $BREW_PREFIX."
fi

# Tạo thư mục hỗ trợ
mkdir -p "$HOMEBREW_CACHE" "$HOMEBREW_TEMP" "$HOMEBREW_LOGS" "$HOMEBREW_CELLAR"

# Detect shell
SHELL_NAME=$(basename "$SHELL")
CONFIG_FILE=""
case "$SHELL_NAME" in
  bash) CONFIG_FILE="$HOME/.bashrc" ;;
  zsh)  CONFIG_FILE="$HOME/.zshrc" ;;
  fish) CONFIG_FILE="$HOME/.config/fish/config.fish" ;;
  *)    echo "⚠️ Không nhận diện được shell ($SHELL_NAME)." ;;
esac

# Thêm PATH và biến môi trường vào shell config
if [ -n "$CONFIG_FILE" ]; then
  echo "🔧 Cập nhật $CONFIG_FILE ..."
  if ! grep -q "$BREW_PREFIX/bin/brew" "$CONFIG_FILE" 2>/dev/null; then
    {
      echo ""
      echo "# Homebrew (user-local install)"
      echo "export HOMEBREW_PREFIX=\"$HOMEBREW_PREFIX\""
      echo "export HOMEBREW_CELLAR=\"$HOMEBREW_CELLAR\""
      echo "export HOMEBREW_CACHE=\"$HOMEBREW_CACHE\""
      echo "export HOMEBREW_TEMP=\"$HOMEBREW_TEMP\""
      echo "export HOMEBREW_LOGS=\"$HOMEBREW_LOGS\""
      echo "export PATH=\"$BREW_PREFIX/bin:\$HOMEBREW_PREFIX/bin:\$PATH\""
      echo "export MANPATH=\"\$HOMEBREW_PREFIX/share/man:\$MANPATH\""
      echo "export INFOPATH=\"\$HOMEBREW_PREFIX/share/info:\$INFOPATH\""
    } >> "$CONFIG_FILE"
  fi
fi

# Export để dùng ngay
export HOMEBREW_PREFIX="$HOMEBREW_PREFIX"
export HOMEBREW_CELLAR="$HOMEBREW_CELLAR"
export HOMEBREW_CACHE="$HOMEBREW_CACHE"
export HOMEBREW_TEMP="$HOMEBREW_TEMP"
export HOMEBREW_LOGS="$HOMEBREW_LOGS"
export PATH="$BREW_PREFIX/bin:$HOMEBREW_PREFIX/bin:$PATH"

# Test brew hoạt động
echo "🍹 Kiểm tra phiên bản Homebrew..."
"$BREW_PREFIX/bin/brew" --version || { echo "❌ Lỗi khi chạy brew"; exit 1; }

# Buộc Homebrew update metadata
"$BREW_PREFIX/bin/brew" update --force --quiet
chmod -R go-w "$("$BREW_PREFIX/bin/brew" --prefix)/share/zsh" || true

echo "✅ Cài đặt xong! Mọi gói sẽ được cài vào:"
echo "   Bin:   $HOMEBREW_PREFIX/bin"
echo "   Lib:   $HOMEBREW_PREFIX/lib"
echo "   Include: $HOMEBREW_PREFIX/include"
echo "   Cellar: $HOMEBREW_CELLAR"
