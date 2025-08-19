#!/bin/bash

# Dừng script nếu có lỗi
set -e

# --- CÁC BIẾN VÀ THƯ MỤC ---
SRC_DIR="$HOME/src"
INSTALL_DIR="$HOME/.local"
NUM_CORES=$(nproc)

# --- BƯỚC 0A: KIỂM TRA CÁC CÔNG CỤ BUILD CỐT LÕI ---
echo "🔎 Kiểm tra các công cụ build cốt lõi (gcc, make, wget)..."
CORE_COMMANDS="wget gcc make"
for CMD in $CORE_COMMANDS; do
    if ! command -v "$CMD" &> /dev/null; then
        echo "❌ Lỗi: Không tìm thấy lệnh '$CMD'."
        echo "Đây là công cụ nền tảng. Vui lòng cài đặt chúng."
        echo "Trên Debian/Ubuntu, bạn có thể chạy: sudo apt update && sudo apt install build-essential wget"
        exit 1
    fi
done
echo "✅ Các công cụ cốt lõi đã có sẵn."

# --- THIẾT LẬP BIẾN MÔI TRƯỜNG (quan trọng cho các bước tiếp theo) ---
mkdir -p "$INSTALL_DIR/bin"
export PATH="$INSTALL_DIR/bin:$PATH"
export LD_LIBRARY_PATH="$INSTALL_DIR/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="$INSTALL_DIR/lib/pkgconfig:$INSTALL_DIR/share/pkgconfig:$PKG_CONFIG_PATH"
export CPPFLAGS="-I$INSTALL_DIR/include"
export CFLAGS="-I$INSTALL_DIR/include"
export LDFLAGS="-L$INSTALL_DIR/lib"

# --- BƯỚC 0B: BUILD CÁC CÔNG CỤ AUTOTOOLS NẾU CẦN ---
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if ! command -v pkg-config &> /dev/null; then
    echo "🛠️  pkg-config không tồn tại. Đang build từ mã nguồn..."
    wget "https://pkgconfig.freedesktop.org/releases/pkg-config-0.29.2.tar.gz"
    tar -xvf pkg-config-0.29.2.tar.gz && cd pkg-config-0.29.2
    ./configure --prefix="$INSTALL_DIR" --with-internal-glib && make -j"$NUM_CORES" install
    cd "$SRC_DIR" && rm -rf pkg-config-0.29.2*
fi

if ! command -v autoconf &> /dev/null; then
    echo "🛠️  autoconf không tồn tại. Đang build từ mã nguồn..."
    wget "https://ftp.gnu.org/gnu/m4/m4-1.4.19.tar.gz"
    tar -xvf m4-1.4.19.tar.gz && cd m4-1.4.19
    ./configure --prefix="$INSTALL_DIR" && make -j"$NUM_CORES" install
    cd "$SRC_DIR" && rm -rf m4-1.4.19*
    
    wget "https://ftp.gnu.org/gnu/autoconf/autoconf-2.71.tar.gz"
    tar -xvf autoconf-2.71.tar.gz && cd autoconf-2.71
    ./configure --prefix="$INSTALL_DIR" && make -j"$NUM_CORES" install
    cd "$SRC_DIR" && rm -rf autoconf-2.71*
fi

if ! command -v automake &> /dev/null; then
    echo "🛠️  automake không tồn tại. Đang build từ mã nguồn..."
    wget "https://ftp.gnu.org/gnu/automake/automake-1.16.5.tar.gz"
    tar -xvf automake-1.16.5.tar.gz && cd automake-1.16.5
    ./configure --prefix="$INSTALL_DIR" && make -j"$NUM_CORES" install
    cd "$SRC_DIR" && rm -rf automake-1.16.5*
fi

if ! command -v libtool &> /dev/null; then
    echo "🛠️  libtool không tồn tại. Đang build từ mã nguồn..."
    wget "https://ftp.gnu.org/gnu/libtool/libtool-2.4.7.tar.gz"
    tar -xvf libtool-2.4.7.tar.gz && cd libtool-2.4.7
    ./configure --prefix="$INSTALL_DIR" && make -j"$NUM_CORES" install
    cd "$SRC_DIR" && rm -rf libtool-2.4.7*
fi

echo "✅ Tất cả các công cụ build đã sẵn sàng."
echo "🚀 Bắt đầu quá trình build scrot và các phụ thuộc."

# --- BUILD CÁC THƯ VIỆN PHỤ THUỘC (Bỏ qua nếu đã có) ---
# ... (Toàn bộ các bước từ 1 đến 11 được giữ nguyên) ...

# 1. xorg-macros
if [ ! -f "$INSTALL_DIR/share/pkgconfig/xorg-macros.pc" ]; then
    echo "🛠️  Đang build xorg-macros..."
    wget "https://www.x.org/archive/individual/util/util-macros-1.19.3.tar.bz2"
    tar -xvf util-macros-1.19.3.tar.bz2 && cd util-macros-1.19.3
    ./configure --prefix="$INSTALL_DIR" && make -j"$NUM_CORES" install
    cd "$SRC_DIR" && rm -rf util-macros-1.19.3*
fi

# 2. libX11
if [ ! -f "$INSTALL_DIR/lib/pkgconfig/x11.pc" ]; then
    echo "🛠️  Đang build libX11..."
    wget "https://www.x.org/archive/individual/lib/libX11-1.8.7.tar.gz"
    tar -xvf libX11-1.8.7.tar.gz && cd libX11-1.8.7
    ./configure --prefix="$INSTALL_DIR" && make -j"$NUM_CORES" install
    cd "$SRC_DIR" && rm -rf libX11-1.8.7*
fi

# 3. zlib
if [ ! -f "$INSTALL_DIR/include/zlib.h" ]; then
    echo "🛠️  Đang build zlib..."
    wget "https://zlib.net/zlib-1.3.1.tar.gz"
    tar -xvf zlib-1.3.1.tar.gz && cd zlib-1.3.1
    ./configure --prefix="$INSTALL_DIR" && make -j"$NUM_CORES" install
    cd "$SRC_DIR" && rm -rf zlib-1.3.1*
fi

# 4. libjpeg-turbo
if [ ! -f "$INSTALL_DIR/include/jpeglib.h" ]; then
    echo "🛠️  Đang build libjpeg-turbo..."
    wget "https://github.com/libjpeg-turbo/libjpeg-turbo/archive/refs/tags/3.0.3.tar.gz" -O libjpeg-turbo.tar.gz
    tar -xvf libjpeg-turbo.tar.gz && cd libjpeg-turbo-3.0.3
    cmake -G"Unix Makefiles" -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR . && make -j"$NUM_CORES" install
    cd "$SRC_DIR" && rm -rf libjpeg-turbo-3.0.3* libjpeg-turbo.tar.gz
fi

# 5. libpng
if [ ! -f "$INSTALL_DIR/include/png.h" ]; then
    echo "🛠️  Đang build libpng..."
    wget "https://download.sourceforge.net/libpng/libpng-1.6.43.tar.gz"
    tar -xvf libpng-1.6.43.tar.gz && cd libpng-1.6.43
    ./configure --prefix="$INSTALL_DIR" && make -j"$NUM_CORES" install
    cd "$SRC_DIR" && rm -rf libpng-1.6.43*
fi

# 6. imlib2
if [ ! -f "$INSTALL_DIR/lib/pkgconfig/imlib2.pc" ]; then
    echo "🛠️  Đang build imlib2..."
    wget "https://downloads.sourceforge.net/project/enlightenment/imlib2-src/1.12.2/imlib2-1.12.2.tar.gz"
    tar -xvf imlib2-1.12.2.tar.gz && cd imlib2-1.12.2
    ./configure --prefix="$INSTALL_DIR" && make -j"$NUM_CORES" install
    cd "$SRC_DIR" && rm -rf imlib2-1.12.2*
fi

# 7. Tạo file imlib2-config giả
if [ ! -x "$INSTALL_DIR/bin/imlib2-config" ]; then
    echo "✨ Tạo file imlib2-config giả để tương thích..."
    cat > "$INSTALL_DIR/bin/imlib2-config" <<'EOF'
#!/bin/sh
if [ "$1" = "--cflags" ]; then
    pkg-config --cflags imlib2
elif [ "$1" = "--libs" ]; then
    pkg-config --libs imlib2
fi
EOF
    chmod +x "$INSTALL_DIR/bin/imlib2-config"
fi

# 8. giblib
if [ ! -f "$INSTALL_DIR/include/giblib/giblib.h" ]; then
    echo "🛠️  Đang build giblib..."
    wget "https://snapshot.debian.org/archive/debian/20120115T043232Z/pool/main/g/giblib/giblib_1.2.4.orig.tar.gz"
    tar -xvf giblib_1.2.4.orig.tar.gz && cd giblib-1.2.4.orig
    ./configure --prefix="$INSTALL_DIR" && make -j"$NUM_CORES" install
    cd "$SRC_DIR" && rm -rf giblib-1.2.4.orig*
fi

# 9. libmd (phụ thuộc của libbsd)
if [ ! -f "$INSTALL_DIR/lib/pkgconfig/libmd.pc" ]; then
    echo "🛠️  Đang build libmd (MD5 functions)..."
    wget "https://libbsd.freedesktop.org/releases/libmd-1.1.0.tar.xz"
    tar -xvf libmd-1.1.0.tar.xz && cd libmd-1.1.0
    ./configure --prefix="$INSTALL_DIR" && make -j"$NUM_CORES" install
    cd "$SRC_DIR" && rm -rf libmd-1.1.0*
fi

# 10. libbsd
if [ ! -f "$INSTALL_DIR/lib/pkgconfig/libbsd.pc" ]; then
    echo "🛠️  Đang build libbsd..."
    wget "https://libbsd.freedesktop.org/releases/libbsd-0.11.7.tar.xz"
    tar -xvf libbsd-0.11.7.tar.xz && cd libbsd-0.11.7
    ./configure --prefix="$INSTALL_DIR" && make -j"$NUM_CORES" install
    cd "$SRC_DIR" && rm -rf libbsd-0.11.7*
fi

# 11. Build scrot
if [ ! -x "$INSTALL_DIR/bin/scrot" ]; then
    echo "📸 Đang build scrot..."
    wget "https://github.com/resurrecting-open-source-projects/scrot/archive/refs/tags/1.8.tar.gz" -O scrot-1.8.tar.gz
    tar -xvf scrot-1.8.tar.gz && cd scrot-1.8
    ./autogen.sh && ./configure --prefix="$INSTALL_DIR" && make -j"$NUM_CORES" install
    cd "$SRC_DIR" && rm -rf scrot-1.8*
fi

# --- BƯỚC CUỐI: TỰ ĐỘNG CẬP NHẬT .bashrc ---
BASHRC_LINE='export PATH="$HOME/.local/bin:$PATH"'
if [ -f "$HOME/.bashrc" ] && ! grep -qF -- "$BASHRC_LINE" "$HOME/.bashrc"; then
    echo "📝 Thêm đường dẫn vào ~/.bashrc..."
    echo "" >> "$HOME/.bashrc"
    echo "# Add local bin to PATH for user-installed programs" >> "$HOME/.bashrc"
    echo "$BASHRC_LINE" >> "$HOME/.bashrc"
    echo "✅ Đã thêm thành công. Vui lòng chạy 'source ~/.bashrc' hoặc mở terminal mới."
else
    echo "👍 Đường dẫn đã tồn tại trong ~/.bashrc (hoặc file không tồn tại). Không cần thêm."
fi

# --- HOÀN TẤT ---
echo ""
echo "🎉 Chúc mừng! Quá trình cài đặt đã hoàn tất thành công!"
echo "Scrot đã có sẵn tại: $INSTALL_DIR/bin/scrot"
