#!/usr/bin/env bash
set -e

# --- Cấu hình ---
OPENSSL_VERSION="3.5.4"
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
echo "⚙️  Đang cấu hình OpenSSL..."
./config shared --prefix="$PREFIX" --openssldir="$PREFIX/ssl"

echo "🚀 Đang build và cài đặt OpenSSL..."
make -j"$(nproc)"
make install

# --- Tạo file pkg-config (openssl.pc) nếu thiếu ---
PKGCONFIG_DIR="$PREFIX/lib/pkgconfig"
mkdir -p "$PKGCONFIG_DIR"
OPENSSL_PC="$PKGCONFIG_DIR/openssl.pc"

if [ ! -f "$OPENSSL_PC" ]; then
    echo "🧩 Đang tạo file openssl.pc để hỗ trợ pkg-config..."
    cat > "$OPENSSL_PC" <<EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: OpenSSL
Description: Secure Sockets Layer and cryptography libraries
Version: ${OPENSSL_VERSION}
Libs: -L\${libdir} -lssl -lcrypto
Cflags: -I\${includedir}
EOF
    echo "✅ Đã tạo file $OPENSSL_PC"
else
    echo "☑️  Đã có file openssl.pc."
fi

# --- Hoàn tất ---
echo ""
echo "✅ OpenSSL ${OPENSSL_VERSION} (bao gồm libcrypto) đã được cài đặt vào $PREFIX"
echo "Bạn có thể kiểm tra bằng:"
echo "PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig pkg-config --libs --cflags openssl"
