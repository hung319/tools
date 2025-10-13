#!/bin/bash
# Script để cài đặt thư viện Oniguruma từ mã nguồn vào thư mục local của người dùng.
# Không yêu cầu quyền root hay apt/yum.

# Dừng script ngay nếu có lỗi
set -e

# --- CẤU HÌNH ---
# Bạn có thể thay đổi phiên bản Oniguruma tại đây.
# Kiểm tra phiên bản mới nhất tại: https://github.com/kkos/oniguruma/releases
ONIG_VERSION="6.9.9"
# -----------------

# Tên file và URL tải xuống
SOURCE_FILE="onig-${ONIG_VERSION}.tar.gz"
DOWNLOAD_URL="https://github.com/kkos/oniguruma/releases/download/v${ONIG_VERSION}/${SOURCE_FILE}"

# Định nghĩa các thư mục
INSTALL_DIR="$HOME/.local"
SOURCE_DIR="$HOME/src"
BUILD_DIR="$SOURCE_DIR/onig-${ONIG_VERSION}"

# Tạo các thư mục cần thiết nếu chưa tồn tại
echo "-> Đảm bảo các thư mục tồn tại..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$SOURCE_DIR"

# Di chuyển vào thư mục chứa mã nguồn
cd "$SOURCE_DIR"

# Tải mã nguồn nếu chưa có
if [ ! -f "$SOURCE_FILE" ]; then
    echo "-> 📥 Đang tải mã nguồn Oniguruma phiên bản ${ONIG_VERSION}..."
    wget "$DOWNLOAD_URL"
else
    echo "-> ✅ Đã tìm thấy file mã nguồn $SOURCE_FILE."
fi

# Giải nén mã nguồn
echo "-> 📦 Đang giải nén $SOURCE_FILE..."
# Xóa thư mục build cũ nếu có để tránh lỗi
rm -rf "$BUILD_DIR"
tar -xzf "$SOURCE_FILE"

# Di chuyển vào thư mục build
cd "$BUILD_DIR"

# Cấu hình bản dựng (configure)
# --prefix=$INSTALL_DIR là phần quan trọng nhất, chỉ định nơi cài đặt
echo "-> ⚙️ Đang cấu hình bản dựng để cài vào $INSTALL_DIR..."
./configure --prefix="$INSTALL_DIR"

# Biên dịch (compile)
# Sử dụng tất cả các nhân CPU để tăng tốc độ với `make -j$(nproc)`
echo "-> 🚀 Đang biên dịch... Thao tác này thường rất nhanh."
make -j$(nproc)

# Cài đặt
echo "-> 💾 Đang cài đặt Oniguruma..."
make install

echo "✅ Cài đặt Oniguruma phiên bản ${ONIG_VERSION} thành công vào $INSTALL_DIR!"
echo ""
echo "---"
echo "👉 BƯỚC TIẾP THEO QUAN TRỌNG: Cấu hình môi trường"
echo "---"
echo "Để hệ thống có thể tìm thấy thư viện vừa cài, bạn cần đảm bảo các dòng sau đã có trong file cấu hình shell của bạn (~/.bashrc, ~/.zshrc, ...):"
echo ""
echo 'export PATH="$HOME/.local/bin:$PATH"'
echo 'export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"'
echo 'export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH"'
echo ""
echo "Nếu bạn vừa làm điều này khi cài ICU thì không cần làm lại. Nếu chưa, hãy thêm chúng vào và chạy 'source ~/.bashrc' (hoặc file tương ứng) để áp dụng thay đổi."
