#!/bin/bash

# Dừng script ngay lập tức nếu có lỗi.
set -e

# --- CÁC BIẾN CẤU HÌNH ---
# Cài đặt phpenv vào thư mục ~/.local/phpenv
PHPENV_DIR="$HOME/.local/phpenv"

# --- BẮT ĐẦU SCRIPT ---
echo "🚀 Bắt đầu quá trình cài đặt phpenv và php-build..."

# 1. Kiểm tra xem Git đã được cài đặt chưa
if ! command -v git &> /dev/null; then
    echo "❌ Lỗi: Không tìm thấy lệnh 'git'."
    echo "Vui lòng cài đặt Git trước khi chạy script này."
    exit 1
fi

# 2. Cài đặt phpenv và php-build
if [ -d "$PHPENV_DIR" ]; then
    echo "✅ phpenv đã được cài đặt tại $PHPENV_DIR. Bỏ qua bước cài đặt."
else
    echo ">> Cài đặt phpenv vào $PHPENV_DIR..."
    git clone https://github.com/phpenv/phpenv.git "$PHPENV_DIR"

    echo ">> Cài đặt php-build làm plugin..."
    mkdir -p "$PHPENV_DIR/plugins"
    git clone https://github.com/php-build/php-build.git "$PHPENV_DIR/plugins/php-build"
fi

# 3. Tự động phát hiện và cập nhật cấu hình Shell
echo ">> Cập nhật cấu hình shell..."
CURRENT_SHELL=$(basename "$SHELL")
SHELL_CONFIG_FILE=""

case "$CURRENT_SHELL" in
    bash)
        SHELL_CONFIG_FILE="$HOME/.bashrc"
        ;;
    zsh)
        SHELL_CONFIG_FILE="$HOME/.zshrc"
        ;;
    *)
        echo "⚠️ Không nhận diện được shell của bạn là bash hay zsh."
        echo "Vui lòng tự thêm các dòng sau vào tệp cấu hình shell của bạn:"
        echo "   export PHPENV_ROOT=\"$PHPENV_DIR\""
        echo "   export PATH=\"\$PHPENV_ROOT/bin:\$PATH\""
        echo '   eval "$(phpenv init -)"'
        exit 0
        ;;
esac

echo "   -> Phát hiện shell: $CURRENT_SHELL. Tệp cấu hình: $SHELL_CONFIG_FILE"

# Các dòng cần thêm vào tệp cấu hình
# Đặt PHPENV_ROOT vì chúng ta không dùng đường dẫn mặc định ~/.phpenv
LINE1="export PHPENV_ROOT=\"$PHPENV_DIR\""
LINE2='export PATH="$PHPENV_ROOT/bin:$PATH"'
LINE3='eval "$(phpenv init -)"'

# Kiểm tra và chỉ thêm nếu các dòng chưa tồn tại
if ! grep -qF "$LINE1" "$SHELL_CONFIG_FILE"; then
    echo "   -> Thêm cấu hình phpenv vào $SHELL_CONFIG_FILE..."
    echo -e "\n# phpenv configuration" >> "$SHELL_CONFIG_FILE"
    echo "$LINE1" >> "$SHELL_CONFIG_FILE"
    echo "$LINE2" >> "$SHELL_CONFIG_FILE"
    echo "$LINE3" >> "$SHELL_CONFIG_FILE"
    echo "✅ Cập nhật $SHELL_CONFIG_FILE thành công."
else
    echo "✅ Cấu hình phpenv đã tồn tại trong $SHELL_CONFIG_FILE. Bỏ qua."
fi

# --- HOÀN TẤT ---
echo -e "\n🎉 Cài đặt phpenv và php-build hoàn tất!"
echo "Thư mục cài đặt: $PHPENV_DIR"
echo ""
echo "VUI LÒNG CHẠY LỆNH SAU ĐỂ CẬP NHẬT MÔI TRƯỜNG:"
echo "   source $SHELL_CONFIG_FILE"
echo "Hoặc mở một cửa sổ terminal mới."
echo ""
echo "Sau đó, bạn có thể bắt đầu cài đặt PHP:"
echo "   - Xem các phiên bản có thể cài: phpenv install --list"
echo "   - Cài một phiên bản cụ thể:   phpenv install 8.3.8"
