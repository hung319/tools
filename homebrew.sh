#!/usr/bin/env bash
set -e

# ========================
# Homebrew no-root installer
# ========================

BREW_PREFIX="$HOME/.local/homebrew"
BREW_REPO="https://github.com/Homebrew/brew"

# Detect shell
SHELL_NAME=$(basename "$SHELL")
CONFIG_FILE=""

case "$SHELL_NAME" in
  bash)
    CONFIG_FILE="$HOME/.bashrc"
    ;;
  zsh)
    CONFIG_FILE="$HOME/.zshrc"
    ;;
  fish)
    CONFIG_FILE="$HOME/.config/fish/config.fish"
    ;;
  *)
    echo "⚠️ Không nhận diện được shell ($SHELL_NAME). Onii-chan cần add PATH thủ công."
    CONFIG_FILE=""
    ;;
esac

# Clone Homebrew
if [ ! -d "$BREW_PREFIX" ]; then
  echo "🍺 Đang cài Homebrew vào $BREW_PREFIX ..."
  git clone --depth=1 "$BREW_REPO" "$BREW_PREFIX"
else
  echo "✅ Homebrew đã tồn tại tại $BREW_PREFIX"
fi

# Add to PATH
if [ -n "$CONFIG_FILE" ]; then
  echo "🔧 Đang thêm PATH vào $CONFIG_FILE ..."
  if [ "$SHELL_NAME" = "fish" ]; then
    echo "set -Ux PATH $BREW_PREFIX/bin \$PATH" >> "$CONFIG_FILE"
  else
    {
      echo ""
      echo "# Homebrew"
      echo "export PATH=\"$BREW_PREFIX/bin:\$PATH\""
    } >> "$CONFIG_FILE"
  fi
fi

# Reload shell config
echo "🔄 Reload config..."
if [ "$SHELL_NAME" = "bash" ] || [ "$SHELL_NAME" = "zsh" ]; then
  source "$CONFIG_FILE"
elif [ "$SHELL_NAME" = "fish" ]; then
  source "$CONFIG_FILE" >/dev/null 2>&1 || true
fi

# Test
echo "🍹 Homebrew version:"
"$BREW_PREFIX/bin/brew" --version
