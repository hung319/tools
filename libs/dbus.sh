#!/bin/bash

# --- Cấu hình DBus ---
DBUS_VERSION="1.15.8" 
DOWNLOAD_URL="https://dbus.freedesktop.org/releases/dbus/dbus-${DBUS_VERSION}.tar.xz"
INSTALL_PREFIX="$HOME/.local"
SOURCE_DIR="dbus-${DBUS_VERSION}"
SRC_PATH="$HOME/src"
TEMP_INSTALL_DIR="$SRC_PATH/dbus-temp-install"
BUILD_DIR="build"

# --- 1. Chuẩn bị, Tải xuống, Cấu hình và Biên dịch (Không thay đổi) ---
echo "▶️ Chuẩn bị thư mục và tải mã nguồn DBus..."
mkdir -p $INSTALL_PREFIX
mkdir -p $SRC_PATH
cd $SRC_PATH

if [ ! -d "${SOURCE_DIR}" ]; then
    echo "Đang tải xuống và giải nén..."
    wget -c ${DOWNLOAD_URL} || { echo "❌ Lỗi: Tải xuống DBus thất bại."; exit 1; }
    tar xJf "${SOURCE_DIR}.tar.xz" || { echo "❌ Lỗi: Giải nén DBus thất bại."; exit 1; }
fi

cd ${SOURCE_DIR}
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
cd $BUILD_DIR

echo "---"
echo "▶️ Cấu hình biên dịch DBus (Chỉ Thư viện Core)..."

# Lệnh MESON SETUP TÙY CHỈNH
meson setup .. \
    --prefix="$INSTALL_PREFIX" \
    -Dmessage_bus=false \
    -Dtools=false \
    -Dsystemd=disabled \
    -Dx11_autolaunch=disabled \
    -Dasserts=false \
    -Dchecks=false \
    -Dinstalled_tests=false \
    -Dembedded_tests=false \
    -Dmodular_tests=disabled \
    -Ddoxygen_docs=disabled \
    -Dxml_docs=disabled \
    -Dducktype_docs=disabled \
    -Dqt_help=disabled

if [ $? -ne 0 ]; then
    echo "❌ LỖI CẤU HÌNH: Lệnh 'meson setup' DBus thất bại."
    cd ..; exit 1
fi

echo "▶️ Bắt đầu biên dịch DBus (ninja)..."
ninja || { echo "❌ Lỗi: Lệnh 'ninja' DBus thất bại."; cd ..; exit 1; }
cd ..

# --- 3. Cài đặt sử dụng DESTDIR và Sao chép thủ công (PHẦN ĐÃ SỬA) ---
echo "---"
echo "▶️ Bắt đầu cài đặt DBus TẠM THỜI sử dụng DESTDIR..."
mkdir -p $TEMP_INSTALL_DIR

# 🌟 LỆNH ĐÃ SỬA: Truyền DESTDIR dưới dạng biến môi trường 🌟
DESTDIR=$TEMP_INSTALL_DIR ninja -C $BUILD_DIR install || { 
    echo "❌ Lỗi: Lệnh 'ninja install DESTDIR' DBus thất bại."; 
    rm -rf $TEMP_INSTALL_DIR
    exit 1 
}

echo "▶️ Sao chép các tệp DBus đã cài đặt vào $INSTALL_PREFIX..."
cp -rf $TEMP_INSTALL_DIR$INSTALL_PREFIX/* $INSTALL_PREFIX/

# Xóa thư mục tạm thời và thư mục build
rm -rf $TEMP_INSTALL_DIR
rm -rf $SOURCE_DIR/$BUILD_DIR 

echo "✅ Cài đặt DBus (libdbus-1) hoàn tất vào $INSTALL_PREFIX"

# --- 4. Cập nhật Môi trường (RẤT QUAN TRỌNG) ---
echo "---"
echo "▶️ Cập nhật biến môi trường PKG_CONFIG_PATH và LD_LIBRARY_PATH..."

PROFILE_FILE="$HOME/.bashrc"
if [ -f "$HOME/.zshrc" ]; then
    PROFILE_FILE="$HOME/.zshrc"
fi

CONFIG_LINE_PKG="export PKG_CONFIG_PATH=\"$INSTALL_PREFIX/lib/pkgconfig:\$PKG_CONFIG_PATH\""
CONFIG_LINE_LIB="export LD_LIBRARY_PATH=\"$INSTALL_PREFIX/lib:\$LD_LIBRARY_PATH\""


if ! grep -q "$CONFIG_LINE_PKG" "$PROFILE_FILE"; then
    echo -e "\n# Thêm thư viện DBus cục bộ" >> $PROFILE_FILE
    echo "$CONFIG_LINE_PKG" >> $PROFILE_FILE
    echo "$CONFIG_LINE_LIB" >> $PROFILE_FILE
fi

echo "Đã cập nhật PKG_CONFIG_PATH và LD_LIBRARY_PATH. Vui lòng chạy 'source $PROFILE_FILE'."
echo "---"
echo "✨ BƯỚC TIẾP THEO: Sau khi chạy script này, bạn phải chạy 'source $PROFILE_FILE', sau đó chạy lại script cài đặt AT-SPI2-CORE."
