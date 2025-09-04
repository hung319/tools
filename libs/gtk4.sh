#!/bin/bash
set -e

# --- Các biến cấu hình ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
GTK4_VER="4.20.0"
GTK4_URL="https://download.gnome.org/sources/gtk/4.20/gtk-$GTK4_VER.tar.xz"

# --- Chuẩn bị thư mục ---
echo "--- 🧱 Chuẩn bị thư mục ---"
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Tải và giải nén ---
echo "--- 🌐 Tải và giải nén GTK4 ---"
if [ ! -f "gtk-$GTK4_VER.tar.xz" ]; then
    curl -LO "$GTK4_URL"
fi

rm -rf "gtk-$GTK4_VER"
tar -xf "gtk-$GTK4_VER.tar.xz"
cd "gtk-$GTK4_VER"

# ==============================================================================
# THIẾT LẬP MÔI TRƯỜNG BUILD ĐẦY ĐỦ
# ==============================================================================
echo "--- 🔩 Thiết lập môi trường build toàn diện ---"
export PATH="$PREFIX/bin:$PATH"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig:${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="$PREFIX/lib:${LD_LIBRARY_PATH:-}"
export CFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib"

# --- Biên dịch và cài đặt với Meson ---
echo "--- ⚙️  Bắt đầu quá trình build GTK4 ---"
rm -rf _build

# SỬA LỖI: Thêm -Dmedia-gstreamer=disabled để bỏ qua dependency GStreamer
meson setup _build --prefix="$PREFIX" \
    -Dintrospection=enabled \
    -Ddocumentation=false \
    -Dbuildtype=release \
    -Dmedia-gstreamer=disabled

meson compile -C _build -j"$(nproc)"
meson install -C _build

echo ""
echo "✅ GTK4 $GTK4_VER đã được cài đặt thành công vào $PREFIX"
