#!/bin/bash
set -e

# --- Các biến cấu hình ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
VER="v1.3.290" # Chọn một phiên bản ổn định, giống với Vulkan-Loader sau này

# --- Chuẩn bị thư mục ---
echo "--- 🧱 Bắt đầu build Vulkan-Headers bằng CMake ---"
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Tải mã nguồn từ Git ---
if [ -d "Vulkan-Headers" ]; then
    rm -rf Vulkan-Headers
fi
# Sử dụng --depth 1 để tải nhanh hơn
git clone --depth 1 --branch ${VER} https://github.com/KhronosGroup/Vulkan-Headers.git
cd Vulkan-Headers

# --- Cấu hình và Cài đặt với CMake ---
echo "--- ⚙️  Cấu hình và Cài đặt Vulkan-Headers ---"
rm -rf build

# 1. Cấu hình: Thêm -DCMAKE_INSTALL_PREFIX để chỉ định đường dẫn cài đặt
cmake -S . -B build -DCMAKE_INSTALL_PREFIX="$PREFIX"

# 2. Cài đặt: CMake sẽ tự động sử dụng PREFIX đã được cấu hình ở bước trên
cmake --install build

echo ""
echo "✅ Build Vulkan-Headers ${VER} bằng CMake thành công!"
