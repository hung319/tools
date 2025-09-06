#!/usr/bin/env bash
set -e

# --- Cấu hình ---
LIBEDIT_VERSION="20240517-3.1"
LIBEDIT_URL="https://thrysoee.dk/editline/libedit-${LIBEDIT_VERSION}.tar.gz"
ARCHIVE_NAME=$(basename "$LIBEDIT_URL")
EXTRACTED_DIR="libedit-${LIBEDIT_VERSION}"

# --- Đường dẫn ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"

# --- Chuẩn bị ---
echo "▶️  Chuẩn bị môi trường..."
mkdir -p "$PREFIX" "$SRC_DIR"
cd "$SRC_DIR"

# --- Tải mã nguồn ---
if [ ! -f "$ARCHIVE_NAME" ]; then
    echo "📥 Đang tải libedit ${LIBEDIT_VERSION}..."
    wget -O "$ARCHIVE_NAME" "$LIBEDIT_URL"
else
    echo "☑️  Đã có file nén libedit."
fi

# --- Giải nén ---
if [ ! -d "$EXTRACTED_DIR" ]; then
    echo "📦 Đang giải nén..."
    tar -xzf "$ARCHIVE_NAME"
else
    echo "☑️  Đã có thư mục mã nguồn libedit."
fi

cd "$EXTRACTED_DIR"

# --- Build và cài đặt ---
echo "⚙️  Đang cấu hình libedit..."
./configure --prefix="$PREFIX"

echo "🚀 Đang build và cài đặt libedit..."
make -j"$(nproc)"
make install

echo ""
echo "✅ libedit ${LIBEDIT_VERSION} đã được cài đặt vào $PREFIX"
