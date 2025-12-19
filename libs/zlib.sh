#!/bin/bash
set -e

ZLIB_VERSION="1.3.1"
SOURCE_DIR="$HOME/src"
INSTALL_PREFIX="$HOME/.local"

echo "--- 🧱 Chuẩn bị môi trường cho Zlib ---"
mkdir -p "$SOURCE_DIR"
cd "$SOURCE_DIR"

echo "--- 🌐 Tải Zlib ---"
# Dùng -L để follow redirect nếu cần
curl -L "https://www.zlib.net/zlib-$ZLIB_VERSION.tar.gz" -o "zlib-$ZLIB_VERSION.tar.gz"
tar -xf "zlib-$ZLIB_VERSION.tar.gz"
cd "zlib-$ZLIB_VERSION"

echo "--- ⚙️ Cấu hình với -fPIC ---"
# ĐIỂM QUAN TRỌNG NHẤT: Thêm CFLAGS="-fPIC" trước ./configure
CFLAGS="-fPIC" ./configure --prefix="$INSTALL_PREFIX"

echo "--- 🛠️ Build và Cài đặt ---"
make -j$(nproc)
make install

echo "✅ Đã sửa xong Zlib với -fPIC!"
