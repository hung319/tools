#!/bin/bash
set -e

# --- Các biến cấu hình ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
W_PROTOCOLS_VER="1.36"
W_PROTOCOLS_URL="https://gitlab.freedesktop.org/wayland/wayland-protocols/-/releases/${W_PROTOCOLS_VER}/downloads/wayland-protocols-${W_PROTOCOLS_VER}.tar.xz"

# --- Chuẩn bị thư mục ---
echo "--- 🧱 Chuẩn bị thư mục ---"
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Tải và giải nén ---
echo "--- 🌐 Tải và giải nén wayland-protocols ${W_PROTOCOLS_VER} ---"
if [ ! -f "wayland-protocols-${W_PROTOCOLS_VER}.tar.xz" ]; then
    curl -LO "$W_PROTOCOLS_URL"
fi

rm -rf "wayland-protocols-${W_PROTOCOLS_VER}"
tar -xf "wayland-protocols-${W_PROTOCOLS_VER}.tar.xz"
cd "wayland-protocols-${W_PROTOCOLS_VER}"

# ==============================================================================
# THIẾT LẬP MÔI TRƯỜNG BUILD ĐẦY ĐỦ
# ==============================================================================
echo "--- 🔩 Thiết lập môi trường build toàn diện ---"
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
echo "--- ⚙️  Bắt đầu quá trình build wayland-protocols ---"
rm -rf _build

meson setup _build --prefix="$PREFIX" -Dbuildtype=release

meson compile -C _build -j"$(nproc)"
meson install -C _build

echo ""
echo "✅ Wayland-protocols ${W_PROTOCOLS_VER} đã được cài đặt thành công vào $PREFIX"
