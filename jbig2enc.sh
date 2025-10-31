#!/bin/bash

# 1. Thiết lập các biến môi trường
INSTALL_DIR="$HOME/.local"
# Thư mục để tải và biên dịch mã nguồn
SRC_DIR="$HOME/src"
# Tên thư mục nguồn (tên khi clone)
SOURCE_DIR="jbig2enc"
# URL Git
GIT_URL="https://github.com/agl/jbig2enc.git"

echo "🛠️ Bắt đầu cài đặt jbig2enc vào $INSTALL_DIR"
echo "---"

# 2. Kiểm tra phụ thuộc
if ! command -v git &> /dev/null; then
    echo "LỖI: Cần 'git' để clone mã nguồn. Vui lòng cài đặt git."
    exit 1
fi

# 3. Thiết lập biến môi trường để tìm phụ thuộc (Leptonica)
# Đảm bảo các thư viện đã cài trong .local được tìm thấy
export PKG_CONFIG_PATH="$INSTALL_DIR/lib/pkgconfig:$PKG_CONFIG_PATH"
export CFLAGS="-I$INSTALL_DIR/include"
export LDFLAGS="-L$INSTALL_DIR/lib"
echo "Đã thiết lập biến môi trường để tìm phụ thuộc (Leptonica) trong $INSTALL_DIR"
echo "---"

# 4. Tải mã nguồn vào ~/src
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

echo "Clone mã nguồn jbig2enc vào $SRC_DIR..."
if [ -d "$SOURCE_DIR" ]; then
    echo "Thư mục $SOURCE_DIR đã tồn tại. Cập nhật mã nguồn..."
    cd "$SOURCE_DIR"
    git pull
    cd ..
else
    git clone "$GIT_URL"
fi

if [ ! -d "$SOURCE_DIR" ]; then
    echo "LỖI: Không thể clone mã nguồn jbig2enc."
    exit 1
fi

# 5. Biên dịch và Cài đặt
echo "Di chuyển vào thư mục nguồn và bắt đầu biên dịch..."
cd "$SOURCE_DIR"

# jbig2enc sử dụng Autotools (configure/make)
# Tạo tệp configure nếu cần
if [ ! -f "configure" ]; then
    echo "Chạy autogen/autoconf..."
    # Yêu cầu autoconf, automake, và libtool nếu các tệp này không có sẵn
    # Nếu lệnh này báo lỗi, bạn cần cài đặt các công cụ build cơ bản này
    autoreconf -i
fi

# Cấu hình để cài đặt vào thư mục .local
./configure --prefix="$INSTALL_DIR"

if [ $? -ne 0 ]; then
    echo "LỖI: Cấu hình thất bại. Kiểm tra xem Leptonica đã được cài đặt và PKG_CONFIG_PATH đã thiết lập đúng chưa."
    exit 1
fi

echo "Biên dịch mã nguồn..."
make -j$(nproc)

echo "Cài đặt vào $INSTALL_DIR..."
make install

# 6. Dọn dẹp
echo "---"
echo "Chỉ xóa các tệp biên dịch (giữ lại thư mục nguồn $SRC_DIR/$SOURCE_DIR cho lần cập nhật sau)."
# Không xóa thư mục nguồn vì nó đã được clone bằng git
make clean

# 7. Thông báo thành công
echo "---"
echo "✅ Cài đặt jbig2enc thành công!"
echo "💡 Chương trình thực thi đã được cài vào $INSTALL_DIR/bin/jbig2"
echo "Kiểm tra bằng cách chạy: $INSTALL_DIR/bin/jbig2 --help"
