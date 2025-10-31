#!/bin/bash

# --- Cấu hình ---
LIBEVENT_VERSION="2.1.12-stable" # Phiên bản ổn định hiện tại
INSTALL_DIR="$HOME/.local"
SOURCE_DIR="$HOME/src"
BUILD_DIR="$SOURCE_DIR/libevent-build" # Thư mục riêng cho quá trình build
DOWNLOAD_URL="https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VERSION}/libevent-${LIBEVENT_VERSION}.tar.gz"
FILENAME="libevent-${LIBEVENT_VERSION}.tar.gz"
EXTRACTED_DIR="libevent-${LIBEVENT_VERSION}"

# --- Kiểm tra và Tạo thư mục ---
echo "✅ Chuẩn bị thư mục..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$SOURCE_DIR"
mkdir -p "$BUILD_DIR"

# --- Tải xuống ---
echo "⬇️ Tải xuống libevent version ${LIBEVENT_VERSION}..."
if [ -f "$SOURCE_DIR/$FILENAME" ]; then
    echo "   File đã tồn tại, bỏ qua tải xuống."
else
    # Sử dụng curl hoặc wget
    if command -v curl &> /dev/null; then
        curl -L "$DOWNLOAD_URL" -o "$SOURCE_DIR/$FILENAME"
    elif command -v wget &> /dev/null; then
        wget -O "$SOURCE_DIR/$FILENAME" "$DOWNLOAD_URL"
    else
        echo "❌ Lỗi: Không tìm thấy curl hay wget để tải file."
        exit 1
    fi
fi

# --- Giải nén ---
echo "📦 Giải nén file..."
cd "$SOURCE_DIR"
if [ -d "$EXTRACTED_DIR" ]; then
    echo "   Thư mục giải nén đã tồn tại, xóa để giải nén lại."
    rm -rf "$EXTRACTED_DIR"
fi
tar -xzvf "$FILENAME"

# --- Biên dịch và Cài đặt bằng CMake ---
echo "⚙️ Bắt đầu biên dịch và cài đặt bằng CMake vào ${INSTALL_DIR}..."
# Di chuyển vào thư mục build
cd "$BUILD_DIR"

# Chạy CMake để cấu hình, chỉ định thư mục source và thư mục cài đặt
cmake "$SOURCE_DIR/$EXTRACTED_DIR" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
    -DEVENT__LIBRARY_TYPE=SHARED \
    -DEVENT__DISABLE_TESTS=ON \
    -DEVENT__DISABLE_BENCHMARK=ON

# Biên dịch (sử dụng -j$(nproc) để tăng tốc nếu hỗ trợ)
make -j$(nproc 2>/dev/null || echo 1)

# Cài đặt
make install

# Dọn dẹp
echo "🧹 Dọn dẹp thư mục build: ${BUILD_DIR}"
rm -rf "$BUILD_DIR"

# --- Hoàn tất ---
echo "🎉 Hoàn tất cài đặt libevent version ${LIBEVENT_VERSION} vào ${INSTALL_DIR}"

# --- Hướng dẫn cuối cùng ---
echo ""
echo "💡 **Bước cuối cùng: Cập nhật biến môi trường**"
echo "   Để hệ thống và các chương trình khác có thể tìm thấy libevent, bạn **cần** thêm các dòng sau vào file shell profile (ví dụ: ~/.bashrc hoặc ~/.zshrc):"
echo ""
echo 'export PATH="$HOME/.local/bin:$PATH"'
echo 'export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"'
echo 'export CPATH="$HOME/.local/include:$CPATH"'
echo 'export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH"'
echo ""
echo "   Sau khi thêm, hãy chạy lệnh: **source ~/.bashrc** (hoặc file tương ứng) để áp dụng thay đổi."
