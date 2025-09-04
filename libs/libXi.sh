#!/bin/bash
set -e

# --- Các biến cấu hình ---
PREFIX="$HOME/.local"
# THAY ĐỔI 1: Đổi tên thư mục mã nguồn
SRC_DIR="$HOME/src"
VER="1.8.1"
URL="https://x.org/releases/individual/lib/libXi-${VER}.tar.xz"

# --- Chuẩn bị thư mục ---
echo "--- 🧱 Bắt đầu build libXi ---"
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Tải và giải nén ---
if [ ! -f "libXi-${VER}.tar.xz" ]; then
    curl -LO "$URL"
fi
rm -rf "libXi-${VER}"
tar -xf "libXi-${VER}.tar.xz"
cd "libXi-${VER}"

# ==============================================================================
# THIẾT LẬP MÔI TRƯỜNG BUILD ĐẦY ĐỦ
# ==============================================================================
export PATH="$PREFIX/bin:$PATH"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig:${PKG_CONFIG_PATH:-}"
export CFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib"

# --- Biên dịch và cài đặt ---
echo "--- ⚙️  Cấu hình, biên dịch và cài đặt libXi ---"

# THAY ĐỔI 2: Tạo thư mục 'build' và thực hiện build trong đó
mkdir -p build
cd build

# Chạy configure từ thư mục cha
../configure --prefix="$PREFIX"

# Chạy make và make install
make -j"$(nproc)"
make install

echo ""
echo "✅ Build libXi ${VER} thành công!"
