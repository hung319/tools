#!/bin/bash

# 1. Cấu hình thông số
GO_VERSION="1.22.0" # Bạn có thể thay đổi phiên bản tại đây
INSTALL_DIR="$HOME/.local"
GO_BIN_DIR="$INSTALL_DIR/go"
SHELL_CONFIG="$HOME/.bashrc"

# Xác định file config shell (hỗ trợ bash và zsh)
if [ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
fi

echo "--- Đang bắt đầu cài đặt Go $GO_VERSION vào $INSTALL_DIR ---"

# 2. Tạo thư mục .local nếu chưa có
mkdir -p "$INSTALL_DIR"

# 3. Xác định kiến trúc hệ thống
ARCH=$(uname -m)
case $ARCH in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    *) echo "Kiến trúc $ARCH không được hỗ trợ tự động."; exit 1 ;;
esac

# 4. Tải và giải nén
URL="https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz"
echo "Đang tải: $URL"

# Xóa bản cũ nếu có để tránh xung đột
rm -rf "$GO_BIN_DIR"

curl -L "$URL" | tar -C "$INSTALL_DIR" -xzf -

# 5. Thiết lập biến môi trường (Environment Variables)
# Kiểm tra xem PATH đã có Go chưa để tránh ghi đè nhiều lần
if ! grep -q "export PATH=\$PATH:$GO_BIN_DIR/bin" "$SHELL_CONFIG"; then
    echo "--- Đang thêm biến môi trường vào $SHELL_CONFIG ---"
    echo "" >> "$SHELL_CONFIG"
    echo "# Go Lang" >> "$SHELL_CONFIG"
    echo "export GOROOT=\"$GO_BIN_DIR\"" >> "$SHELL_CONFIG"
    echo "export GOPATH=\"\$HOME/go\"" >> "$SHELL_CONFIG"
    echo "export PATH=\"\$PATH:\$GOROOT/bin:\$GOPATH/bin\"" >> "$SHELL_CONFIG"
else
    echo "--- Biến môi trường Go đã tồn tại trong $SHELL_CONFIG ---"
fi

echo "--- Cài đặt hoàn tất! ---"
echo "Vui lòng chạy lệnh: source $SHELL_CONFIG"
echo "Sau đó kiểm tra bằng lệnh: go version"
