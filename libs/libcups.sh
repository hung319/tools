#!/bin/bash

# --- Cấu hình ---
CUPS_VERSION="2.4.7"
DOWNLOAD_URL="https://github.com/OpenPrinting/cups/releases/download/v${CUPS_VERSION}/cups-${CUPS_VERSION}-source.tar.gz"
INSTALL_PREFIX="$HOME/.local"
SOURCE_DIR="cups-${CUPS_VERSION}"
SRC_PATH="$HOME/src"
# <<< ĐÃ THAY ĐỔI: Sử dụng thư mục tạm trong $HOME/src để tránh lỗi dung lượng /tmp
TEMP_INSTALL_DIR="$SRC_PATH/temp_install_dir" 

# --- 1. Chuẩn bị và Tải xuống ---
echo "▶️ Chuẩn bị thư mục và tải mã nguồn CUPS..."
mkdir -p $INSTALL_PREFIX
mkdir -p $SRC_PATH
cd $SRC_PATH

# Tải xuống mã nguồn nếu chưa có
if [ ! -f "${SOURCE_DIR}-source.tar.gz" ]; then
    echo "Đang tải xuống CUPS ${CUPS_VERSION}..."
    wget -c ${DOWNLOAD_URL} || { echo "Lỗi: Không thể tải xuống mã nguồn CUPS."; exit 1; }
fi

# Giải nén mã nguồn
if [ ! -d "${SOURCE_DIR}" ]; then
    echo "Đang giải nén..."
    tar xzf "${SOURCE_DIR}-source.tar.gz" || { echo "Lỗi: Giải nén không thành công."; exit 1; }
fi

cd ${SOURCE_DIR}
echo "▶️ Dọn dẹp cấu hình cũ..."
make clean > /dev/null 2>&1

# --- 2. Cấu hình và Biên dịch ---
echo "▶️ Cấu hình biên dịch..."
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
    --without-ssl \
    --disable-gui \
    --disable-manpages \
    --enable-libs

if [ $? -ne 0 ]; then
    echo "❌ Lỗi: Lệnh './configure' thất bại. Vui lòng kiểm tra các thư viện phụ thuộc."
    exit 1
fi

echo "▶️ Bắt đầu biên dịch (make)..."
make -j$(nproc) || { echo "❌ Lỗi: Lệnh 'make' thất bại."; exit 1; }

# --- 3. Cài đặt sử dụng DESTDIR và Sao chép thủ công ---
echo "---"
echo "▶️ Bắt đầu cài đặt TẠM THỜI sử dụng DESTDIR vào $TEMP_INSTALL_DIR..."
# Đảm bảo thư mục tạm thời được tạo trong $HOME/src/
mkdir -p $TEMP_INSTALL_DIR

# make install sẽ cài đặt mọi thứ vào $TEMP_INSTALL_DIR/$INSTALL_PREFIX/
# Điều này tránh được lỗi ghi vào hệ thống và lỗi dung lượng /tmp
make install DESTDIR=$TEMP_INSTALL_DIR || { 
    echo "❌ Lỗi: Lệnh 'make install DESTDIR' thất bại."; 
    rm -rf $TEMP_INSTALL_DIR
    exit 1 
}

# Sao chép thủ công các tệp từ thư mục tạm thời vào thư mục .local mong muốn
echo "▶️ Sao chép các tệp đã cài đặt từ thư mục tạm thời vào $INSTALL_PREFIX..."
# Các tệp sẽ nằm trong $TEMP_INSTALL_DIR/home/container/.local/ (hoặc đường dẫn tương tự)
cp -rf $TEMP_INSTALL_DIR$INSTALL_PREFIX/* $INSTALL_PREFIX/

# Xóa thư mục tạm thời
rm -rf $TEMP_INSTALL_DIR

echo "✅ Cài đặt CUPS (libcups) hoàn tất vào $INSTALL_PREFIX"

# --- 4. Thiết lập Môi trường ---
echo "---"
echo "▶️ Thiết lập biến môi trường LD_LIBRARY_PATH..."

PROFILE_FILE="$HOME/.bashrc"
if [ -f "$HOME/.zshrc" ]; then
    PROFILE_FILE="$HOME/.zshrc"
fi

CONFIG_LINE="export LD_LIBRARY_PATH=\"$INSTALL_PREFIX/lib:\$LD_LIBRARY_PATH\""

if ! grep -q "$CONFIG_LINE" "$PROFILE_FILE"; then
    echo -e "\n# Thêm thư viện CUPS cục bộ (libcups2)" >> $PROFILE_FILE
    echo "$CONFIG_LINE" >> $PROFILE_FILE
    echo "Đã thêm LD_LIBRARY_PATH vào $PROFILE_FILE."
    echo "⚠️ Vui lòng chạy 'source $PROFILE_FILE' hoặc mở terminal mới để áp dụng thay đổi."
else
    echo "LD_LIBRARY_PATH đã được thiết lập trong $PROFILE_FILE."
fi

echo "---"
echo "✨ HOÀN THÀNH. Bạn đã có thể sử dụng libcups2 cục bộ."
