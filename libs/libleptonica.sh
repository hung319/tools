#!/bin/bash

# 1. Thiết lập các biến môi trường
INSTALL_DIR="$HOME/.local"
# Thư mục để tải và biên dịch mã nguồn
SRC_DIR="$HOME/src"
LEPTONICA_VERSION="1.83.0" # Hoặc phiên bản mới nhất bạn muốn
SOURCE_DIR="leptonica-$LEPTONICA_VERSION"
ARCHIVE_FILE="$SOURCE_DIR.tar.gz"
DOWNLOAD_URL="https://github.com/DanBloomberg/leptonica/releases/download/$LEPTONICA_VERSION/$ARCHIVE_FILE"

echo "🛠️ Bắt đầu cài đặt Leptonica $LEPTONICA_VERSION vào $INSTALL_DIR"
echo "---"

# 2. Thiết lập biến môi trường để tìm phụ thuộc (quan trọng!)
export PKG_CONFIG_PATH="$INSTALL_DIR/lib/pkgconfig:$PKG_CONFIG_PATH"
export CFLAGS="-I$INSTALL_DIR/include"
export LDFLAGS="-L$INSTALL_DIR/lib"
echo "Đã thiết lập biến môi trường để tìm phụ thuộc (zlib, v.v.) trong $INSTALL_DIR"
echo "---"

# 3. Tạo thư mục nguồn và di chuyển vào
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# 4. Tải mã nguồn vào ~/src
echo "Tải mã nguồn Leptonica vào $SRC_DIR..."
if command -v curl &> /dev/null; then
    curl -LO "$DOWNLOAD_URL"
elif command -v wget &> /dev/null; then
    wget "$DOWNLOAD_URL"
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
cd "$SOURCE_DIR"

# Cấu hình
./configure --prefix="$INSTALL_DIR"

if [ $? -ne 0 ]; then
    echo "LỖI: Cấu hình thất bại. Kiểm tra phụ thuộc."
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
echo "✅ Cài đặt Leptonica thành công! (Nguồn: $SRC_DIR)"
