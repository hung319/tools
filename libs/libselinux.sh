#!/bin/bash
# Script để build libselinux từ source (phiên bản thử với biến LIBS)

set -e

# --- Các biến ---
LIBSELINUX_VERSION="3.6"
SOURCE_DIR="$HOME/src"
INSTALL_PREFIX="$HOME/.local"

# --- Bắt đầu ---
echo "--- 🔍 Kiểm tra các công cụ build ---"
if ! command -v gcc &> /dev/null || ! command -v make &> /dev/null; then
    echo "❌ Lỗi: Vui lòng cài đặt 'build-essential'."
    exit 1
fi

echo "--- 🧱 Chuẩn bị môi trường cho libselinux ---"
mkdir -p "$SOURCE_DIR" "$INSTALL_PREFIX/lib" "$INSTALL_PREFIX/include"
cd "$SOURCE_DIR"

echo "--- 🌐 Tải và giải nén libselinux $LIBSELINUX_VERSION ---"
if [ ! -f "libselinux-$LIBSELINUX_VERSION.tar.gz" ]; then
    wget "https://github.com/SELinuxProject/selinux/releases/download/$LIBSELINUX_VERSION/libselinux-$LIBSELINUX_VERSION.tar.gz"
fi
rm -rf "libselinux-$LIBSELINUX_VERSION"
tar -xf "libselinux-$LIBSELINUX_VERSION.tar.gz"
cd "libselinux-$LIBSELINUX_VERSION"

echo "--- ⚙️  Thiết lập môi trường và biên dịch ---"
# Giữ lại CFLAGS để trình biên dịch tìm header
export CFLAGS="-I$INSTALL_PREFIX/include"

# ==============================================================================
# SỬA LỖI LẦN NÀY: Dùng biến LIBS thay vì LDFLAGS
# ==============================================================================
# Một số Makefile bỏ qua LDFLAGS nhưng lại tuân theo biến LIBS để liên kết thư viện.
# Chúng ta truyền cả đường dẫn -L và cờ thư viện -l vào đây.
make -j$(nproc) LIBS="-L$INSTALL_PREFIX/lib -lpcre2-8"

echo "--- 🚀 Cài đặt vào thư mục tạm (staging) ---"
STAGE_DIR=$(mktemp -d)
make install DESTDIR="$STAGE_DIR" PREFIX="/usr"

echo "--- 🚚 Sao chép file từ thư mục tạm vào ~/.local ---"

if [ -d "$STAGE_DIR/lib/" ]; then
    cp -av "$STAGE_DIR/lib/"* "$INSTALL_PREFIX/lib/"
fi
if [ -d "$STAGE_DIR/usr/lib/" ]; then
    cp -av "$STAGE_DIR/usr/lib/"* "$INSTALL_PREFIX/lib/"
fi
if [ -d "$STAGE_DIR/usr/include/" ]; then
    cp -av "$STAGE_DIR/usr/include/"* "$INSTALL_PREFIX/include/"
fi

echo "--- 🧹 Dọn dẹp thư mục tạm ---"
rm -rf "$STAGE_DIR"

echo ""
echo "✅ Cài đặt libselinux $LIBSELINUX_VERSION thành công!"
