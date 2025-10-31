#!/bin/bash

# 1. Thiết lập các biến môi trường
INSTALL_DIR="$HOME/.local"
SRC_DIR="$HOME/src"
TESSERACT_VERSION="5.5.1" 
SOURCE_DIR="tesseract-$TESSERACT_VERSION"
ARCHIVE_FILE="$TESSERACT_VERSION.tar.gz"
# URL đã được cập nhật theo yêu cầu của bạn
DOWNLOAD_URL="https://github.com/tesseract-ocr/tesseract/archive/refs/tags/$ARCHIVE_FILE"

echo "🛠️ Bắt đầu cài đặt Tesseract $TESSERACT_VERSION vào $INSTALL_DIR"
echo "---"

# 2. Thiết lập biến môi trường để tìm phụ thuộc (Leptonica)
export PKG_CONFIG_PATH="$INSTALL_DIR/lib/pkgconfig:$PKG_CONFIG_PATH"
export CFLAGS="-I$INSTALL_DIR/include"
export LDFLAGS="-L$INSTALL_DIR/lib"
echo "Đã thiết lập biến môi trường để tìm phụ thuộc (Leptonica) trong $INSTALL_DIR"
echo "---"

# 3. Tạo thư mục nguồn và di chuyển vào
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# 4. Tải mã nguồn vào ~/src
echo "Tải mã nguồn Tesseract v$TESSERACT_VERSION vào $SRC_DIR..."
if command -v curl &> /dev/null; then
    curl -LO "$DOWNLOAD_URL"
elif command -v wget &> /dev/null; then
    wget -O "$ARCHIVE_FILE" "$DOWNLOAD_URL" # Dùng -O để đảm bảo tên file đúng
else
    echo "LỖI: Cần 'curl' hoặc 'wget'."
    exit 1
fi

if [ ! -f "$ARCHIVE_FILE" ]; then
    echo "LỖI: Không thể tải tệp $ARCHIVE_FILE."
    exit 1
fi

# 5. Giải nén, Biên dịch, và Cài đặt
echo "Giải nén và cấu hình..."
tar -xzf "$ARCHIVE_FILE"
# Sau khi giải nén từ GitHub tag, thư mục thường là tesseract-<version>
cd "$SOURCE_DIR"

# Tesseract sử dụng Autotools (configure/make)
# Chạy autoconf nếu cần (chỉ cần thiết nếu tệp configure bị thiếu)
if [ ! -f "configure" ]; then
    echo "Chạy autogen/autoconf..."
    ./autogen.sh
fi

# Cấu hình
./configure --prefix="$INSTALL_DIR" \
            --disable-debug \
            --disable-openmp

if [ $? -ne 0 ]; then
    echo "LỖI: Cấu hình Tesseract thất bại. Kiểm tra Leptonica và các công cụ build cơ bản."
    exit 1
fi

echo "Biên dịch mã nguồn..."
make -j$(nproc)

echo "Cài đặt vào $INSTALL_DIR..."
make install

# 6. Dọn dẹp
echo "---"
echo "Dọn dẹp tệp tạm..."
cd "$SRC_DIR"
rm -rf "$SOURCE_DIR" "$ARCHIVE_FILE"

# 7. Thông báo thành công
echo "---"
echo "✅ Cài đặt Tesseract $TESSERACT_VERSION thành công!"
echo "Chương trình thực thi là: $INSTALL_DIR/bin/tesseract"
