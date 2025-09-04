#!/bin/bash
set -e

# --- Các biến cấu hình ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
VER="6.0.1"
URL="https://x.org/releases/individual/lib/libXfixes-${VER}.tar.xz"

# --- Chuẩn bị thư mục ---
echo "--- 🧱 Bắt đầu build libXfixes ---"
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Tải và giải nén ---
if [ ! -f "libXfixes-${VER}.tar.xz" ]; then
    curl -LO "$URL"
fi
rm -rf "libXfixes-${VER}"
tar -xf "libXfixes-${VER}.tar.xz"
cd "libXfixes-${VER}"

# ==============================================================================
# THIẾT LẬP MÔI TRƯỜNG BUILD ĐẦY ĐỦ
# (Quan trọng để tìm thấy libX11 và xorgproto đã build trước đó)
# ==============================================================================
export PATH="$PREFIX/bin:$PATH"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig:${PKG_CONFIG_PATH:-}"
export CFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib"

# --- Biên dịch và cài đặt ---
echo "--- ⚙️  Cấu hình, biên dịch và cài đặt libXfixes ---"

# Tạo thư mục 'build' và thực hiện build trong đó
mkdir -p build
cd build

# Chạy configure từ thư mục cha
../configure --prefix="$PREFIX"

# Chạy make và make install
make -j"$(nproc)"
make install

echo ""
echo "✅ Build libXfixes ${VER} thành công!"
