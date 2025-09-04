#!/bin/bash
set -e

# --- Các biến cấu hình ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
MESA_VER="24.1.7" # Chọn phiên bản ổn định mới nhất
MESA_URL="https://archive.mesa3d.org/mesa-${MESA_VER}.tar.xz"

# --- Chuẩn bị thư mục ---
echo "--- 🧱 Bắt đầu build Mesa 3D ---"
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Tải và giải nén ---
if [ ! -f "mesa-${MESA_VER}.tar.xz" ]; then
    curl -LO "$MESA_URL"
fi
rm -rf "mesa-${MESA_VER}"
tar -xf "mesa-${MESA_VER}.tar.xz"
cd "mesa-${MESA_VER}"

# ==============================================================================
# THIẾT LẬP MÔI TRƯỜNG BUILD ĐẦY ĐỦ
# ==============================================================================
export PATH="$PREFIX/bin:$PATH"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig:${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="$PREFIX/lib:${LD_LIBRARY_PATH:-}"
export CFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib"

# --- Biên dịch và cài đặt với Meson ---
echo "--- ⚙️  Cấu hình, biên dịch và cài đặt Mesa ---"
rm -rf _build

# SỬA LỖI: Đổi giá trị của glx từ 'enabled' thành 'dri'
meson setup _build --prefix="$PREFIX" \
    -Dbuildtype=release \
    -Dplatforms=x11,wayland \
    -Dglx=dri \
    -Degl=enabled \
    -Dopengl=true \
    -Dgles2=true \
    -Dgallium-drivers=swrast \
    -Dvulkan-drivers=[] # Tắt Vulkan drivers để build nhanh hơn và ít lỗi hơn

meson compile -C _build -j"$(nproc)"
meson install -C _build

echo ""
echo "✅ Build Mesa ${MESA_VER} thành công!"
