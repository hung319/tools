#!/bin/bash
set -e
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
VER="1.5.4"
URL="https://x.org/releases/individual/lib/libXrandr-${VER}.tar.xz"

echo "--- 🧱 Bắt đầu build libxrandr ---"
mkdir -p "$SRC_DIR"; cd "$SRC_DIR"
if [ ! -f "libXrandr-${VER}.tar.xz" ]; then curl -LO "$URL"; fi
rm -rf "libXrandr-${VER}"; tar -xf "libXrandr-${VER}.tar.xz"; cd "libXrandr-${VER}"

# Thiết lập môi trường
export PATH="$PREFIX/bin:$PATH"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig:${PKG_CONFIG_PATH:-}"
export CFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib"

# Build với Autotools
./configure --prefix="$PREFIX"
make -j"$(nproc)"; make install
echo "✅ Build libxrandr thành công!"
