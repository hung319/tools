#!/bin/bash

# Dừng script nếu có lỗi xảy ra
set -e

# Cấu hình thư mục cài đặt
INSTALL_DIR="$HOME/.local/bin"
FFMPEG_URL="https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz"
TMP_DIR=$(mktemp -d)

echo "--- Bắt đầu cài đặt FFmpeg (phiên bản Static) ---"

# 1. Tạo thư mục bin cục bộ nếu chưa có
if [ ! -d "$INSTALL_DIR" ]; then
    echo "[+] Đang tạo thư mục $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR"
fi

# 2. Tải về bản build mới nhất
echo "[+] Đang tải FFmpeg từ $FFMPEG_URL..."
if command -v wget >/dev/null 2>&1; then
    wget -q --show-progress -O "$TMP_DIR/ffmpeg.tar.xz" "$FFMPEG_URL"
elif command -v curl >/dev/null 2>&1; then
    curl -L "$FFMPEG_URL" -o "$TMP_DIR/ffmpeg.tar.xz"
else
    echo "Lỗi: Cần có wget hoặc curl để tải file."
    exit 1
fi

# 3. Giải nén
echo "[+] Đang giải nén..."
tar -xf "$TMP_DIR/ffmpeg.tar.xz" -C "$TMP_DIR"

# Tìm thư mục vừa giải nén (vì tên thư mục thay đổi theo version)
EXTRACTED_DIR=$(find "$TMP_DIR" -maxdepth 1 -type d -name "ffmpeg-*-static" | head -n 1)

# 4. Di chuyển file chạy vào thư mục bin của user
echo "[+] Đang cài đặt vào $INSTALL_DIR..."
cp "$EXTRACTED_DIR/ffmpeg" "$INSTALL_DIR/"
cp "$EXTRACTED_DIR/ffprobe" "$INSTALL_DIR/"

# Cấp quyền thực thi (thường mặc định đã có, nhưng làm cho chắc)
chmod +x "$INSTALL_DIR/ffmpeg"
chmod +x "$INSTALL_DIR/ffprobe"

# 5. Dọn dẹp file tạm
rm -rf "$TMP_DIR"

# 6. Cấu hình PATH
SHELL_CONFIG=""
if [ -n "$BASH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
else
    # Mặc định thử bashrc nếu không phát hiện được shell
    SHELL_CONFIG="$HOME/.bashrc"
fi

echo "--- Cấu hình biến môi trường ---"

# Kiểm tra xem đường dẫn đã có trong PATH chưa
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "PATH hiện tại chưa chứa $INSTALL_DIR."
    
    # Kiểm tra xem đã từng thêm vào file config chưa để tránh thêm trùng lặp
    if grep -q "export PATH=\"$INSTALL_DIR:\$PATH\"" "$SHELL_CONFIG"; then
        echo "Đã tìm thấy cấu hình trong $SHELL_CONFIG."
    else
        echo "Đang thêm $INSTALL_DIR vào $SHELL_CONFIG..."
        echo "" >> "$SHELL_CONFIG"
        echo "# Add local bin to PATH" >> "$SHELL_CONFIG"
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$SHELL_CONFIG"
        echo "Đã cập nhật $SHELL_CONFIG."
    fi
else
    echo "Tuyệt vời! $INSTALL_DIR đã có sẵn trong PATH."
fi

echo "--- HOÀN TẤT ---"
echo "Để sử dụng ngay lập tức, hãy chạy lệnh sau:"
echo "source $SHELL_CONFIG"
echo ""
echo "Sau đó kiểm tra bằng lệnh: ffmpeg -version"
