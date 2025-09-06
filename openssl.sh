#!/usr/bin/env bash
set -e

# --- Cấu hình ---
OPENSSL_VERSION="3.0.14" # Một phiên bản LTS (hỗ trợ lâu dài) ổn định
OPENSSL_URL="https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
ARCHIVE_NAME=$(basename "$OPENSSL_URL")
EXTRACTED_DIR="openssl-${OPENSSL_VERSION}"

# --- Đường dẫn ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"

# --- Chuẩn bị ---
echo "▶️  Chuẩn bị môi trường..."
mkdir -p "$PREFIX" "$SRC_DIR"
cd "$SRC_DIR"

# --- Tải mã nguồn ---
if [ ! -f "$ARCHIVE_NAME" ]; then
    echo "📥 Đang tải OpenSSL ${OPENSSL_VERSION}..."
    wget -O "$ARCHIVE_NAME" "$OPENSSL_URL"
else
    echo "☑️  Đã có file nén OpenSSL."
fi

# --- Giải nén ---
if [ ! -d "$EXTRACTED_DIR" ]; then
    echo "📦 Đang giải nén..."
    tar -xzf "$ARCHIVE_NAME"
else
    echo "☑️  Đã có thư mục mã nguồn OpenSSL."
fi

cd "$EXTRACTED_DIR"

# --- Build và cài đặt ---
# OpenSSL có hệ thống build riêng, không phải CMake hay configure chuẩn
echo "⚙️  Đang cấu hình OpenSSL..."
./config shared --prefix="$PREFIX" --openssldir="$PREFIX/ssl"

echo "🚀 Đang build và cài đặt OpenSSL (có thể mất một lúc)..."
make -j"$(nproc)"
make install

echo ""
echo "✅ OpenSSL ${OPENSSL_VERSION} (bao gồm libcrypto) đã được cài đặt vào $PREFIX"
