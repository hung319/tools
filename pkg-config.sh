#!/bin/bash

# Dừng script ngay lập tức nếu có lỗi
set -e

# --- CÁC BIẾN CẤU HÌNH ---
PKG_CONFIG_VERSION="0.29.2"
SOURCE_DIR="$HOME/src"
INSTALL_DIR="$HOME/.local"
DOWNLOAD_URL="https://pkg-config.freedesktop.org/releases/pkg-config-${PKG_CONFIG_VERSION}.tar.gz"

# --- BẮT ĐẦU SCRIPT ---

echo "--- Bắt đầu quá trình cài đặt pkg-config ---"

# 1. Tạo các thư mục cần thiết
echo "-> Tạo thư mục nguồn và thư mục cài đặt..."
mkdir -p "$SOURCE_DIR"
mkdir -p "$INSTALL_DIR"

# 2. Tải mã nguồn
echo "-> Tải mã nguồn pkg-config phiên bản ${PKG_CONFIG_VERSION}..."
cd "$SOURCE_DIR"
if [ ! -f "pkg-config-${PKG_CONFIG_VERSION}.tar.gz" ]; then
    wget "$DOWNLOAD_URL"
else
    echo "-> Tệp mã nguồn đã tồn tại, bỏ qua bước tải."
fi

# 3. Giải nén
echo "-> Giải nén tệp mã nguồn..."
rm -rf "pkg-config-${PKG_CONFIG_VERSION}"
tar -xzf "pkg-config-${PKG_CONFIG_VERSION}.tar.gz"

# 4. Biên dịch và cài đặt
echo "-> Biên dịch và cài đặt vào $INSTALL_DIR..."
cd "pkg-config-${PKG_CONFIG_VERSION}"

./configure --prefix="$INSTALL_DIR" --with-internal-glib

# --- THAY ĐỔI Ở ĐÂY ---
# Biên dịch với tất cả các lõi CPU để tăng tốc 🚀
echo "-> Bắt đầu biên dịch, sử dụng tất cả các lõi CPU..."
make -j$(nproc)

# Cài đặt
make install

echo ""
echo "✅ pkg-config đã được cài đặt thành công vào: $INSTALL_DIR"
echo ""

# --- TỰ ĐỘNG CẤU HÌNH MÔI TRƯỜNG ---

# Xác định file cấu hình shell
SHELL_CONFIG_FILE=""
if [ -n "$BASH_VERSION" ]; then
    SHELL_CONFIG_FILE="$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG_FILE="$HOME/.zshrc"
else
    echo "⚠️ Không thể tự động xác định file cấu hình shell (hỗ trợ bash và zsh)."
    echo "Vui lòng tự thêm các dòng sau vào file cấu hình của bạn:"
    echo 'export PATH="$HOME/.local/bin:$PATH"'
    echo 'export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:$HOME/.local/share/pkgconfig:$PKG_CONFIG_PATH"'
    exit 0
fi

echo "-> Tự động cập nhật file cấu hình shell: $SHELL_CONFIG_FILE"

# Chuỗi cần thêm
PATH_EXPORT='export PATH="$HOME/.local/bin:$PATH"'
PKG_CONFIG_PATH_EXPORT='export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:$HOME/.local/share/pkgconfig:$PKG_CONFIG_PATH"'

# Kiểm tra và thêm PATH nếu chưa có
if ! grep -qF -- "$PATH_EXPORT" "$SHELL_CONFIG_FILE"; then
    echo 'Thêm cấu hình PATH...'
    echo -e "\n# Cấu hình cho các công cụ cài đặt tại local" >> "$SHELL_CONFIG_FILE"
    echo "$PATH_EXPORT" >> "$SHELL_CONFIG_FILE"
else
    echo 'Cấu hình PATH đã tồn tại.'
fi

# Kiểm tra và thêm PKG_CONFIG_PATH nếu chưa có
if ! grep -qF -- "$PKG_CONFIG_PATH_EXPORT" "$SHELL_CONFIG_FILE"; then
    echo 'Thêm cấu hình PKG_CONFIG_PATH...'
    echo "$PKG_CONFIG_PATH_EXPORT" >> "$SHELL_CONFIG_FILE"
else
    echo 'Cấu hình PKG_CONFIG_PATH đã tồn tại.'
fi

# --- HOÀN TẤT ---
echo ""
echo "🎉 Quá trình hoàn tất!"
echo "Đã tự động thêm cấu hình vào $SHELL_CONFIG_FILE."
echo "Để áp dụng thay đổi, vui lòng chạy lệnh sau hoặc mở lại terminal:"
echo "source $SHELL_CONFIG_FILE"
