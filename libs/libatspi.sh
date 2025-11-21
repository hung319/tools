#!/bin/bash

# --- Cấu hình ---
ATSPI_VERSION="2.48.0" 
DOWNLOAD_URL="https://download.gnome.org/sources/at-spi2-core/${ATSPI_VERSION%.*}/at-spi2-core-${ATSPI_VERSION}.tar.xz"
INSTALL_PREFIX="$HOME/.local"
SOURCE_DIR="at-spi2-core-${ATSPI_VERSION}"
SRC_PATH="$HOME/src"
TEMP_INSTALL_DIR="$SRC_PATH/atspi-temp-install" 
BUILD_DIR="build"

# --- 1. Chuẩn bị và Tải xuống (Không thay đổi) ---
echo "▶️ Chuẩn bị thư mục và tải mã nguồn AT-SPI2-CORE..."
mkdir -p $INSTALL_PREFIX
mkdir -p $SRC_PATH
cd $SRC_PATH

if [ ! -d "${SOURCE_DIR}" ]; then
    echo "Đang tải xuống và giải nén..."
    wget -c ${DOWNLOAD_URL} || { echo "❌ Lỗi: Không thể tải xuống."; exit 1; }
    tar xJf "${SOURCE_DIR}.tar.xz" || { echo "❌ Lỗi: Giải nén không thành công."; exit 1; }
fi

cd ${SOURCE_DIR}

# --- 2. Cấu hình và Biên dịch (Không thay đổi) ---
echo "---"
echo "▶️ Bắt đầu cấu hình biên dịch bằng Meson/Ninja..."

# Nếu bạn đã chạy meson setup thành công, bạn có thể bỏ qua phần này và chỉ chạy từ 'ninja'
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
cd $BUILD_DIR

meson setup .. \
    --prefix="$INSTALL_PREFIX" \
    -Dsystemd_user_dir='' \
    -Ddocs=false \
    -Dintrospection=enabled \
    -Dx11=disabled

if [ $? -ne 0 ]; then
    echo "❌ LỖI CẤU HÌNH: Lệnh 'meson setup' thất bại."
    cd ..; exit 1
fi

echo "▶️ Bắt đầu biên dịch (ninja)..."
ninja || { echo "❌ Lỗi: Lệnh 'ninja' thất bại."; cd ..; exit 1; }
cd ..

# --- 3. Cài đặt sử dụng DESTDIR và Sao chép thủ công (PHẦN ĐÃ SỬA) ---
echo "---"
echo "▶️ Bắt đầu cài đặt TẠM THỜI sử dụng DESTDIR vào $TEMP_INSTALL_DIR..."
mkdir -p $TEMP_INSTALL_DIR

# 🌟 LỆNH ĐÃ SỬA: Truyền DESTDIR dưới dạng biến môi trường 🌟
DESTDIR=$TEMP_INSTALL_DIR ninja -C $BUILD_DIR install || { 
    echo "❌ Lỗi: Lệnh 'ninja install DESTDIR' thất bại."; 
    rm -rf $TEMP_INSTALL_DIR
    exit 1 
}

echo "▶️ Sao chép các tệp đã cài đặt từ thư mục tạm thời vào $INSTALL_PREFIX..."
cp -rf $TEMP_INSTALL_DIR$INSTALL_PREFIX/* $INSTALL_PREFIX/

# Xóa thư mục tạm thời và thư mục build
rm -rf $TEMP_INSTALL_DIR
rm -rf $SOURCE_DIR/$BUILD_DIR 

echo "✅ Cài đặt AT-SPI2-CORE (libatspi) hoàn tất vào $INSTALL_PREFIX"

# --- 4. Thiết lập Môi trường (Không thay đổi) ---
echo "---"
echo "▶️ Thiết lập biến môi trường LD_LIBRARY_PATH và PKG_CONFIG_PATH..."

PROFILE_FILE="$HOME/.bashrc"
if [ -f "$HOME/.zshrc" ]; then
    PROFILE_FILE="$HOME/.zshrc"
fi

CONFIG_LINE_LIB="export LD_LIBRARY_PATH=\"$INSTALL_PREFIX/lib:\$LD_LIBRARY_PATH\""
CONFIG_LINE_PKG="export PKG_CONFIG_PATH=\"$INSTALL_PREFIX/lib/pkgconfig:\$PKG_CONFIG_PATH\""

if ! grep -q "$CONFIG_LINE_LIB" "$PROFILE_FILE"; then
    echo -e "\n# Thêm thư viện AT-SPI2 cục bộ" >> $PROFILE_FILE
    echo "$CONFIG_LINE_LIB" >> $PROFILE_FILE
fi

if ! grep -q "$CONFIG_LINE_PKG" "$PROFILE_FILE"; then
    echo "$CONFIG_LINE_PKG" >> $PROFILE_FILE
fi

echo "Đã cập nhật LD_LIBRARY_PATH và PKG_CONFIG_PATH trong $PROFILE_FILE."
echo "⚠️ Vui lòng chạy 'source $PROFILE_FILE' hoặc mở terminal mới để áp dụng thay đổi."
echo "---"
echo "✨ HOÀN THÀNH. Bạn chỉ còn một bước nữa!"
