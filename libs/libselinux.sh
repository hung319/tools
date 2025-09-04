#!/bin/bash
# Script hoàn chỉnh để build libselinux, tự động dọn dẹp file cũ

set -e

# --- Các biến ---
LIBSELINUX_VERSION="3.6"
SOURCE_DIR="$HOME/src"
INSTALL_PREFIX="$HOME/.local"

# ==============================================================================
# BƯỚC AN TOÀN: Tự động xóa các file libselinux cũ để tránh lỗi
# ==============================================================================
echo "--- 🧹 Dọn dẹp các file libselinux cũ (nếu có) ---"
rm -f "$INSTALL_PREFIX/lib/libselinux."*
rm -rf "$INSTALL_PREFIX/include/selinux"
echo "--- ✅ Dọn dẹp xong ---"


# --- Bắt đầu ---
echo "--- 🧱 Chuẩn bị môi trường cho libselinux ---"
mkdir -p "$SRC_DIR" "$INSTALL_PREFIX/lib" "$INSTALL_PREFIX/include"
cd "$SRC_DIR"

echo "--- 🌐 Tải và giải nén libselinux ---"
if [ ! -f "libselinux-$LIBSELINUX_VERSION.tar.gz" ]; then
    wget "https://github.com/SELinuxProject/selinux/releases/download/$LIBSELINUX_VERSION/libselinux-$LIBSELINUX_VERSION.tar.gz"
fi
rm -rf "libselinux-$LIBSELINUX_VERSION"
tar -xf "libselinux-$LIBSELINUX_VERSION.tar.gz"
cd "libselinux-$LIBSELINUX_VERSION"

# --- Thiết lập môi trường và biên dịch ---
echo "--- ⚙️  Thiết lập môi trường và biên dịch ---"
export CFLAGS="-I$INSTALL_PREFIX/include -fPIC"
make -j$(nproc) LIBS="-L$INSTALL_PREFIX/lib -lpcre2-8"

# --- Cài đặt (Staging Install) ---
echo "--- 🚀 Cài đặt vào thư mục tạm ---"
STAGE_DIR=$(mktemp -d)
make install DESTDIR="$STAGE_DIR" PREFIX="/usr"

echo "--- 🚚 Sao chép file vào ~/.local ---"
if [ -d "$STAGE_DIR/lib/" ]; then cp -av "$STAGE_DIR/lib/"* "$INSTALL_PREFIX/lib/"; fi
if [ -d "$STAGE_DIR/usr/lib/" ]; then cp -av "$STAGE_DIR/usr/lib/"* "$INSTALL_PREFIX/lib/"; fi
if [ -d "$STAGE_DIR/usr/include/" ]; then cp -av "$STAGE_DIR/usr/include/"* "$INSTALL_PREFIX/include/"; fi
rm -rf "$STAGE_DIR"

echo ""
echo "✅ Cài đặt libselinux $LIBSELINUX_VERSION thành công!"
