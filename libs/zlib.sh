#!/bin/bash
# Script để build zlib từ source

set -e

# --- Các biến ---
ZLIB_VERSION="1.3.1"
SOURCE_DIR="$HOME/src"
INSTALL_PREFIX="$HOME/.local"

# --- Bắt đầu ---
echo "--- 🔍 Kiểm tra các công cụ build ---"
if ! command -v gcc &> /dev/null || ! command -v make &> /dev/null; then
    echo "❌ Lỗi: Vui lòng cài đặt 'build-essential'."
    exit 1
fi

echo "--- 🧱 Chuẩn bị môi trường cho Zlib ---"
mkdir -p "$SOURCE_DIR"
cd "$SOURCE_DIR"

echo "--- 🌐 Tải và giải nén Zlib $ZLIB_VERSION ---"
if [ ! -f "zlib-$ZLIB_VERSION.tar.gz" ]; then
    wget "https://www.zlib.net/zlib-$ZLIB_VERSION.tar.gz"
fi
rm -rf "zlib-$ZLIB_VERSION"
tar -xf "zlib-$ZLIB_VERSION.tar.gz"
cd "zlib-$ZLIB_VERSION"

echo "--- ⚙️  Cấu hình, Build và Cài đặt Zlib ---"
./configure --prefix="$INSTALL_PREFIX"
make -j$(nproc)
make install

echo ""
echo "✅ Cài đặt Zlib $ZLIB_VERSION thành công!"
