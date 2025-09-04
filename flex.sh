#!/bin/bash

# Dừng script ngay khi có lỗi
set -e

# --- Các biến có thể tùy chỉnh ---
# Phiên bản Flex bạn muốn cài đặt.
# Bạn có thể tìm phiên bản mới nhất tại: https://github.com/westes/flex/releases
FLEX_VERSION="2.6.4"

# Thư mục chứa mã nguồn
SOURCE_DIR="$HOME/src"

# Thư mục cài đặt
INSTALL_PREFIX="$HOME/.local"

# --- Bắt đầu script ---

# 1. Kiểm tra các công cụ build cần thiết
echo "--- 🔍 Kiểm tra các công cụ build ---"
if ! command -v gcc &> /dev/null || ! command -v make &> /dev/null; then
    echo "❌ Lỗi: Không tìm thấy 'gcc' hoặc 'make'."
    echo "Vui lòng cài đặt 'build-essential' trước khi chạy script."
    echo "Trên Ubuntu/Debian, chạy: sudo apt install build-essential"
    exit 1
fi
echo "✅ Đã có các công cụ build."

# 2. Tạo các thư mục cần thiết
echo "--- 🧱 Tạo thư mục nguồn và thư mục cài đặt ---"
mkdir -p "$SOURCE_DIR"
mkdir -p "$INSTALL_PREFIX"

# 3. Tải mã nguồn
echo "--- 🌐 Tải về Flex phiên bản $FLEX_VERSION ---"
cd "$SOURCE_DIR"
if [ ! -f "flex-$FLEX_VERSION.tar.gz" ]; then
    wget "https://github.com/westes/flex/releases/download/v$FLEX_VERSION/flex-$FLEX_VERSION.tar.gz"
else
    echo "File nguồn đã tồn tại, bỏ qua bước tải về."
fi

# 4. Giải nén
echo "--- 📦 Giải nén file nguồn ---"
# Xóa thư mục cũ để đảm bảo build sạch
rm -rf "flex-$FLEX_VERSION"
tar -xf "flex-$FLEX_VERSION.tar.gz"
cd "flex-$FLEX_VERSION"

# 5. Cấu hình (Configure)
echo "--- ⚙️  Cấu hình build script ---"
./configure --prefix="$INSTALL_PREFIX"

# 6. Build
echo "--- 👨‍💻 Biên dịch (make) ---"
# Sử dụng `make -j$(nproc)` để tăng tốc độ build bằng cách sử dụng tất cả các nhân CPU
make -j$(nproc)

# 7. Cài đặt
echo "--- 🚀 Cài đặt (make install) ---"
make install

# --- Hoàn tất ---
echo ""
echo "✅ Cài đặt Flex $FLEX_VERSION thành công vào $INSTALL_PREFIX"
echo "👉 Hãy chắc chắn rằng thư mục '$INSTALL_PREFIX/bin' đã có trong biến môi trường PATH của bạn."
echo "Bạn có thể kiểm tra bằng lệnh: echo \$PATH"
