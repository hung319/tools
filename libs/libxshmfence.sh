#!/bin/bash
set -e

# --- Các biến cấu hình ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
VER="1.4"
URL="https://x.org/releases/individual/lib/libxshmfence-${VER}.tar.gz"

# --- Chuẩn bị thư mục ---
echo "--- 🧱 Bắt đầu build libxshmfence ---"
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Tải và giải nén ---
if [ ! -f "libxshmfence-${VER}.tar.gz" ]; then
    curl -LO "$URL"
fi
rm -rf "libxshmfence-${VER}"
tar -xf "libxshmfence-${VER}.tar.gz"
cd "libxshmfence-${VER}"

# ==============================================================================
# THIẾT LẬP MÔI TRƯỜNG BUILD ĐẦY ĐỦ
# (Quan trọng để tìm thấy xorgproto đã build trước đó)
# ==============================================================================
export PATH="$PREFIX/bin:$PATH"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig:${PKG_CONFIG_PATH:-}"
export CFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib"

# --- Biên dịch và cài đặt ---
echo "--- ⚙️  Cấu hình, biên dịch và cài đặt libxshmfence ---"

# Tạo thư mục 'build' và thực hiện build trong đó
mkdir -p build
cd build

# Chạy configure từ thư mục cha
../configure --prefix="$PREFIX"

# Chạy make và make install
make -j"$(nproc)"
make install

echo ""
echo "✅ Build libxshmfence ${VER} thành công!"
