#!/usr/bin/env bash
set -e

# --- Cấu hình ---
SODIUM_VERSION="1.0.20"
SODIUM_URL="https://download.libsodium.org/libsodium/releases/libsodium-${SODIUM_VERSION}.tar.gz"
ARCHIVE_NAME=$(basename "$SODIUM_URL")
EXTRACTED_DIR="libsodium-${SODIUM_VERSION}"

# --- Đường dẫn ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"

# --- Chuẩn bị ---
echo "▶️  Chuẩn bị môi trường..."
mkdir -p "$PREFIX" "$SRC_DIR"
cd "$SRC_DIR"

# --- Tải mã nguồn ---
if [ ! -f "$ARCHIVE_NAME" ]; then
    echo "📥 Đang tải libsodium ${SODIUM_VERSION}..."
    wget -O "$ARCHIVE_NAME" "$SODIUM_URL"
else
    echo "☑️  Đã có file nén libsodium."
fi

# --- Giải nén ---
if [ ! -d "$EXTRACTED_DIR" ]; then
    echo "📦 Đang giải nén..."
    tar -xzf "$ARCHIVE_NAME"
else
    echo "☑️  Đã có thư mục mã nguồn libsodium."
fi

cd "$EXTRACTED_DIR"

# --- Build và cài đặt ---
echo "⚙️  Đang cấu hình libsodium..."
./configure --prefix="$PREFIX"

echo "🚀 Đang build và cài đặt libsodium..."
make -j"$(nproc)"
make install

echo ""
echo "✅ libsodium ${SODIUM_VERSION} đã được cài đặt vào $PREFIX"
