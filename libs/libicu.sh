#!/bin/bash
# Script để cài đặt thư viện ICU (icu4c) phiên bản 77.1 từ mã nguồn vào thư mục local của người dùng.
# Không yêu cầu quyền root hay apt/yum.

# Dừng script ngay nếu có lỗi
set -e

# --- CẤU HÌNH ---
# Phiên bản ICU được chỉ định
ICU_VERSION="77.1"
ICU_VERSION_UNDERSCORE="77_1"
ICU_VERSION_RELEASE="77-1"
# -----------------

# Tên file và URL tải xuống từ yêu cầu
SOURCE_FILE="icu4c-${ICU_VERSION_UNDERSCORE}-src.tgz"
DOWNLOAD_URL="https://github.com/unicode-org/icu/releases/download/release-${ICU_VERSION_RELEASE}/${SOURCE_FILE}"

# Định nghĩa các thư mục
INSTALL_DIR="$HOME/.local"
SOURCE_DIR="$HOME/src"
BUILD_DIR="$SOURCE_DIR/icu"

# Tạo các thư mục cần thiết nếu chưa tồn tại
echo "-> Đảm bảo các thư mục tồn tại..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$SOURCE_DIR"

# Di chuyển vào thư mục chứa mã nguồn
cd "$SOURCE_DIR"

# Tải mã nguồn nếu chưa có
if [ ! -f "$SOURCE_FILE" ]; then
    echo "-> 📥 Đang tải mã nguồn ICU phiên bản $ICU_VERSION..."
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
cd "$BUILD_DIR/source"

# Cấu hình bản dựng (configure)
# --prefix=$INSTALL_DIR là phần quan trọng nhất, chỉ định nơi cài đặt
echo "-> ⚙️ Đang cấu hình bản dựng để cài vào $INSTALL_DIR..."
./configure --prefix="$INSTALL_DIR"

# Biên dịch (compile)
# Sử dụng tất cả các nhân CPU để tăng tốc độ với `make -j$(nproc)`
echo "-> 🚀 Đang biên dịch... Quá trình này có thể mất một lúc."
make -j$(nproc)

# Cài đặt
echo "-> 💾 Đang cài đặt ICU..."
make install

echo "✅ Cài đặt ICU phiên bản $ICU_VERSION thành công vào $INSTALL_DIR!"
echo ""
echo "---"
echo "👉 BƯỚC TIẾP THEO QUAN TRỌNG: Cấu hình môi trường"
echo "---"
echo "Để hệ thống có thể tìm thấy thư viện vừa cài, bạn cần thêm các dòng sau vào cuối file cấu hình shell của bạn (~/.bashrc, ~/.zshrc, ...):"
echo ""
echo 'export PATH="$HOME/.local/bin:$PATH"'
echo 'export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"'
echo 'export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH"'
echo ""
echo "Sau khi thêm, hãy chạy lệnh 'source ~/.bashrc' (hoặc file tương ứng) hoặc mở lại terminal để áp dụng thay đổi."
