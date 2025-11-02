#!/bin/bash

# --- Cấu hình ---
# Đổi số phiên bản nếu cần
READLINE_VERSION="8.2" 
READLINE_TARBALL="readline-${READLINE_VERSION}.tar.gz"
READLINE_URL="https://ftp.gnu.org/gnu/readline/${READLINE_TARBALL}"
INSTALL_DIR="$HOME/.local"
BUILD_DIR="$HOME/tmp_build_readline"

# Tạo thư mục cài đặt nếu chưa có
mkdir -p "$INSTALL_DIR"
# Tạo thư mục build tạm thời
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "Bắt đầu cài đặt Readline phiên bản ${READLINE_VERSION} vào ${INSTALL_DIR}"
echo "----------------------------------------------------"

# 1. Tải mã nguồn
echo "1. Đang tải mã nguồn..."
if command -v wget &> /dev/null; then
    wget -q "$READLINE_URL"
elif command -v curl &> /dev/null; then
    curl -s -O "$READLINE_URL"
else
    echo "LỖI: Không tìm thấy wget hoặc curl. Vui lòng cài đặt một trong hai."
    exit 1
fi

if [ ! -f "$READLINE_TARBALL" ]; then
    echo "LỖI: Tải xuống thất bại. Tệp ${READLINE_TARBALL} không tồn tại."
    exit 1
fi

# 2. Giải nén
echo "2. Đang giải nén..."
tar -xzf "$READLINE_TARBALL"
cd "readline-${READLINE_VERSION}"

# 3. Cấu hình, Biên dịch và Cài đặt
echo "3. Đang cấu hình (chỉ định --prefix=${INSTALL_DIR})..."
./configure --prefix="$INSTALL_DIR" --disable-shared

if [ $? -ne 0 ]; then
    echo "LỖI: Cấu hình thất bại."
    exit 1
fi

echo "4. Đang biên dịch..."
# Sử dụng -j để tăng tốc độ biên dịch (ví dụ: -j4)
make -j$(nproc)

if [ $? -ne 0 ]; then
    echo "LỖI: Biên dịch thất bại."
    exit 1
fi

echo "5. Đang cài đặt..."
# Sử dụng install (không cần sudo)
make install

if [ $? -ne 0 ]; then
    echo "LỖI: Cài đặt thất bại."
    exit 1
fi

# 6. Dọn dẹp
echo "6. Dọn dẹp thư mục build tạm thời..."
cd "$HOME"
rm -rf "$BUILD_DIR"

# 7. Cập nhật PATH và LD_LIBRARY_PATH (Quan trọng)
echo ""
echo "✅ Cài đặt Readline thành công vào ${INSTALL_DIR}"
echo "----------------------------------------------------"
echo "⭐ ĐỂ SỬ DỤNG LIB NÀY, BẠN CẦN CẬP NHẬT BIẾN MÔI TRƯỜNG."
echo "   VUI LÒNG THÊM CÁC DÒNG SAU VÀO TỆP CẤU HÌNH SHELL CỦA BẠN (ví dụ: ~/.bashrc hoặc ~/.zshrc):"
echo ""
echo 'export PATH="$HOME/.local/bin:$PATH"'
echo 'export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"'
echo ""
echo "   Sau khi thêm, chạy: source ~/.bashrc (hoặc tệp tương ứng) để áp dụng."
