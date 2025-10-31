#!/bin/bash

# 1. Thiết lập các biến môi trường
INSTALL_DIR="$HOME/.local"
SRC_DIR="$HOME/src"
# Thông tin tệp binary
ARCHIVE_FILE="pngquant-linux.tar.bz2"
DOWNLOAD_URL="https://pngquant.org/$ARCHIVE_FILE"
# Tên file binary sau khi giải nén (có thể thay đổi tùy phiên bản)
BINARY_FILE="pngquant"

echo "🛠️ Bắt đầu cài đặt binary pngquant vào $INSTALL_DIR/bin"
echo "---"

# 2. Tạo thư mục đích và thư mục nguồn
mkdir -p "$INSTALL_DIR/bin"
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# 3. Tải tệp binary nén vào ~/src
echo "Tải tệp binary nén pngquant từ $DOWNLOAD_URL..."
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

# 4. Giải nén và Cài đặt
echo "Giải nén tệp..."
# Sử dụng 'j' cho tar.bz2
tar -xjf "$ARCHIVE_FILE"

# Di chuyển binary vào thư mục đích
echo "Cài đặt binary vào $INSTALL_DIR/bin..."
# Binary sau khi giải nén thường nằm ở thư mục hiện tại hoặc một thư mục con
# Tùy thuộc vào cách tệp tar.bz2 được đóng gói, ta cần tìm binary
if [ -f "$BINARY_FILE" ]; then
    cp "$BINARY_FILE" "$INSTALL_DIR/bin/"
elif [ -f "pngquant/pngquant" ]; then
    # Trường hợp binary nằm trong một thư mục con tên là 'pngquant'
    cp "pngquant/$BINARY_FILE" "$INSTALL_DIR/bin/"
else
    echo "LỖI: Không tìm thấy tệp thực thi (binary) 'pngquant' sau khi giải nén."
    echo "Vui lòng kiểm tra nội dung của tệp $ARCHIVE_FILE."
    exit 1
fi

# Cấp quyền thực thi
chmod +x "$INSTALL_DIR/bin/$BINARY_FILE"

# 5. Dọn dẹp
echo "---"
echo "Dọn dẹp tệp tạm..."
# Xóa tệp nén và thư mục giải nén tạm thời
rm -rf "$ARCHIVE_FILE" "pngquant"

# 6. Thông báo thành công
echo "---"
echo "✅ Cài đặt binary pngquant thành công!"
echo "Chương trình thực thi là: $INSTALL_DIR/bin/pngquant"
echo "💡 Hãy đảm bảo rằng $INSTALL_DIR/bin đã có trong biến môi trường \$PATH của bạn."
