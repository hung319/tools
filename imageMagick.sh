#!/bin/bash

#================================================================================
# SCRIPT BUILD IMAGEMAGICK TỪ SOURCE & TỰ ĐỘNG CẤU HÌNH SHELL (KHÔNG CẦN ROOT)
# - Tải source vào: ~/src
# - Cài đặt vào: ~/.local
# - Tự động phát hiện và cập nhật .bashrc hoặc .zshrc
#================================================================================

# Dừng script ngay nếu có lỗi
set -e

# --- Phần 1: Cấu hình ---
INSTALL_DIR="$HOME/.local"
SOURCE_DIR="$HOME/src"
IM_URL="https://imagemagick.org/archive/ImageMagick.tar.gz"
IM_FILENAME=$(basename "$IM_URL")

# Màu sắc để output dễ đọc hơn
C_BLUE="\033[0;34m"
C_GREEN="\033[0;32m"
C_YELLOW="\033[0;33m"
C_RESET="\033[0m"

# --- Phần 2: Kiểm tra các công cụ cần thiết ---
echo -e "${C_BLUE}▶ Kiểm tra các công cụ biên dịch (gcc, make, wget)...${C_RESET}"
for cmd in gcc make wget; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${C_YELLOW}❌ Lỗi: Lệnh '$cmd' không được tìm thấy. Vui lòng cài đặt và thử lại.${C_RESET}"
        exit 1
    fi
done
echo -e "${C_GREEN}✅ Đã có công cụ biên dịch.${C_RESET}"

# --- Phần 3: Chuẩn bị và Tải về ---
echo -e "\n${C_BLUE}▶ Chuẩn bị thư mục...${C_RESET}"
mkdir -p "$SOURCE_DIR" "$INSTALL_DIR"
cd "$SOURCE_DIR"

echo -e "${C_BLUE}▶ Tải về mã nguồn ImageMagick...${C_RESET}"
if [ ! -f "$IM_FILENAME" ]; then
    wget -q --show-progress -O "$IM_FILENAME" "$IM_URL"
else
    echo "    Tệp nguồn đã tồn tại, bỏ qua tải về."
fi

echo "    Dọn dẹp thư mục source cũ để đảm bảo build mới hoàn toàn..."
rm -rf ImageMagick-*

echo -e "${C_BLUE}▶ Giải nén mã nguồn...${C_RESET}"
tar -xzf "$IM_FILENAME"
cd ImageMagick-*/

# --- Phần 4: Cấu hình, Biên dịch và Cài đặt ---
echo -e "\n${C_BLUE}▶ Cấu hình quá trình biên dịch...${C_RESET}"
./configure --prefix="$INSTALL_DIR" --without-perl

echo -e "${C_BLUE}▶ Bắt đầu biên dịch (việc này có thể mất vài phút)...${C_RESET}"
make -j$(nproc)

echo -e "${C_BLUE}▶ Cài đặt vào thư mục ${INSTALL_DIR}...${C_RESET}"
make install
echo -e "${C_GREEN}✅ Cài đặt thư viện ImageMagick thành công!${C_RESET}"


# --- Phần 5: Tự động cập nhật Cấu hình Shell ---
echo -e "\n${C_BLUE}▶ Tự động cập nhật cấu hình shell...${C_RESET}"
SHELL_CONFIG_FILE=""
SHELL_NAME=$(basename "$SHELL")

if [ "$SHELL_NAME" = "bash" ]; then
    SHELL_CONFIG_FILE="$HOME/.bashrc"
elif [ "$SHELL_NAME" = "zsh" ]; then
    SHELL_CONFIG_FILE="$HOME/.zshrc"
fi

if [ -n "$SHELL_CONFIG_FILE" ]; then
    CONFIG_BLOCK="# Cấu hình cho ImageMagick cài đặt trong $INSTALL_DIR (thêm bởi script)
export PATH=\"$INSTALL_DIR/bin:\$PATH\"
export PKG_CONFIG_PATH=\"$INSTALL_DIR/lib/pkgconfig:\$PKG_CONFIG_PATH\"
export LD_LIBRARY_PATH=\"$INSTALL_DIR/lib:\$LD_LIBRARY_PATH\"
# Kết thúc khối cấu hình ImageMagick"

    # Kiểm tra xem cấu hình đã tồn tại chưa để tránh trùng lặp
    if grep -Fq "# Cấu hình cho ImageMagick" "$SHELL_CONFIG_FILE"; then
        echo -e "${C_GREEN}    Cấu hình đã tồn tại trong ${SHELL_CONFIG_FILE}. Không cần cập nhật.${C_RESET}"
    else
        echo "    Thêm cấu hình môi trường vào ${SHELL_CONFIG_FILE}..."
        # Thêm một dòng trống cho đẹp rồi mới thêm cấu hình
        echo "" >> "$SHELL_CONFIG_FILE"
        echo "$CONFIG_BLOCK" >> "$SHELL_CONFIG_FILE"
        echo -e "${C_GREEN}    Đã cập nhật ${SHELL_CONFIG_FILE} thành công!${C_RESET}"
    fi
else
    echo -e "${C_YELLOW}⚠️ Không thể tự động xác định tệp cấu hình cho shell '$SHELL_NAME'. Vui lòng thêm thủ công.${C_RESET}"
fi

# --- Phần 6: Hướng dẫn cuối cùng ---
echo -e "
${C_GREEN}🎉🎉 HOÀN TẤT! 🎉🎉${C_RESET}

${C_YELLOW}Vui lòng làm theo các bước cuối cùng sau:${C_RESET}

1.  **NẠP LẠI SHELL CỦA BẠN:**
    Mở một terminal MỚI, hoặc chạy lệnh sau trong terminal hiện tại:
    ${C_BLUE}${SHELL_CONFIG_FILE:+source $SHELL_CONFIG_FILE}${C_RESET}

2.  **Cài đặt extension PHP bằng \`pecl\`:**
    \`\`\`bash
    pecl install imagick
    \`\`\`

3.  **Kích hoạt trong \`php.ini\`:**
    a. Tìm tệp \`php.ini\` với lệnh: \`${C_BLUE}php --ini\`${C_RESET}
    b. Mở tệp đó và thêm dòng: \`${C_GREEN}extension=imagick.so\`${C_RESET}

4.  **Khởi động lại dịch vụ và Kiểm tra:**
    a. Khởi động lại Apache/Nginx/PHP-FPM.
    b. Kiểm tra bằng lệnh: \`${C_BLUE}php -m | grep imagick\`${C_RESET} (kết quả phải là 'imagick').
"
