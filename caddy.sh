#!/bin/bash

# Script tự động cài đặt Caddy trực tiếp vào ~/.local/bin cho người dùng hiện tại.

# --- Các biến ---
INSTALL_DIR="$HOME/.local/bin"
CADDY_BIN_PATH="$INSTALL_DIR/caddy"
CADDY_DOWNLOAD_API="https://caddyserver.com/api/download"

# --- Hàm thông báo ---
info() {
    echo "✅  $1"
}

warn() {
    echo "⚠️  $1"
}

# --- Bắt đầu thực thi ---
echo "Bắt đầu quá trình cài đặt Caddy trực tiếp vào $INSTALL_DIR..."

# 1. Tạo thư mục cài đặt nếu chưa có
info "Đang đảm bảo thư mục $INSTALL_DIR tồn tại..."
mkdir -p "$INSTALL_DIR"

# 2. Xác định kiến trúc hệ thống
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        CADDY_ARCH="amd64"
        ;;
    aarch64 | arm64)
        CADDY_ARCH="arm64"
        ;;
    armv7l)
        CADDY_ARCH="armv7"
        ;;
    *)
        warn "Không thể tự động xác định kiến trúc CPU ($ARCH). Đang thử tải bản amd64."
        CADDY_ARCH="amd64"
        ;;
esac
info "Kiến trúc CPU của bạn là: $CADDY_ARCH"

# 3. Tải Caddy trực tiếp vào thư mục cài đặt
DOWNLOAD_URL="${CADDY_DOWNLOAD_API}?os=linux&arch=${CADDY_ARCH}"

info "Đang tải phiên bản Caddy mới nhất vào $CADDY_BIN_PATH..."
if curl -L "$DOWNLOAD_URL" -o "$CADDY_BIN_PATH"; then
    info "Tải Caddy thành công."
else
    warn "Tải Caddy thất bại. Vui lòng kiểm tra lại kết nối mạng."
    exit 1
fi

# 4. Cấp quyền thực thi
info "Đang cấp quyền thực thi cho Caddy..."
chmod +x "$CADDY_BIN_PATH"

# 5. Phát hiện shell và cập nhật PATH
SHELL_CONFIG_FILE=""
CURRENT_SHELL=$(basename "$SHELL")

if [ "$CURRENT_SHELL" = "bash" ]; then
    SHELL_CONFIG_FILE="$HOME/.bashrc"
elif [ "$CURRENT_SHELL" = "zsh" ]; then
    SHELL_CONFIG_FILE="$HOME/.zshrc"
else
    warn "Không nhận diện được shell ($CURRENT_SHELL). Vui lòng tự thêm dòng sau vào file cấu hình shell của bạn:"
    echo "export PATH=\"$INSTALL_DIR:\$PATH\""
    exit 0
fi

info "Phát hiện shell: $CURRENT_SHELL. Sẽ kiểm tra file: $SHELL_CONFIG_FILE"

# 6. Kiểm tra và thêm PATH nếu cần
PATH_TO_ADD="export PATH=\"$INSTALL_DIR:\$PATH\""

if ! grep -q ".local/bin" "$SHELL_CONFIG_FILE"; then
    info "Đang thêm $INSTALL_DIR vào PATH trong file $SHELL_CONFIG_FILE..."
    echo "" >> "$SHELL_CONFIG_FILE"
    echo "# Thêm thư mục bin cục bộ vào PATH" >> "$SHELL_CONFIG_FILE"
    echo "$PATH_TO_ADD" >> "$SHELL_CONFIG_FILE"
    info "Đã thêm thành công."
else
    info "Đường dẫn $INSTALL_DIR đã tồn tại trong $SHELL_CONFIG_FILE. Bỏ qua."
fi

# --- Hoàn tất ---
echo ""
echo "🎉 Cài đặt Caddy hoàn tất! 🎉"
echo ""
echo "Để sử dụng lệnh 'caddy', bạn cần làm một trong hai việc sau:"
echo "1. Đóng và mở lại terminal."
echo "2. Hoặc chạy lệnh sau ngay bây giờ:"
echo "   source $SHELL_CONFIG_FILE"
echo ""
echo "Sau đó, hãy kiểm tra bằng cách chạy lệnh: caddy version"
