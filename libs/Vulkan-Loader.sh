#!/bin/bash
set -e

# --- Các biến cấu hình ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
VER="v1.3.290" # Phải cùng phiên bản với Headers để tương thích

# --- Chuẩn bị thư mục ---
echo "--- 🧱 Bắt đầu build Vulkan-Loader bằng CMake ---"
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Tải mã nguồn từ Git ---
if [ -d "Vulkan-Loader" ]; then
    rm -rf Vulkan-Loader
fi
git clone --depth 1 --branch ${VER} https://github.com/KhronosGroup/Vulkan-Loader.git
cd Vulkan-Loader

# ==============================================================================
# THIẾT LẬP MÔI TRƯỜNG BUILD ĐẦY ĐỦ
# (Quan trọng để CMake tìm thấy Vulkan-Headers, Wayland, X11 libs...)
# ==============================================================================
export PATH="$PREFIX/bin:$PATH"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig:${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="$PREFIX/lib:${LD_LIBRARY_PATH:-}"
export CFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib"

# --- Cấu hình, Biên dịch và Cài đặt với CMake ---
echo "--- ⚙️  Cấu hình, biên dịch và cài đặt Vulkan-Loader ---"
rm -rf build

# 1. Cấu hình
cmake -S . -B build \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_WSI_WAYLAND_SUPPORT=ON \
    -DBUILD_WSI_XCB_SUPPORT=ON

# 2. Biên dịch
cmake --build build --parallel "$(nproc)"

# 3. Cài đặt
cmake --install build

echo ""
echo "✅ Build Vulkan-Loader ${VER} bằng CMake thành công!"
