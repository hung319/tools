#!/usr/bin/env bash
set -e

# --- Cấu hình ---
LIBGIT2_VERSION="v1.8.0" # Một phiên bản ổn định
LIBGIT2_REPO="https://github.com/libgit2/libgit2.git"

# --- Đường dẫn ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src/libgit2"

# --- Chuẩn bị ---
echo "▶️  Chuẩn bị môi trường..."
mkdir -p "$PREFIX"

# --- Tải mã nguồn ---
if [ ! -d "$SRC_DIR" ]; then
    echo "📥 Đang tải libgit2 ${LIBGIT2_VERSION}..."
    git clone --depth=1 --branch "$LIBGIT2_VERSION" "$LIBGIT2_REPO" "$SRC_DIR"
else
    echo "☑️  Đã có thư mục mã nguồn libgit2."
fi

cd "$SRC_DIR"

# --- Build và cài đặt ---
echo "⚙️  Đang build và cài đặt libgit2 với CMake..."
mkdir -p build
cd build
cmake -DCMAKE_INSTALL_PREFIX="$PREFIX" ..
make -j"$(nproc)"
make install

echo ""
echo "✅ libgit2 ${LIBGIT2_VERSION} đã được cài đặt vào $PREFIX"
