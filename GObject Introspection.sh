#!/bin/bash

set -e

# --- Các biến ---
SOURCE_DIR="$HOME/src"
INSTALL_PREFIX="$HOME/.local"
GI_GIT_URL="https://gitlab.gnome.org/GNOME/gobject-introspection.git"

# ==============================================================================
# Thiết lập môi trường build
# ==============================================================================
echo "--- 🔩 Thiết lập môi trường build để sử dụng Python tùy chỉnh và các thư viện local ---"
export PATH="$HOME/.local/python/bin:$PATH"
export PKG_CONFIG_PATH="$INSTALL_PREFIX/lib/pkgconfig:$INSTALL_PREFIX/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH"
export LD_LIBRARY_PATH="$INSTALL_PREFIX/lib:$INSTALL_PREFIX/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"
export CFLAGS="-I$INSTALL_PREFIX/include"
export CPPFLAGS="-I$INSTALL_PREFIX/include"

# --- Bắt đầu build ---
echo "--- 🧱 Chuẩn bị thư mục cho GObject-Introspection ---"
mkdir -p "$SOURCE_DIR"
cd "$SOURCE_DIR"

# ==============================================================================
# Lấy mã nguồn từ Git
# ==============================================================================
echo "--- 🌐 Lấy mã nguồn GObject-Introspection mới nhất từ Git ---"
# Xóa thư mục cũ nếu tồn tại
if [ -d "gobject-introspection" ]; then
    echo "    -> Xóa thư mục mã nguồn cũ..."
    rm -rf gobject-introspection
fi

# Clone repository
if ! command -v git &> /dev/null; then
    echo "❌ Lỗi: Không tìm thấy lệnh 'git'. Vui lòng cài đặt Git trước."
    exit 1
fi
echo "    -> Đang clone từ ${GI_GIT_URL}..."
git clone "${GI_GIT_URL}"
cd gobject-introspection

echo "--- ⚙️  Cấu hình và Biên dịch với Meson/Ninja ---"
rm -rf build

# ==============================================================================
# SỬA LỖI: Thêm -Dtests=false để bỏ qua việc build bộ kiểm thử
# ==============================================================================
# Cấu hình build
meson setup build --prefix="$INSTALL_PREFIX" -Dtests=false

# Biên dịch
ninja -C build

echo "--- 🚀 Cài đặt ---"
ninja -C build install

echo ""
echo "✅ Cài đặt GObject Introspection từ Git thành công!"
