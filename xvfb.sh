#!/bin/bash

# Script để build và cài đặt Xvfb cho người dùng non-root trên Debian 11
# PHIÊN BẢN HOÀN CHỈNH: Tự động kiểm tra dependency, sửa lỗi link, và cập nhật .bashrc thông minh.

# Dừng script nếu có lỗi xảy ra
set -e

# --- Phần 1: Thiết lập môi trường ---
echo "--- Thiết lập môi trường ---"

export SRC_DIR="$HOME/src"
export INSTALL_DIR="$HOME/.local"
mkdir -p "$SRC_DIR" "$INSTALL_DIR"

# Luôn đảm bảo PATH và các biến khác được cập nhật cho phiên chạy script này
export PATH="$HOME/.local/bin:$INSTALL_DIR/bin:$PATH"
export PKG_CONFIG_PATH="$INSTALL_DIR/lib/pkgconfig:$INSTALL_DIR/share/pkgconfig:$PKG_CONFIG_PATH"
export LD_LIBRARY_PATH="$INSTALL_DIR/lib:$LD_LIBRARY_PATH"
export ACLOCAL_PATH="$INSTALL_DIR/share/aclocal"
export CFLAGS="-I$INSTALL_DIR/include -I$INSTALL_DIR/include/freetype2 -I$INSTALL_DIR/include/libdrm"
export LDFLAGS="-L$INSTALL_DIR/lib"

# --- Cập nhật .bashrc một cách chi tiết ---
echo "--- Kiểm tra và cập nhật file .bashrc ---"
CONFIG_BLOCK_HEADER="# --- Cài đặt Xvfb tùy chỉnh ---"
NEEDS_HEADER=0

# Kiểm tra PATH
if ! grep -q "export PATH=\"$HOME/.local/bin:$INSTALL_DIR/bin:\$PATH\"" ~/.bashrc; then
    echo 'export PATH="'$HOME/.local/bin:$INSTALL_DIR/bin':$PATH"' >> ~/.bashrc
    echo "Đã thêm PATH vào .bashrc"
    NEEDS_HEADER=1
fi

# Kiểm tra PKG_CONFIG_PATH
if ! grep -q "export PKG_CONFIG_PATH=\"$INSTALL_DIR/lib/pkgconfig:$INSTALL_DIR/share/pkgconfig:\$PKG_CONFIG_PATH\"" ~/.bashrc; then
    echo 'export PKG_CONFIG_PATH="'$INSTALL_DIR/lib/pkgconfig:$INSTALL_DIR/share/pkgconfig':$PKG_CONFIG_PATH"' >> ~/.bashrc
    echo "Đã thêm PKG_CONFIG_PATH vào .bashrc"
    NEEDS_HEADER=1
fi

# Kiểm tra LD_LIBRARY_PATH
if ! grep -q "export LD_LIBRARY_PATH=\"$INSTALL_DIR/lib:\$LD_LIBRARY_PATH\"" ~/.bashrc; then
    echo 'export LD_LIBRARY_PATH="'$INSTALL_DIR/lib':$LD_LIBRARY_PATH"' >> ~/.bashrc
    echo "Đã thêm LD_LIBRARY_PATH vào .bashrc"
    NEEDS_HEADER=1
fi

# Kiểm tra CFLAGS
if ! grep -q "export CFLAGS=\"-I$INSTALL_DIR/include -I$INSTALL_DIR/include/freetype2 -I$INSTALL_DIR/include/libdrm\"" ~/.bashrc; then
    echo 'export CFLAGS="'"-I$INSTALL_DIR/include -I$INSTALL_DIR/include/freetype2 -I$INSTALL_DIR/include/libdrm"'"' >> ~/.bashrc
    echo "Đã thêm CFLAGS vào .bashrc"
    NEEDS_HEADER=1
fi

# Chỉ thêm dòng comment phân cách nếu có bất kỳ thay đổi nào và nó chưa tồn tại
if [ "$NEEDS_HEADER" -eq 1 ] && ! grep -q "$CONFIG_BLOCK_HEADER" ~/.bashrc; then
    echo -e "\n$CONFIG_BLOCK_HEADER\n# (Các dòng trên được thêm tự động bởi script build)" >> ~/.bashrc
fi

echo "--- Hoàn tất kiểm tra .bashrc ---"


# --- Phần 2: Cài đặt các công cụ build cơ bản ---
if ! command -v gcc &> /dev/null || ! command -v make &> /dev/null; then
    echo "LỖI: Vui lòng cài đặt các gói build cơ bản (build-essential) với quyền root." >&2; exit 1; fi
if ! command -v python3 &> /dev/null || ! command -v pip3 &> /dev/null; then
    echo "LỖI: Vui lòng cài đặt python3 và python3-pip với quyền root." >&2; exit 1; fi

if ! command -v meson &> /dev/null || ! command -v ninja &> /dev/null; then
    echo "--- Cài đặt Meson và Ninja bằng pip ---"; pip3 install --user meson ninja; fi
if ! command -v pkg-config &> /dev/null; then
    echo "pkg-config không tồn tại. Đang tiến hành build thủ công..."; cd "$SRC_DIR"
    wget https://pkgconfig.freedesktop.org/releases/pkg-config-0.29.2.tar.gz
    tar -xf pkg-config-0.29.2.tar.gz && cd pkg-config-0.29.2
    ./configure --prefix="$INSTALL_DIR" --with-internal-glib && make && make install; cd "$SRC_DIR"; fi

cd "$SRC_DIR"

# --- Phần 2.5: Build và cài đặt các dependency cơ bản ---
if ! command -v m4 &> /dev/null; then
    echo "--- Bắt đầu build GNU M4 ---"; wget -O m4-latest.tar.gz http://ftp.gnu.org/gnu/m4/m4-latest.tar.gz; tar -xf m4-latest.tar.gz && cd m4-*/ && ./configure --prefix="$INSTALL_DIR" && make && make install; cd "$SRC_DIR" && rm -rf m4-*/ m4-latest.tar.gz
else echo "Lệnh 'm4' đã tồn tại, bỏ qua."; fi

if ! command -v bison &> /dev/null; then
    echo "--- Bắt đầu build bison ---"; wget -O bison-latest.tar.gz https://ftp.gnu.org/gnu/bison/bison-3.8.tar.xz; tar -xf bison-latest.tar.gz && cd bison-*/ && ./configure --prefix="$INSTALL_DIR" && make && make install; cd "$SRC_DIR" && rm -rf bison-*/ bison-latest.tar.gz
else echo "Lệnh 'bison' đã tồn tại, bỏ qua."; fi

if ! command -v flex &> /dev/null; then
    echo "--- Bắt đầu build flex ---"; wget https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz -O flex-2.6.4.tar.gz; tar -xf flex-2.6.4.tar.gz && cd flex-2.6.4/ && ./configure --prefix="$INSTALL_DIR" && make && make install; cd "$SRC_DIR" && rm -rf flex-*/ flex-2.6.4.tar.gz
else echo "Lệnh 'flex' đã tồn tại, bỏ qua."; fi

if ! pkg-config --exists "zlib"; then
    echo "--- Bắt đầu build zlib ---"; wget https://www.zlib.net/zlib-1.3.1.tar.gz -O zlib-1.3.1.tar.gz; tar -xf zlib-1.3.1.tar.gz && cd zlib-1.3.1/ && ./configure --prefix="$INSTALL_DIR" && make && make install; cd "$SRC_DIR" && rm -rf zlib-1.3.1/ zlib-1.3.1.tar.gz
else echo "Thư viện 'zlib' đã tồn tại, bỏ qua."; fi

if ! pkg-config --exists "freetype2"; then
    echo "--- Bắt đầu build freetype ---"; wget https://download.savannah.gnu.org/releases/freetype/freetype-2.13.2.tar.gz -O freetype-2.13.2.tar.gz; tar -xf freetype-2.13.2.tar.gz && cd freetype-2.13.2/ && ./configure --prefix="$INSTALL_DIR" && make && make install; cd "$SRC_DIR" && rm -rf freetype-2.13.2/ freetype-2.13.2.tar.gz
else echo "Thư viện 'freetype2' đã tồn tại, bỏ qua."; fi

# --- Phần 3: Build và cài đặt các thư viện phụ thuộc của Xorg ---
echo "--- Bắt đầu build các thư viện X.Org ---"
cd "$SRC_DIR"
packages=(
    "util-macros-1.19.3 https://www.x.org/pub/individual/util/util-macros-1.19.3.tar.bz2 xorg-macros"
    "xorgproto-2021.5 https://www.x.org/pub/individual/proto/xorgproto-2021.5.tar.gz xproto"
    "libXau-1.0.9 https://www.x.org/pub/individual/lib/libXau-1.0.9.tar.bz2 xau"
    "libXdmcp-1.1.3 https://www.x.org/pub/individual/lib/libXdmcp-1.1.3.tar.bz2 xdmcp"
    "xcb-proto-1.14.1 https://xorg.freedesktop.org/archive/individual/xcb/xcb-proto-1.14.1.tar.gz xcb-proto"
    "libxcb-1.14 https://xorg.freedesktop.org/archive/individual/lib/libxcb-1.14.tar.gz xcb"
    "xtrans-1.4.0 https://www.x.org/pub/individual/lib/xtrans-1.4.0.tar.bz2 xtrans"
    "libpciaccess-0.17 https://www.x.org/archive/individual/lib/libpciaccess-0.17.tar.gz pciaccess"
    "libdrm-2.4.115 https://dri.freedesktop.org/libdrm/libdrm-2.4.115.tar.xz libdrm"
    "libX11-1.7.2 https://www.x.org/pub/individual/lib/libX11-1.7.2.tar.bz2 x11"
    "libfontenc-1.1.4 https://www.x.org/pub/individual/lib/libfontenc-1.1.4.tar.bz2 fontenc"
    "libxfont2-2.0.5 https://www.x.org/archive/individual/lib/libXfont2-2.0.5.tar.gz xfont2"
    "xkeyboard-config-2.33 https://www.x.org/pub/individual/data/xkeyboard-config/xkeyboard-config-2.33.tar.bz2 xkeyboard-config"
    "xkbcomp-1.4.5 https://www.x.org/pub/individual/app/xkbcomp-1.4.5.tar.bz2 xkbcomp"
)

for pkg_info in "${packages[@]}"; do
    pkg_name_ver=$(echo "$pkg_info" | awk '{print $1}'); pkg_url=$(echo "$pkg_info" | awk '{print $2}'); pkg_check_name=$(echo "$pkg_info" | awk '{print $3}')
    SHOULD_BUILD=1
    if [[ "$pkg_check_name" == "xkbcomp" ]]; then if command -v "$pkg_check_name" &> /dev/null; then SHOULD_BUILD=0; fi
    elif pkg-config --exists "$pkg_check_name"; then SHOULD_BUILD=0; fi
    if [ "$SHOULD_BUILD" -eq 0 ]; then echo "Thư viện/lệnh '$pkg_check_name' đã tồn tại, bỏ qua build $pkg_name_ver."; continue; fi
    echo "--- Bắt đầu build: $pkg_name_ver ---"
    pkg_filename=$(basename "$pkg_url")
    if [ ! -f "$pkg_filename" ]; then wget "$pkg_url"; fi
    pkg_dir=$(tar -tf "$pkg_filename" | head -1 | cut -f1 -d"/"); if [ -d "$pkg_dir" ]; then rm -rf "$pkg_dir"; fi
    tar -xf "$pkg_filename"; cd "$pkg_dir"
    
    if [[ "$pkg_check_name" == "xkeyboard-config" || "$pkg_check_name" == "libdrm" ]]; then
        meson setup --prefix="$INSTALL_DIR" --libdir=lib build && ninja -C build install
    else
        ./configure --prefix="$INSTALL_DIR" && make && make install
    fi
    
    cd "$SRC_DIR"; echo "--- Hoàn thành build: $pkg_name_ver ---"
done

# --- Phần 4: Build và cài đặt Xvfb (xorg-server) ---
if ! command -v Xvfb &> /dev/null; then
    echo "--- Bắt đầu build Xorg Server (Xvfb) ---"
    cd "$SRC_DIR"
    XORG_SERVER_VER="xorg-server-1.20.13"
    XORG_SERVER_URL="https://www.x.org/pub/individual/xserver/$XORG_SERVER_VER.tar.gz"
    XORG_SERVER_FILENAME=$(basename "$XORG_SERVER_URL")
    if [ ! -f "$XORG_SERVER_FILENAME" ]; then wget "$XORG_SERVER_URL"; fi
    XORG_DIR=$(tar -tf "$XORG_SERVER_FILENAME" | head -1 | cut -f1 -d"/")
    if [ -d "$XORG_DIR" ]; then rm -rf "$XORG_DIR"; fi
    tar -xf "$XORG_SERVER_FILENAME"; cd "$XORG_DIR"
    ./configure --prefix="$INSTALL_DIR" --enable-xvfb --disable-glamor --disable-glx --disable-dri --disable-dri2 --disable-dri3 --without-dtrace --disable-unit-tests --disable-xinerama --disable-xcsecurity --disable-xf86vidmode --disable-xnest --disable-xwayland --disable-libunwind
    make && make install
else
    echo "Lệnh 'Xvfb' đã tồn tại, bỏ qua build xorg-server."
fi

# --- Hoàn tất ---
cd "$HOME"
echo -e "\n--- ✅ HOÀN TẤT! ---\nXvfb đã được cài đặt vào: $INSTALL_DIR/bin/Xvfb\n"
echo "QUAN TRỌNG: Hãy chạy lệnh sau hoặc mở lại terminal để cập nhật môi trường:"
echo "source ~/.bashrc"
echo -e "\nSau đó, bạn có thể kiểm tra phiên bản Xvfb bằng lệnh:"
echo "Xvfb -version"
