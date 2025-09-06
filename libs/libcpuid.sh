#!/usr/bin/env bash
set -e

# --- Cấu hình ---
LIBCPUID_REPO="https://github.com/anrieff/libcpuid.git"
LIBCPUID_VERSION="v0.6.5" # Một phiên bản ổn định

# --- Đường dẫn ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src/libcpuid"

# --- Chuẩn bị ---
echo "▶️  Chuẩn bị môi trường..."
mkdir -p "$PREFIX"

# --- Tải mã nguồn ---
if [ ! -d "$SRC_DIR" ]; then
    echo "📥 Đang tải libcpuid..."
    git clone --depth=1 --branch "$LIBCPUID_VERSION" "$LIBCPUID_REPO" "$SRC_DIR"
else
    echo "☑️  Đã có thư mục mã nguồn libcpuid."
fi

cd "$SRC_DIR"

# --- Build và cài đặt ---
echo "⚙️  Đang build và cài đặt libcpuid với CMake..."
mkdir -p build
cd build
cmake -DCMAKE_INSTALL_PREFIX="$PREFIX" ..
make -j"$(nproc)"
make install

echo ""
echo "✅ libcpuid ${LIBCPUID_VERSION} đã được cài đặt vào $PREFIX"
