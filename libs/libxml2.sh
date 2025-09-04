#!/bin/bash
set -e

# --- Các biến cấu hình ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
LIBXML2_VER="2.13.4"
LIBXML2_URL="https://download.gnome.org/sources/libxml2/2.13/libxml2-${LIBXML2_VER}.tar.xz"

# --- Chuẩn bị thư mục ---
echo "--- 🧱 Chuẩn bị thư mục ---"
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Tải và giải nén ---
echo "--- 🌐 Tải và giải nén libxml2 ${LIBXML2_VER} ---"
if [ ! -f "libxml2-${LIBXML2_VER}.tar.xz" ]; then
    curl -LO "$LIBXML2_URL"
fi

rm -rf "libxml2-${LIBXML2_VER}"
tar -xf "libxml2-${LIBXML2_VER}.tar.xz"
cd "libxml2-${LIBXML2_VER}"

# ==============================================================================
# THIẾT LẬP MÔI TRƯỜNG BUILD ĐẦY ĐỦ
# (Để tìm thấy zlib, xz, và các thư viện khác trong ~/.local)
# ==============================================================================
echo "--- 🔩 Thiết lập môi trường build toàn diện ---"
export PATH="$PREFIX/bin:$PATH"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig:${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="$PREFIX/lib:${LD_LIBRARY_PATH:-}"
export CFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib"

# --- Biên dịch và cài đặt ---
echo "--- ⚙️  Bắt đầu quá trình build libxml2 ---"

# --with-python=no để đơn giản hóa quá trình build, không cần thiết cho các dependency của GTK
./configure --prefix="$PREFIX" --with-python=no

make -j"$(nproc)"
make install

echo ""
echo "✅ Libxml2 ${LIBXML2_VER} đã được cài đặt thành công vào $PREFIX"
