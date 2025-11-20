#!/bin/bash

# --- Cấu hình ---
CUPS_VERSION="2.4.7" # Bạn có thể thay đổi phiên bản này
DOWNLOAD_URL="https://github.com/OpenPrinting/cups/releases/download/v${CUPS_VERSION}/cups-${CUPS_VERSION}-source.tar.gz"
INSTALL_PREFIX="$HOME/.local"
SOURCE_DIR="cups-${CUPS_VERSION}"

# --- 1. Tạo thư mục và Tải xuống ---
echo "▶️ Chuẩn bị thư mục và tải mã nguồn CUPS..."
mkdir -p $INSTALL_PREFIX
mkdir -p ~/src
cd ~/src

if [ ! -f "${SOURCE_DIR}-source.tar.gz" ]; then
    wget -c ${DOWNLOAD_URL} || { echo "Lỗi: Không thể tải xuống mã nguồn CUPS."; exit 1; }
fi

if [ ! -d "${SOURCE_DIR}" ]; then
    tar xzf "${SOURCE_DIR}-source.tar.gz" || { echo "Lỗi: Giải nén không thành công."; exit 1; }
fi

cd ${SOURCE_DIR}

# --- 2. Biên dịch và Cài đặt ---
echo "▶️ Biên dịch và cài đặt CUPS vào $INSTALL_PREFIX..."

# Cấu hình biên dịch
# Lưu ý: Các cờ như --disable-server, --disable-notifier, v.v. giúp chỉ biên dịch thư viện
# libcups mà không cần các phần CUPS server, vốn yêu cầu quyền root và các thiết lập hệ thống.
./configure \
    --prefix=$INSTALL_PREFIX \
    --libdir=$INSTALL_PREFIX/lib \
    --datadir=$INSTALL_PREFIX/share \
    --sysconfdir=$INSTALL_PREFIX/etc \
    --localstatedir=$INSTALL_PREFIX/var \
    --with-cups-user=$USER \
    --with-cups-group=$(id -gn) \
    --disable-server \
    --disable-notifier \
    --disable-tests \
    --disable-pam \
    --disable-gssapi \
    --with-systemd=no \
    --with-initd=no \
    --without-ssl

# Kiểm tra lỗi cấu hình
if [ $? -ne 0 ]; then
    echo "Lỗi: Lệnh './configure' thất bại. Có thể thiếu các thư viện phụ thuộc."
    exit 1
fi

# Chạy make
make -j$(nproc) || { echo "Lỗi: Lệnh 'make' thất bại."; exit 1; }

# Chạy make install
make install || { echo "Lỗi: Lệnh 'make install' thất bại."; exit 1; }

echo "✅ Cài đặt CUPS (libcups) hoàn tất vào $INSTALL_PREFIX"

# --- 3. Thiết lập Môi trường ---
echo "▶️ Thêm đường dẫn thư viện vào .bashrc hoặc .zshrc..."

PROFILE_FILE="$HOME/.bashrc"
if [ -f "$HOME/.zshrc" ]; then
    PROFILE_FILE="$HOME/.zshrc"
fi

CONFIG_LINE="export LD_LIBRARY_PATH=\"$INSTALL_PREFIX/lib:\$LD_LIBRARY_PATH\""

if ! grep -q "$CONFIG_LINE" "$PROFILE_FILE"; then
    echo -e "\n# Thêm thư viện CUPS cục bộ" >> $PROFILE_FILE
    echo "$CONFIG_LINE" >> $PROFILE_FILE
    echo "Đã thêm LD_LIBRARY_PATH vào $PROFILE_FILE. Vui lòng chạy 'source $PROFILE_FILE' hoặc mở terminal mới."
else
    echo "LD_LIBRARY_PATH đã được thiết lập."
fi

echo "Hoàn thành!"
