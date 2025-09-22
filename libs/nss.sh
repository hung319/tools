#!/bin/bash

#================================================================
# Script cài đặt libnss3 vào ~/.local và tự động cấu hình shell.
# Script sẽ:
# 1. Tải và cài đặt thư viện vào ~/.local/lib.
# 2. Tự động nhận diện shell (bash, zsh, fish).
# 3. Kiểm tra và thêm biến môi trường vào file config tương ứng.
#================================================================

# Dừng script ngay nếu có lệnh nào thất bại
set -e

# --- Cấu hình ---
PACKAGE_NAME="libnss3"
INSTALL_DIR="$HOME/.local"
LIB_DIR="$INSTALL_DIR/lib"

# --- Phần 1: Tải và cài đặt thư viện ---
echo "🚀 Bắt đầu quá trình cài đặt $PACKAGE_NAME vào $INSTALL_DIR"

# Tạo thư mục đích nếu nó chưa tồn tại
echo "-> Tạo thư mục: $LIB_DIR"
mkdir -p "$LIB_DIR"

# Tạo thư mục tạm và đảm bảo dọn dẹp sau khi script chạy xong
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT
cd "$TEMP_DIR"

# Tải gói .deb
echo "-> Đang tải gói $PACKAGE_NAME..."
if ! apt-get download "$PACKAGE_NAME" >/dev/null 2>&1; then
    echo "❌ Lỗi: Không thể tải về file .deb của $PACKAGE_NAME. Hãy kiểm tra lại tên gói hoặc kết nối mạng."
    exit 1
fi

DEB_FILE=$(ls *.deb)
echo "-> Đã tải thành công: $DEB_FILE"

# Giải nén và sao chép thư viện
echo "-> Giải nén và sao chép các file thư viện (.so)..."
dpkg-deb -x "$DEB_FILE" .
find . -name "*.so*" -exec cp -v {} "$LIB_DIR/" \;

echo "✅ Hoàn tất cài đặt thư viện vào $LIB_DIR."

# --- Phần 2: Tự động cấu hình Shell ---
echo ""
echo "⚙️ Bắt đầu tự động cấu hình môi trường shell..."

# Lấy tên shell hiện tại (vd: bash, zsh)
CURRENT_SHELL=$(basename "$SHELL")
CONFIG_FILE=""
ENV_LINE=""

case "$CURRENT_SHELL" in
bash)
    CONFIG_FILE="$HOME/.bashrc"
    ENV_LINE='export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"'
    ;;
zsh)
    CONFIG_FILE="$HOME/.zshrc"
    ENV_LINE='export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"'
    ;;
fish)
    # fish shell có cú pháp khác và đường dẫn config khác
    CONFIG_DIR="$HOME/.config/fish"
    mkdir -p "$CONFIG_DIR"
    CONFIG_FILE="$CONFIG_DIR/config.fish"
    ENV_LINE='set -x LD_LIBRARY_PATH "$HOME/.local/lib" $LD_LIBRARY_PATH'
    ;;
*)
    echo "⚠️ Không thể tự động nhận diện shell '$CURRENT_SHELL'."
    echo "Vui lòng tự thêm dòng sau vào file cấu hình shell của bạn:"
    echo 'export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"'
    exit 0
    ;;
esac

echo "-> Phát hiện bạn đang dùng shell: $CURRENT_SHELL"
echo "-> Sẽ kiểm tra và cập nhật file: $CONFIG_FILE"

# Kiểm tra xem dòng cấu hình đã tồn tại trong file chưa
if grep -qF -- "$ENV_LINE" "$CONFIG_FILE"; then
    echo "✔️ Cấu hình đã tồn tại trong $CONFIG_FILE. Bỏ qua."
else
    # Nếu chưa, thêm vào cuối file
    echo "-> Thêm cấu hình vào cuối file $CONFIG_FILE..."
    echo "" >> "$CONFIG_FILE"
    echo "# Cấu hình đường dẫn thư viện cục bộ (thêm bởi script)" >> "$CONFIG_FILE"
    echo "$ENV_LINE" >> "$CONFIG_FILE"
    echo "✔️ Đã thêm cấu hình thành công."
fi

# --- Hướng dẫn cuối cùng ---
echo -e "\n\n"
echo "--- 🎉 HOÀN TẤT ---"
echo "Để áp dụng thay đổi ngay lập tức, hãy làm một trong hai việc sau:"
echo "1. Chạy lệnh sau:"
echo -e "\033[1;32msource $CONFIG_FILE\033[0m"
echo "2. Hoặc đơn giản là đóng và mở lại cửa sổ terminal của bạn."
