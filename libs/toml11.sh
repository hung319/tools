#!/usr/bin/env bash
set -e

# --- Cấu hình ---
TOML11_VERSION="v3.8.0"
TOML11_REPO="https://github.com/ToruNiina/toml11.git"

# --- Đường dẫn ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src/toml11"

# --- Chuẩn bị ---
echo "▶️  Chuẩn bị môi trường..."
mkdir -p "$PREFIX"

# --- Tải mã nguồn ---
if [ ! -d "$SRC_DIR" ]; then
    echo "📥 Đang tải toml11 ${TOML11_VERSION}..."
    git clone --depth=1 --branch "$TOML11_VERSION" "$TOML11_REPO" "$SRC_DIR"
else
    echo "☑️  Đã có thư mục mã nguồn toml11."
fi

cd "$SRC_DIR"

# --- Build và cài đặt ---
echo "⚙️  Đang cài đặt toml11 với CMake..."
mkdir -p build
cd build

# SỬA LỖI: Thêm -DCMAKE_CXX_STANDARD=17 để chỉ định phiên bản C++
cmake -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_CXX_STANDARD=17 ..

# Thư viện header-only không cần `make -j`, chỉ cần `make install`
make install

echo ""
echo "✅ toml11 ${TOML11_VERSION} đã được cài đặt vào $PREFIX"
