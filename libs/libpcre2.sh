#!/bin/bash
# Script để build PCRE2 từ source

set -e

# --- Các biến ---
PCRE2_VERSION="10.44"
SOURCE_DIR="$HOME/src"
INSTALL_PREFIX="$HOME/.local"

# --- Bắt đầu ---
echo "--- 🔍 Kiểm tra các công cụ build ---"
if ! command -v gcc &> /dev/null || ! command -v make &> /dev/null; then
    echo "❌ Lỗi: Vui lòng cài đặt 'build-essential'."
    exit 1
fi

echo "--- 🧱 Chuẩn bị môi trường cho PCRE2 ---"
mkdir -p "$SOURCE_DIR"
cd "$SOURCE_DIR"

echo "--- 🌐 Tải và giải nén PCRE2 $PCRE2_VERSION ---"
if [ ! -f "pcre2-$PCRE2_VERSION.tar.gz" ]; then
    wget "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-$PCRE2_VERSION/pcre2-$PCRE2_VERSION.tar.gz"
fi
rm -rf "pcre2-$PCRE2_VERSION"
tar -xf "pcre2-$PCRE2_VERSION.tar.gz"
cd "pcre2-$PCRE2_VERSION"

echo "--- ⚙️  Cấu hình, Build và Cài đặt PCRE2 ---"
./configure --prefix="$INSTALL_PREFIX"
make -j$(nproc)
make install

echo ""
echo "✅ Cài đặt PCRE2 $PCRE2_VERSION thành công!"
