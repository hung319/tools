#!/usr/bin/env bash
set -e

# --- Cấu hình ---
JSON_REPO="https://github.com/nlohmann/json.git"
JSON_VERSION="v3.11.3"

# --- Đường dẫn ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src/nlohmann_json"

# --- Chuẩn bị ---
echo "▶️  Chuẩn bị môi trường..."
mkdir -p "$PREFIX"

# --- Tải mã nguồn ---
if [ ! -d "$SRC_DIR" ]; then
    echo "📥 Đang tải nlohmann_json..."
    git clone --depth=1 --branch "$JSON_VERSION" "$JSON_REPO" "$SRC_DIR"
else
    echo "☑️  Đã có thư mục mã nguồn nlohmann_json."
fi

cd "$SRC_DIR"

# --- Cài đặt (chỉ cần copy header) ---
echo "⚙️  Đang cài đặt nlohmann_json (header-only) với CMake..."
mkdir -p build
cd build
# CMAKE_INSTALL_PREFIX chỉ định nơi cài đặt header
cmake -DCMAKE_INSTALL_PREFIX="$PREFIX" ..
# 'make install' sẽ chỉ copy các file header cần thiết
make install

echo ""
echo "✅ nlohmann_json ${JSON_VERSION} đã được cài đặt vào $PREFIX/include"
