#!/bin/bash
# Script để tải và giải nén thủ công gói linux-libc-dev vào ~/.local

set -e

# --- Các biến cấu hình ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"

# ==============================================================================
# SỬA LỖI: Sử dụng chính xác URL MỚI NHẤT bạn đã cung cấp
# ==============================================================================
DEBIAN_MIRROR="http://ftp.de.debian.org/debian"
KHEADERS_VER="6.1.137-1"

# --- Bắt đầu ---
echo "--- 🧱 Chuẩn bị môi trường để cài đặt header thủ công ---"
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Xác định kiến trúc và URL ---
ARCH=$(uname -m)
PACKAGE_URL=""
PACKAGE_NAME=""

if [ "$ARCH" = "x86_64" ]; then
    echo "--- DETECTED ARCH: amd64 ---"
    PACKAGE_NAME="linux-libc-dev_${KHEADERS_VER}_amd64.deb"
    PACKAGE_URL="${DEBIAN_MIRROR}/pool/main/l/linux/linux-libc-dev_${KHEADERS_VER}_amd64.deb"
elif [ "$ARCH" = "aarch64" ]; then
    echo "--- DETECTED ARCH: arm64 ---"
    PACKAGE_NAME="linux-libc-dev_${KHEADERS_VER}_arm64.deb"
    PACKAGE_URL="${DEBIAN_MIRROR}/pool/main/l/linux/linux-libc-dev_${KHEADERS_VER}_arm64.deb"
else
    echo "❌ Lỗi: Kiến trúc không được hỗ trợ: $ARCH"
    exit 1
fi

# --- Tải gói .deb ---
echo "--- 🌐 Tải về ${PACKAGE_NAME} ---"
if [ ! -f "${PACKAGE_NAME}" ]; then
    curl -fLO "$PACKAGE_URL"
fi

# --- Giải nén gói .deb ---
echo "--- 📦 Giải nén gói .deb ---"
ar x "${PACKAGE_NAME}"

echo "--- 📁 Giải nén data.tar.xz ---"
tar -xf data.tar.xz

# --- Sao chép các header vào ~/.local/include ---
echo "--- 🚚 Sao chép các file header vào ${PREFIX}/include ---"
cp -rT usr/include/ "$PREFIX/include/"

# --- Dọn dẹp ---
echo "--- 🧹 Dọn dẹp các file tạm ---"
rm -f "${PACKAGE_NAME}" control.tar.xz data.tar.xz debian-binary
rm -rf usr/

echo ""
echo "✅ Các file header của Kernel đã được cài đặt thủ công vào ${PREFIX}/include!"
