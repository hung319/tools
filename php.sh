#!/bin/bash

# Dừng script ngay lập tức nếu có lỗi.
set -e

echo "🚀 Bắt đầu quá trình cài đặt phpenv bằng trình cài đặt tự động..."

# 1. Tải và chạy phpenv-installer
# Trình cài đặt này sẽ tự động clone phpenv và php-build vào ~/.phpenv
curl -L https://raw.githubusercontent.com/phpenv/phpenv-installer/master/bin/phpenv-installer | bash

echo "✅ Cài đặt phpenv và php-build thành công."

# 2. Tự động phát hiện và cập nhật cấu hình Shell
echo ">> Cập nhật cấu hình shell..."

# Các dòng cần thêm vào tệp cấu hình.
# Trình cài đặt mặc định vào ~/.phpenv, nên ta không cần set PHPENV_ROOT.
LINE1='export PATH="$HOME/.phpenv/bin:$PATH"'
LINE2='eval "$(phpenv init -)"'

CURRENT_SHELL=$(basename "$SHELL")
SHELL_CONFIG_FILE=""

case "$CURRENT_SHELL" in
    bash)
        # Kiểm tra cả .bash_profile và .bashrc
        if [ -f "$HOME/.bash_profile" ]; then
            SHELL_CONFIG_FILE="$HOME/.bash_profile"
        else
            SHELL_CONFIG_FILE="$HOME/.bashrc"
        fi
        ;;
    zsh)
        SHELL_CONFIG_FILE="$HOME/.zshrc"
        ;;
    *)
        echo "⚠️ Không nhận diện được shell của bạn là bash hay zsh."
        echo "Vui lòng tự thêm các dòng sau vào tệp cấu hình shell của bạn:"
        echo "   $LINE1"
        echo "   $LINE2"
        exit 0
        ;;
esac

echo "   -> Phát hiện shell: $CURRENT_SHELL. Tệp cấu hình: $SHELL_CONFIG_FILE"

# Kiểm tra và chỉ thêm nếu các dòng chưa tồn tại
if ! grep -q 'phpenv init' "$SHELL_CONFIG_FILE"; then
    echo "   -> Thêm cấu hình phpenv vào $SHELL_CONFIG_FILE..."
    echo -e "\n# phpenv configuration" >> "$SHELL_CONFIG_FILE"
    echo "$LINE1" >> "$SHELL_CONFIG_FILE"
    echo "$LINE2" >> "$SHELL_CONFIG_FILE"
    echo "✅ Cập nhật $SHELL_CONFIG_FILE thành công."
else
    echo "✅ Cấu hình phpenv đã tồn tại trong $SHELL_CONFIG_FILE. Bỏ qua."
fi

# --- HOÀN TẤT ---
echo -e "\n🎉 Cài đặt phpenv hoàn tất!"
echo "Thư mục cài đặt: ~/.phpenv"
echo ""
echo "VUI LÒNG CHẠY LỆNH SAU ĐỂ CẬP NHẬT MÔI TRƯỜNG:"
echo "   source $SHELL_CONFIG_FILE"
echo "Hoặc mở một cửa sổ terminal mới."
echo ""
echo "Sau đó, bạn có thể bắt đầu cài đặt PHP:"
echo "   - Xem các phiên bản có thể cài: phpenv install --list"
echo "   - Cài một phiên bản cụ thể:   phpenv install 8.3.8"
