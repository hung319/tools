#!/usr/bin/env bash
set -e

# ⚙️ Cấu hình
LIBZIP_VERSION="1.11.1"
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
LIBZIP_SRC_DIR="$SRC_DIR/libzip-${LIBZIP_VERSION}"
BUILD_DIR="$LIBZIP_SRC_DIR/build"
LIBZIP_URL="https://libzip.org/download/libzip-${LIBZIP_VERSION}.tar.gz"

# 🧹 Chuẩn bị
mkdir -p "$SRC_DIR" "$PREFIX"
cd "$SRC_DIR"

# 📦 Tải mã nguồn
if [ ! -f "libzip-${LIBZIP_VERSION}.tar.gz" ]; then
    echo "📥 Đang tải libzip ${LIBZIP_VERSION}..."
    wget -q "$LIBZIP_URL"
fi

# 🗜️ Giải nén
if [ ! -d "$LIBZIP_SRC_DIR" ]; then
    echo "📦 Giải nén mã nguồn..."
    tar -xzf "libzip-${LIBZIP_VERSION}.tar.gz"
fi

# 🏗️ Chuẩn bị build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# ⚙️ Thiết lập môi trường
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
export LD_LIBRARY_PATH="$PREFIX/lib:$LD_LIBRARY_PATH"
export CFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib"

# ⚙️ Cấu hình CMake (bỏ OpenSSL vì không cần cho libzip cơ bản)
cmake "$LIBZIP_SRC_DIR" \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_PREFIX_PATH="$PREFIX" \
  -DBUILD_SHARED_LIBS=ON \
  -DENABLE_OPENSSL=OFF \
  -DENABLE_BZIP2=OFF \
  -DENABLE_LZMA=ON \
  -DENABLE_ZSTD=OFF \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON

# 🚀 Build và cài đặt
make -j"$(nproc)"
make install

# ✅ Kiểm tra
echo ""
echo "✅ libzip ${LIBZIP_VERSION} đã được cài vào $PREFIX"
echo "📦 Kiểm tra với: pkg-config --modversion libzip"
