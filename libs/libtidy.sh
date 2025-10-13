#!/bin/bash
# Script để cài đặt thư viện HTML Tidy (libtidy) từ mã nguồn vào thư mục local của người dùng.
# Không yêu cầu quyền root hay apt/yum.

# Dừng script ngay nếu có lỗi
set -e

# --- CẤU HÌNH ---
# Script sẽ tự động tìm phiên bản mới nhất. Nếu muốn chỉ định, hãy bỏ comment dòng dưới và sửa.
# TIDY_VERSION="5.8.0"
# -----------------

# Định nghĩa các thư mục
INSTALL_DIR="$HOME/.local"
SOURCE_DIR="$HOME/src"

# Tạo các thư mục cần thiết nếu chưa tồn tại
echo "-> Đảm bảo các thư mục tồn tại..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$SOURCE_DIR"

# Di chuyển vào thư mục chứa mã nguồn
cd "$SOURCE_DIR"

# Tự động tìm phiên bản mới nhất từ GitHub API
if [ -z "$TIDY_VERSION" ]; then
    echo "-> 🔎 Đang tìm phiên bản HTML Tidy mới nhất..."
    # Dùng wget và các công cụ text-processing để lấy số phiên bản mới nhất
    LATEST_TAG=$(wget -qO- "https://api.github.com/repos/htacg/tidy-html5/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$LATEST_TAG" ]; then
        echo "Lỗi: Không thể tự động tìm phiên bản mới nhất. Vui lòng chỉ định TIDY_VERSION trong script."
        exit 1
    fi
    TIDY_VERSION="$LATEST_TAG"
    echo "-> ✅ Tìm thấy phiên bản mới nhất: ${TIDY_VERSION}"
fi

# Tên file và URL tải xuống
SOURCE_FILE="${TIDY_VERSION}.tar.gz"
DOWNLOAD_URL="https://github.com/htacg/tidy-html5/archive/refs/tags/${SOURCE_FILE}"
BUILD_DIR="$SOURCE_DIR/tidy-html5-${TIDY_VERSION}"

# Tải mã nguồn nếu chưa có
if [ ! -f "$SOURCE_FILE" ]; then
    echo "-> 📥 Đang tải mã nguồn HTML Tidy phiên bản ${TIDY_VERSION}..."
    wget -O "$SOURCE_FILE" "$DOWNLOAD_URL"
else
    echo "-> ✅ Đã tìm thấy file mã nguồn $SOURCE_FILE."
fi

# Giải nén mã nguồn
echo "-> 📦 Đang giải nén $SOURCE_FILE..."
rm -rf "$BUILD_DIR"
tar -xzf "$SOURCE_FILE"

# Di chuyển vào thư mục build
# Thư mục giải nén có thể khác nhau, nên ta tìm đúng thư mục con
EXTRACTED_DIR=$(tar -tf "$SOURCE_FILE" | head -1 | cut -f1 -d"/")
cd "$EXTRACTED_DIR"

# Quá trình build của Tidy sử dụng CMake
echo "-> ⚙️ Đang cấu hình bản dựng (sử dụng CMake) để cài vào $INSTALL_DIR..."
# Tạo thư mục build riêng
mkdir -p build && cd build

# Chạy cmake để cấu hình
# -DCMAKE_INSTALL_PREFIX chỉ định thư mục cài đặt
cmake .. -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR"

# Biên dịch (compile)
echo "-> 🚀 Đang biên dịch... Thao tác này thường rất nhanh."
make -j$(nproc)

# Cài đặt
echo "-> 💾 Đang cài đặt HTML Tidy..."
make install

echo "✅ Cài đặt HTML Tidy phiên bản ${TIDY_VERSION} thành công vào $INSTALL_DIR!"
echo ""
echo "---"
echo "👉 BƯỚC TIẾP THEO QUAN TRỌNG: Cấu hình môi trường"
echo "---"
echo "Để hệ thống có thể tìm thấy thư viện, đảm bảo các dòng sau đã có trong file ~/.bashrc (hoặc ~/.zshrc):"
echo ""
echo 'export PATH="$HOME/.local/bin:$PATH"'
echo 'export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"'
echo 'export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH"'
echo ""
echo "Nếu bạn đã làm điều này khi cài ICU hoặc Oniguruma thì không cần làm lại."
