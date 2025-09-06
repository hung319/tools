#!/usr/bin/env bash
set -e

# --- Cấu hình ---
BDWGC_VERSION="v8.2.6"
BDWGC_REPO="https://github.com/ivmai/bdwgc.git"

# --- Đường dẫn ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src/bdwgc"

# --- Chuẩn bị ---
echo "▶️  Chuẩn bị môi trường..."
mkdir -p "$PREFIX"

# --- Tải mã nguồn ---
if [ ! -d "$SRC_DIR" ]; then
    echo "📥 Đang tải bdw-gc ${BDWGC_VERSION}..."
    git clone --depth=1 --branch "$BDWGC_VERSION" "$BDWGC_REPO" "$SRC_DIR"
else
    echo "☑️  Đã có thư mục mã nguồn bdw-gc."
fi

cd "$SRC_DIR"

# --- Build và cài đặt ---
echo "⚙️  Đang build và cài đặt bdw-gc..."
./autogen.sh
./configure --prefix="$PREFIX"
make -j"$(nproc)"
make install

echo ""
echo "✅ bdw-gc ${BDWGC_VERSION} đã được cài đặt vào $PREFIX"
