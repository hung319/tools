#!/bin/bash
set -e

# --- Các biến cấu hình ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
VER="2.4.122"
URL="https://dri.freedesktop.org/libdrm/libdrm-${VER}.tar.xz"

# --- Chuẩn bị thư mục ---
echo "--- 🧱 Bắt đầu build libdrm ---"
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Tải và giải nén ---
if [ ! -f "libdrm-${VER}.tar.xz" ]; then
    curl -LO "$URL"
fi
rm -rf "libdrm-${VER}"
tar -xf "libdrm-${VER}.tar.xz"
cd "libdrm-${VER}"

# ==============================================================================
# THIẾT LẬP MÔI TRƯỜNG BUILD ĐẦY ĐỦ
# ==============================================================================
export PATH="$PREFIX/bin:$PATH"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig:${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="$PREFIX/lib:${LD_LIBRARY_PATH:-}"

# --- Kiểm tra các công cụ build cần thiết ---
echo "--- 🔍 Kiểm tra Meson và Ninja ---"
if ! command -v meson &> /dev/null || ! command -v ninja &> /dev/null; then
    echo "❌ Lỗi: Không tìm thấy 'meson' hoặc 'ninja'. Vui lòng cài đặt chúng trước."
    exit 1
fi

# --- Biên dịch và cài đặt với Meson ---
echo "--- ⚙️  Cấu hình, biên dịch và cài đặt libdrm ---"
rm -rf _build

meson setup _build --prefix="$PREFIX" -Dbuildtype=release

meson compile -C _build -j"$(nproc)"
meson install -C _build

echo ""
echo "✅ Build libdrm ${VER} thành công!"
