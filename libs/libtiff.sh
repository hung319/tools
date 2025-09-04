#!/bin/bash
set -e

# --- Các biến cấu hình ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
TIFF_VER="4.7.0"
TIFF_URL="https://download.osgeo.org/libtiff/tiff-${TIFF_VER}.tar.xz"

# --- Chuẩn bị thư mục ---
echo "--- 🧱 Chuẩn bị thư mục ---"
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Tải và giải nén ---
echo "--- 🌐 Tải và giải nén libtiff ${TIFF_VER} ---"
if [ ! -f "tiff-${TIFF_VER}.tar.xz" ]; then
    curl -LO "$TIFF_URL"
fi

rm -rf "tiff-${TIFF_VER}"
tar -xf "tiff-${TIFF_VER}.tar.xz"
cd "tiff-${TIFF_VER}"

# ==============================================================================
# THIẾT LẬP MÔI TRƯỜDNG BUILD ĐẦY ĐỦ
# (Để libtiff tìm thấy zlib và các thư viện khác trong ~/.local)
# ==============================================================================
echo "--- 🔩 Thiết lập môi trường build toàn diện ---"
export PATH="$PREFIX/bin:$PATH"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig:${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="$PREFIX/lib:${LD_LIBRARY_PATH:-}"
export CFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib"


# --- Biên dịch và cài đặt ---
echo "--- ⚙️  Bắt đầu quá trình build libtiff ---"

./configure --prefix="$PREFIX"

make -j"$(nproc)"
make install

echo ""
echo "✅ Libtiff ${TIFF_VER} đã được cài đặt thành công vào $PREFIX"
