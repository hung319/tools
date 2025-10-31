#!/bin/bash

# 1. Thiết lập các biến môi trường
INSTALL_DIR="$HOME/.local"
SRC_DIR="$HOME/src"
SOURCE_DIR="woff2"
GIT_URL="https://github.com/google/woff2.git"
BUILD_DIR="build_woff2"

echo "🛠️ Bắt đầu cài đặt WOFF2 từ GitHub vào $INSTALL_DIR"
echo "---"

# 2. Kiểm tra phụ thuộc
if ! command -v git &> /dev/null; then
    echo "LỖI: Cần 'git' để clone mã nguồn."
    exit 1
fi
if ! command -v cmake &> /dev/null; then
    echo "LỖI: Cần 'cmake' để cấu hình. Vui lòng cài đặt cmake thủ công hoặc bằng pip."
    exit 1
fi
if ! command -v g++ &> /dev/null; then
    echo "LỖI: Cần 'g++' (hoặc trình biên dịch C++) để biên dịch."
    exit 1
fi

# 3. Thiết lập biến môi trường để tìm phụ thuộc (nếu có)
# Thư viện này có thể yêu cầu Zlib.
export PKG_CONFIG_PATH="$INSTALL_DIR/lib/pkgconfig:$PKG_CONFIG_PATH"
export CFLAGS="-I$INSTALL_DIR/include"
export LDFLAGS="-L$INSTALL_DIR/lib"
echo "Đã thiết lập biến môi trường để tìm phụ thuộc (Zlib) trong $INSTALL_DIR"
echo "---"

# 4. Clone mã nguồn vào ~/src
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if [ -d "$SOURCE_DIR" ]; then
    echo "Thư mục '$SOURCE_DIR' đã tồn tại. Cập nhật mã nguồn..."
    cd "$SOURCE_DIR"
    git pull
else
    echo "Clone mã nguồn WOFF2 từ GitHub..."
    git clone "$GIT_URL"
    cd "$SOURCE_DIR"
fi

# 5. Cấu hình bằng CMake
echo "---"
echo "Chạy CMake setup..."

# Tạo thư mục build và chạy CMake
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Cấu hình CMake để cài đặt vào $INSTALL_DIR
cmake .. -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR"

if [ $? -ne 0 ]; then
    echo "❌ LỖI: CMake cấu hình thất bại."
    exit 1
fi

# 6. Biên dịch và Cài đặt
echo "Biên dịch mã nguồn..."
make -j$(nproc)

echo "Cài đặt vào $INSTALL_DIR..."
make install

# 7. Dọn dẹp
echo "---"
echo "Dọn dẹp tệp tạm..."
cd "$SRC_DIR"
# Xóa thư mục build bên trong thư mục nguồn
rm -rf "$SOURCE_DIR/$BUILD_DIR"

# 8. Thông báo thành công
echo "---"
echo "✅ Cài đặt WOFF2 thành công!"
echo "💡 Thư viện (libwoff2.a) và các công cụ đã được cài vào $INSTALL_DIR/lib và $INSTALL_DIR/bin."
echo "Hãy đảm bảo $HOME/.local/lib đã có trong biến môi trường \$LD_LIBRARY_PATH của bạn."
