#!/usr/bin/env bash
set -e

PREFIX="$HOME/.local"
SRC="$HOME/src"
LIBZIP_VER="1.11.2" # bản mới nhất tính đến hiện tại

mkdir -p "$SRC"
cd "$SRC"

echo "📦 Downloading libzip $LIBZIP_VER..."
curl -L -o libzip-$LIBZIP_VER.tar.gz https://libzip.org/download/libzip-$LIBZIP_VER.tar.gz

echo "📂 Extracting..."
tar -xzf libzip-$LIBZIP_VER.tar.gz
cd libzip-$LIBZIP_VER

echo "⚙️ Configuring libzip..."
mkdir -p build && cd build

PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig" \
CFLAGS="-I$PREFIX/include" \
LDFLAGS="-L$PREFIX/lib" \
cmake .. \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DENABLE_GNUTLS=OFF \
  -DENABLE_MBEDTLS=OFF \
  -DENABLE_OPENSSL=ON \
  -DCMAKE_PREFIX_PATH=$PREFIX

echo "🧱 Building..."
make -j$(nproc)

echo "📥 Installing..."
make install

echo "✅ libzip $LIBZIP_VER installed to $PREFIX"
