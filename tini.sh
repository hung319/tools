#!/bin/bash

# Dừng thực thi ngay lập tức nếu có bất kỳ lệnh nào thất bại.
set -e

# --- Các biến có thể tùy chỉnh ---
# Thư mục chứa mã nguồn
SRC_DIR="$HOME/src"
# Thư mục cài đặt (chuẩn cho các gói cài đặt không cần root)
INSTALL_DIR="$HOME/.local"
# Phiên bản tini muốn cài đặt (để "latest" để tự động lấy bản mới nhất)
TINI_VERSION="latest"

# --- Bắt đầu tập lệnh ---

echo "🚀 Bắt đầu quá trình build và cài đặt tini..."

# 1. Chuẩn bị thư mục
echo "--- (1/6) Tạo các thư mục cần thiết ---"
mkdir -p "$SRC_DIR"
mkdir -p "$INSTALL_DIR/bin"

# 2. Tải mã nguồn
echo "--- (2/6) Tải hoặc cập nhật mã nguồn tini ---"
cd "$SRC_DIR"

if [ -d "tini" ]; then
    echo "Thư mục 'tini' đã tồn tại. Cập nhật từ Git..."
    cd tini && git fetch --all --prune && git checkout master && git pull
else
    echo "Tải mã nguồn tini từ GitHub..."
    git clone https://github.com/krallin/tini.git
    cd tini
fi

# 3. Checkout phiên bản
echo "--- (3/6) Chọn phiên bản tini ---"
if [ "$TINI_VERSION" = "latest" ]; then
    # Lấy tag mới nhất từ repo
    LATEST_TAG=$(git describe --tags `git rev-list --tags --max-count=1`)
    echo "Sử dụng phiên bản mới nhất: $LATEST_TAG"
    git checkout "$LATEST_TAG"
else
    echo "Sử dụng phiên bản được chỉ định: v$TINI_VERSION"
    git checkout "v$TINI_VERSION"
fi

# 4. Build và cài đặt
echo "--- (4/6) Build và biên dịch mã nguồn ---"
# Tạo thư mục build riêng để giữ mã nguồn sạch sẽ
mkdir -p build && cd build

# Chạy cmake để cấu hình, trỏ đường dẫn cài đặt đến $HOME/.local
cmake -D CMAKE_INSTALL_PREFIX="$INSTALL_DIR" ..

echo "--- (5/6) Biên dịch và cài đặt với toàn bộ nhân CPU ---"
# Sử dụng 'nproc' để lấy số lượng nhân CPU và cờ -j để build song song
# Điều này giúp tăng tốc đáng kể quá trình biên dịch.
make -j$(nproc)
make install

# 5. Cấu hình môi trường (PATH)
echo "--- (6/6) Cập nhật biến môi trường PATH ---"
# Xác định file cấu hình shell của người dùng
if [ -n "$BASH_VERSION" ]; then
    SHELL_PROFILE="$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
    SHELL_PROFILE="$HOME/.zshrc"
else
    # Giải pháp dự phòng
    SHELL_PROFILE="$HOME/.profile"
fi

EXPORT_CMD="export PATH=\"\$HOME/.local/bin:\$PATH\""
# Kiểm tra xem PATH đã được thêm vào file cấu hình chưa
if ! grep -q "export PATH=\"\$HOME/.local/bin:\$PATH\"" "$SHELL_PROFILE"; then
    echo "Thêm $INSTALL_DIR/bin vào PATH trong file $SHELL_PROFILE..."
    # Thêm dòng export vào cuối file
    echo "" >> "$SHELL_PROFILE"
    echo "# Thêm đường dẫn cho các ứng dụng cài đặt cục bộ" >> "$SHELL_PROFILE"
    echo "$EXPORT_CMD" >> "$SHELL_PROFILE"
    echo "Đã thêm! Vui lòng khởi động lại terminal hoặc chạy 'source $SHELL_PROFILE' để áp dụng thay đổi."
else
    echo "Đường dẫn $INSTALL_DIR/bin đã tồn tại trong PATH của file $SHELL_PROFILE."
fi

# 6. Dọn dẹp và hoàn tất
echo ""
echo "✅ HOÀN TẤT!"
echo "Tini đã được cài đặt thành công tại: $INSTALL_DIR/bin/tini"
echo "Phiên bản: $(tini --version)"
echo "Để sử dụng ngay, bạn có thể chạy: source $SHELL_PROFILE"
