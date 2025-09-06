#!/usr/bin/env bash
set -e

# --- Cấu hình ---
CURL_VERSION="8.10.0" # Một phiên bản ổn định
CURL_URL="https://curl.se/download/curl-${CURL_VERSION}.tar.gz"
ARCHIVE_NAME=$(basename "$CURL_URL")
EXTRACTED_DIR="curl-${CURL_VERSION}"

# --- Đường dẫn ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"

# --- Chuẩn bị ---
echo "▶️  Chuẩn bị môi trường..."
mkdir -p "$PREFIX" "$SRC_DIR"
cd "$SRC_DIR"

# --- Tải mã nguồn ---
if [ ! -f "$ARCHIVE_NAME" ]; then
    echo "📥 Đang tải libcurl ${CURL_VERSION}..."
    wget -O "$ARCHIVE_NAME" "$CURL_URL"
else
    echo "☑️  Đã có file nén libcurl."
fi

# --- Giải nén ---
if [ ! -d "$EXTRACTED_DIR" ]; then
    echo "📦 Đang giải nén..."
    tar -xzf "$ARCHIVE_NAME"
else
    echo "☑️  Đã có thư mục mã nguồn libcurl."
fi

cd "$EXTRACTED_DIR"

# --- Build và cài đặt ---
echo "⚙️  Đang cấu hình libcurl..."
# Chúng ta build không cần SSL vì đã có OpenSSL riêng
./configure --prefix="$PREFIX" --with-openssl="$PREFIX"

echo "🚀 Đang build và cài đặt libcurl..."
make -j"$(nproc)"
make install

echo ""
echo "✅ libcurl ${CURL_VERSION} đã được cài đặt vào $PREFIX"
