#!/usr/bin/env bash
set -e

# ========================
# Homebrew no-root installer + custom cache/temp
# ========================

BREW_PREFIX="$HOME/.local/homebrew"
BREW_REPO="https://github.com/Homebrew/brew"

# 📝 Thêm các đường dẫn cache/temp Onii-chan muốn
HOMEBREW_CACHE="$BREW_PREFIX/homebrew-cache"
HOMEBREW_TEMP="$BREW_PREFIX/homebrew-tmp"
HOMEBREW_LOGS="$BREW_PREFIX/homebrew-logs"

# Kiểm tra nếu tệp brew đã tồn tại trong thư mục bin
if [ ! -f "$BREW_PREFIX/bin/brew" ]; then
  # Clone Homebrew nếu chưa tồn tại
  echo "🍺 Đang cài Homebrew vào $BREW_PREFIX ..."
  git clone "$BREW_REPO" "$BREW_PREFIX" || { echo "❌ Không thể clone Homebrew"; exit 1; }
else
  # Nếu Homebrew đã tồn tại, cập nhật bằng git pull
  echo "✅ Homebrew đã tồn tại tại $BREW_PREFIX. Đang cập nhật..."
  cd "$BREW_PREFIX" || { echo "❌ Không thể vào thư mục Homebrew"; exit 1; }
  git pull origin master || { echo "❌ Không thể cập nhật Homebrew"; exit 1; }
fi

# Tạo thư mục cache, temp, logs sau khi clone hoặc update
mkdir -p "$HOMEBREW_CACHE" "$HOMEBREW_TEMP" "$HOMEBREW_LOGS" || { echo "❌ Không thể tạo thư mục"; exit 1; }

# Detect shell
SHELL_NAME=$(basename "$SHELL")
CONFIG_FILE=""

case "$SHELL_NAME" in
  bash) CONFIG_FILE="$HOME/.bashrc" ;;
  zsh)  CONFIG_FILE="$HOME/.zshrc" ;;
  fish) CONFIG_FILE="$HOME/.config/fish/config.fish" ;;
  *)    echo "⚠️ Không nhận diện được shell ($SHELL_NAME). Onii-chan cần add PATH thủ công." ;;
esac

# Thêm PATH và export biến môi trường cache/temp vào cấu hình shell
if [ -n "$CONFIG_FILE" ]; then
  echo "🔧 Đang thêm PATH + env vào $CONFIG_FILE ..."
  if ! grep -q "export PATH=\"$BREW_PREFIX/bin:\$PATH\"" "$CONFIG_FILE"; then
    if [ "$SHELL_NAME" = "fish" ]; then
      echo "set -Ux PATH $BREW_PREFIX/bin \$PATH" >> "$CONFIG_FILE"
      echo "set -Ux HOMEBREW_CACHE $HOMEBREW_CACHE" >> "$CONFIG_FILE"
      echo "set -Ux HOMEBREW_TEMP $HOMEBREW_TEMP" >> "$CONFIG_FILE"
      echo "set -Ux HOMEBREW_LOGS $HOMEBREW_LOGS" >> "$CONFIG_FILE"
    else
      {
        echo ""
        echo "# Homebrew"
        echo "export PATH=\"$BREW_PREFIX/bin:\$PATH\""
        echo "export HOMEBREW_CACHE=\"$HOMEBREW_CACHE\""
        echo "export HOMEBREW_TEMP=\"$HOMEBREW_TEMP\""
        echo "export HOMEBREW_LOGS=\"$HOMEBREW_LOGS\""
      } >> "$CONFIG_FILE"
    fi
  else
    echo "✅ Các biến đã được thêm vào $CONFIG_FILE rồi."
  fi
fi

# Export ngay trong session này để dùng luôn
export HOMEBREW_CACHE="$HOMEBREW_CACHE"
export HOMEBREW_TEMP="$HOMEBREW_TEMP"
export HOMEBREW_LOGS="$HOMEBREW_LOGS"
export PATH="$BREW_PREFIX/bin:$PATH"

# Reload shell config
echo "🔄 Reload config..."
if [ "$SHELL_NAME" = "bash" ] || [ "$SHELL_NAME" = "zsh" ]; then
  source "$CONFIG_FILE"
elif [ "$SHELL_NAME" = "fish" ]; then
  source "$CONFIG_FILE" >/dev/null 2>&1 || true
fi

# Test Homebrew version
echo "🍹 Homebrew version:"
"$BREW_PREFIX/bin/brew" --version

# Update repo
"$BREW_PREFIX/bin/brew" update --force --quiet
