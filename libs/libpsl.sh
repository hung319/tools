#!/usr/bin/env bash
set -e

# --- Cấu hình ---
LIBPSL_VERSION="0.21.5"
LIBPSL_URL="https://github.com/rockdaboot/libpsl/releases/download/${LIBPSL_VERSION}/libpsl-${LIBPSL_VERSION}.tar.gz"
ARCHIVE_NAME=$(basename "$LIBPSL_URL")
EXTRACTED_DIR="libpsl-${LIBPSL_VERSION}"

# --- Đường dẫn ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"

# --- Chuẩn bị ---
echo "▶️  Chuẩn bị môi trường..."
mkdir -p "$PREFIX" "$SRC_DIR"
cd "$SRC_DIR"

# --- Tải mã nguồn ---
if [ ! -f "$ARCHIVE_NAME" ]; then
    echo "📥 Đang tải libpsl ${LIBPSL_VERSION}..."
    wget -O "$ARCHIVE_NAME" "$LIBPSL_URL"
else
    echo "☑️  Đã có file nén libpsl."
fi

# --- Giải nén ---
if [ ! -d "$EXTRACTED_DIR" ]; then
    echo "📦 Đang giải nén..."
    tar -xzf "$ARCHIVE_NAME"
else
    echo "☑️  Đã có thư mục mã nguồn libpsl."
fi

cd "$EXTRACTED_DIR"

# --- Build và cài đặt ---
echo "⚙️  Đang cấu hình libpsl..."
./configure --prefix="$PREFIX"

echo "🚀 Đang build và cài đặt libpsl..."
make -j"$(nproc)"
make install

echo ""
echo "✅ libpsl ${LIBPSL_VERSION} đã được cài đặt vào $PREFIX"
