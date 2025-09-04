#!/bin/bash
set -e

# --- Các biến cấu hình ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
SHADERC_GIT_URL="https://github.com/google/shaderc.git"

# --- Chuẩn bị thư mục ---
echo "--- 🧱 Bắt đầu build glslc (shaderc) ---"
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Tải mã nguồn từ Git ---
if [ -d "shaderc" ]; then
    rm -rf shaderc
fi
# Clone repository chính
echo "--- 🌐 Tải mã nguồn shaderc từ Git ---"
git clone --depth 1 "${SHADERC_GIT_URL}"
cd shaderc

# --- Tải các dependency của shaderc ---
echo "--- 📦 Tải các dependency (glslang, spirv-tools...) ---"
# Script này sẽ clone các repository cần thiết vào thư mục third_party
python3 utils/git-sync-deps

# ==============================================================================
# THIẾT LẬP MÔI TRƯỜNG BUILD ĐẦY ĐỦ
# ==============================================================================
export PATH="$PREFIX/bin:$PATH"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig:${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="$PREFIX/lib:${LD_LIBRARY_PATH:-}"
export CFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib"

# --- Cấu hình, Biên dịch và Cài đặt với CMake ---
echo "--- ⚙️  Cấu hình, biên dịch và cài đặt glslc ---"
rm -rf build
cmake -S . -B build \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_BUILD_TYPE=Release \
    -DSHADERC_SKIP_TESTS=ON

cmake --build build --parallel "$(nproc)"
cmake --install build

echo ""
echo "✅ Build glslc thành công!"
