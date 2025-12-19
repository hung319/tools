#!/bin/bash

# Dừng script nếu gặp lỗi
set -e

# 1. Cấu hình đường dẫn
export PREFIX="$HOME/.local"
export PATH="$PREFIX/bin:$PATH"
export PKG_CONFIG_PATH="$PREFIX/lib/x86_64-linux-gnu/pkgconfig:$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig:$PKG_CONFIG_PATH"
export LD_LIBRARY_PATH="$PREFIX/lib/x86_64-linux-gnu:$PREFIX/lib:$LD_LIBRARY_PATH"

mkdir -p "$PREFIX/bin"
mkdir -p ~/cairo_standalone_build
cd ~/cairo_standalone_build

echo "--- 2. Kiểm tra Meson và Ninja ---"
# Nếu máy chưa có meson/ninja, cài qua pip (không cần root)
if ! command -v meson &> /dev/null || ! command -v ninja &> /dev/null; then
    echo "Không tìm thấy Meson/Ninja. Đang cài đặt qua pip..."
    pip install --user meson ninja
    export PATH="$HOME/.local/bin:$PATH"
fi

echo "--- 3. Tải và Cài đặt Pixman 0.46.4 ---"
curl -L https://www.cairographics.org/releases/pixman-0.46.4.tar.xz -o pixman.tar.xz
tar -xf pixman.tar.xz
cd pixman-0.46.4
# Cấu hình Pixman: tắt gtk và tests để tránh phụ thuộc phức tạp
meson setup builddir --prefix="$PREFIX" --buildtype=release -Dgtk=disabled -Dtests=disabled
ninja -C builddir
ninja -C builddir install
cd ..

echo "--- 4. Tải và Cài đặt Cairo 1.18.4 ---"
curl -L https://www.cairographics.org/releases/cairo-1.18.4.tar.xz -o cairo.tar.xz
tar -xf cairo.tar.xz
cd cairo-1.18.4

# Cấu hình Cairo:
# - Dùng các tùy chọn bạn cung cấp để tối giản các phụ thuộc hệ thống (X11, Fontconfig) 
# - Nếu bạn cần dùng font hoặc X11, hãy đổi 'disabled' thành 'auto'
meson setup builddir --prefix="$PREFIX" --buildtype=release \
    -Dtests=disabled \
    -Dglib=disabled \
    -Dfontconfig=disabled \
    -Dfreetype=disabled \
    -Dpng=enabled \
    -Dxcb=disabled \
    -Dxlib=disabled \
    -Dgtk_doc=false

ninja -C builddir
ninja -C builddir install

echo "--- HOÀN TẤT ---"
echo "Hãy thêm các dòng sau vào file ~/.bashrc để hệ thống nhận diện thư viện:"
echo "------------------------------------------------------------------"
echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
echo "export PKG_CONFIG_PATH=\"\$HOME/.local/lib/pkgconfig:\$HOME/.local/lib/x86_64-linux-gnu/pkgconfig:\$PKG_CONFIG_PATH\""
echo "export LD_LIBRARY_PATH=\"\$HOME/.local/lib:\$HOME/.local/lib/x86_64-linux-gnu:\$LD_LIBRARY_PATH\""
echo "------------------------------------------------------------------"
