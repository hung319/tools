#!/bin/bash

# ==============================================================================
# Script chỉ tải và thiết lập mã nguồn WordPress.
# Yêu cầu: Đã có sẵn Web Server, PHP, và MariaDB/MySQL.
#
# Tác giả: Gemini
# Phiên bản: 1.1
# ==============================================================================

# --- Cấu hình đường dẫn ---
INSTALL_DIR="$HOME/.local/wordpress"
WWW_DIR="$INSTALL_DIR/www"

# --- Màu sắc cho output ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Hàm hỗ trợ ---
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# --- Bắt đầu script ---
clear
info "Bắt đầu quá trình thiết lập WordPress..."
info "Mã nguồn sẽ được cài đặt vào thư mục: $WWW_DIR"
echo "---------------------------------------------------------"

# 1. Tạo cấu trúc thư mục
info "Tạo thư mục đích..."
mkdir -p "$WWW_DIR"
cd "$WWW_DIR" || exit 1

# 2. Tải và giải nén WordPress
info "Tải phiên bản WordPress mới nhất..."
wget -q --show-progress "https://wordpress.org/latest.tar.gz" -O "wordpress.tar.gz"

info "Giải nén mã nguồn..."
tar -xzf "wordpress.tar.gz" --strip-components=1
rm "wordpress.tar.gz"

# 3. Tạo file cấu hình
info "Chuẩn bị file wp-config.php..."
if [ -f "wp-config-sample.php" ]; then
    mv wp-config-sample.php wp-config.php
else
    info "File wp-config.php đã tồn tại, bỏ qua bước tạo mới."
fi

# Cấp quyền ghi cho web server (nếu cần)
# Tùy thuộc vào user mà Apache/Nginx đang chạy, bạn có thể cần lệnh này.
# chmod -R g+w "$WWW_DIR/wp-content"

# --- Hoàn tất ---
echo "---------------------------------------------------------"
info "THIẾT LẬP MÃ NGUỒN WORDPRESS HOÀN TẤT!"
echo -e "${YELLOW}Vui lòng thực hiện các bước tiếp theo:${NC}"
echo ""
echo -e "1. ${CYAN}Trỏ Web Server của bạn vào thư mục gốc:${NC}"
echo -e "   ${GREEN}$WWW_DIR${NC}"
echo ""
echo -e "2. ${CYAN}Tạo Cơ sở dữ liệu và Người dùng trong MariaDB:${NC}"
echo -e "   a. Đăng nhập vào MariaDB: ${GREEN}mysql -u root -p${NC}"
echo -e "   b. Chạy các lệnh SQL sau (thay thông tin của bạn):"
echo "      CREATE DATABASE ${GREEN}wordpress_db${NC};"
echo "      CREATE USER '${GREEN}wp_user${NC}'@'localhost' IDENTIFIED BY '${GREEN}your_strong_password${NC}';"
echo "      GRANT ALL PRIVILEGES ON ${GREEN}wordpress_db${NC}.* TO '${GREEN}wp_user${NC}'@'localhost';"
echo "      FLUSH PRIVILEGES;"
echo "      EXIT;"
echo ""
echo -e "3. ${CYAN}Cập nhật file cấu hình WordPress:${NC}"
echo -e "   - Mở file: ${GREEN}$WWW_DIR/wp-config.php${NC}"
echo "   - Điền thông tin cơ sở dữ liệu bạn vừa tạo (DB_NAME, DB_USER, DB_PASSWORD)."
echo ""
echo -e "4. ${CYAN}Hoàn tất cài đặt trên trình duyệt:${NC}"
echo "   - Truy cập vào địa chỉ web của bạn để bắt đầu trình cài đặt 5 phút của WordPress."
echo "---------------------------------------------------------"
