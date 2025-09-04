#!/bin/bash

# Dừng script ngay khi có lỗi
set -e

# --- Các biến có thể tùy chỉnh ---
# Phiên bản libffi bạn muốn cài đặt.
# Bạn có thể tìm phiên bản mới nhất tại: https://github.com/libffi/libffi/releases
LIBFFI_VERSION="3.4.6"

# Thư mục chứa mã nguồn
SOURCE_DIR="$HOME/src"

# Thư mục cài đặt
INSTALL_PREFIX="$HOME/.local"

# --- Bắt đầu script ---

# 0. Kiểm tra các công cụ build cần thiết
echo "--- 🔍 Kiểm tra các công cụ build ---"
if ! command -v gcc &> /dev/null || ! command -v make &> /dev/null; then
    echo "❌ Lỗi: Không tìm thấy 'gcc' hoặc 'make'."
    echo "Vui lòng cài đặt gói 'build-essential' trước."
    exit 1
fi
echo "✅ Đã có các công cụ build."

# 1. Tạo các thư mục cần thiết
echo "--- 🧱 Tạo thư mục nguồn và thư mục cài đặt ---"
mkdir -p "$SOURCE_DIR"
mkdir -p "$INSTALL_PREFIX"

# 2. Tải mã nguồn
echo "--- 🌐 Tải về libffi phiên bản $LIBFFI_VERSION ---"
cd "$SOURCE_DIR"
if [ ! -f "libffi-$LIBFFI_VERSION.tar.gz" ]; then
    wget "https://github.com/libffi/libffi/releases/download/v$LIBFFI_VERSION/libffi-$LIBFFI_VERSION.tar.gz"
else
    echo "File nguồn đã tồn tại, bỏ qua bước tải về."
fi

# 3. Giải nén
echo "--- 📦 Giải nén file nguồn ---"
# Xóa thư mục cũ để đảm bảo build sạch
rm -rf "libffi-$LIBFFI_VERSION"
tar -xf "libffi-$LIBFFI_VERSION.tar.gz"
cd "libffi-$LIBFFI_VERSION"

# 4. Cấu hình (Configure)
echo "--- ⚙️  Cấu hình build script ---"
./configure --prefix="$INSTALL_PREFIX" --disable-static

# 5. Build
echo "--- 👨‍💻 Biên dịch (make) ---"
# Sử dụng `make -j$(nproc)` để tăng tốc độ build bằng cách sử dụng tất cả các nhân CPU
make -j$(nproc)

# 6. Cài đặt
echo "--- 🚀 Cài đặt (make install) ---"
make install

# 7. Tự động cập nhật file cấu hình Shell (nếu cần)
echo "--- ✍️  Cập nhật file cấu hình shell ---"
SHELL_CONFIG_FILE=""
if [[ "$SHELL" == *"bash"* ]]; then
    SHELL_CONFIG_FILE="$HOME/.bashrc"
elif [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_CONFIG_FILE="$HOME/.zshrc"
fi

if [ -n "$SHELL_CONFIG_FILE" ] && [ -f "$SHELL_CONFIG_FILE" ]; then
    CONFIG_MARKER="# Added by build-script for .local installation"
    if ! grep -qF "$CONFIG_MARKER" "$SHELL_CONFIG_FILE"; then
        echo "Thêm cấu hình biến môi trường vào $SHELL_CONFIG_FILE"
        {
            echo ""
            echo "$CONFIG_MARKER"
            echo 'export PATH="$HOME/.local/bin:$PATH"'
            echo 'export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"'
            echo 'export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH"'
            echo 'export XDG_DATA_DIRS="$HOME/.local/share:$XDG_DATA_DIRS:/usr/local/share/:/usr/share/"'
        } >> "$SHELL_CONFIG_FILE"
    else
        echo "Cấu hình biến môi trường đã tồn tại trong $SHELL_CONFIG_FILE."
    fi
fi

# --- Hoàn tất ---
echo ""
echo "✅ Cài đặt libffi thành công vào $INSTALL_PREFIX"
if [ -n "$SHELL_CONFIG_FILE" ]; then
    echo "✅ Cấu hình shell đã được kiểm tra/cập nhật tại $SHELL_CONFIG_FILE"
    echo "👉 Vui lòng khởi động lại terminal hoặc chạy lệnh sau để áp dụng thay đổi:"
    echo "   source $SHELL_CONFIG_FILE"
fi
