#!/bin/bash
set -e

# --- Các biến cấu hình ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
WAYLAND_VER="1.23.0"
WAYLAND_URL="https://gitlab.freedesktop.org/wayland/wayland/-/releases/${WAYLAND_VER}/downloads/wayland-${WAYLAND_VER}.tar.xz"

# --- Chuẩn bị thư mục ---
echo "--- 🧱 Chuẩn bị thư mục ---"
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Tải và giải nén ---
echo "--- 🌐 Tải và giải nén Wayland ${WAYLAND_VER} ---"
if [ ! -f "wayland-${WAYLAND_VER}.tar.xz" ]; then
    curl -LO "$WAYLAND_URL"
fi

rm -rf "wayland-${WAYLAND_VER}"
tar -xf "wayland-${WAYLAND_VER}.tar.xz"
cd "wayland-${WAYLAND_VER}"

# ==============================================================================
# THIẾT LẬP MÔI TRƯỜNG BUILD ĐẦY ĐỦ
# ==============================================================================
echo "--- 🔩 Thiết lập môi trường build toàn diện ---"
export PATH="$PREFIX/bin:$PATH"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig:${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="$PREFIX/lib:${LD_LIBRARY_PATH:-}"
export CFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib"
# Thêm biến đặc biệt cho Wayland để nó biết nơi tìm các file protocol
export XDG_DATA_DIRS="$PREFIX/share:${XDG_DATA_DIRS:-/usr/local/share/:/usr/share/}"


# --- Kiểm tra các công cụ build cần thiết ---
echo "--- 🔍 Kiểm tra Meson và Ninja ---"
if ! command -v meson &> /dev/null || ! command -v ninja &> /dev/null; then
    echo "❌ Lỗi: Không tìm thấy 'meson' hoặc 'ninja'. Vui lòng cài đặt chúng trước."
    exit 1
fi

# --- Biên dịch và cài đặt với Meson ---
echo "--- ⚙️  Bắt đầu quá trình build Wayland ---"
rm -rf _build

meson setup _build --prefix="$PREFIX" -Dbuildtype=release -Ddocumentation=false

meson compile -C _build -j"$(nproc)"
meson install -C _build

echo ""
echo "✅ Wayland ${WAYLAND_VER} (bao gồm wayland-scanner) đã được cài đặt thành công vào $PREFIX"
