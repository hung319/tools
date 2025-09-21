#!/bin/bash
# PHIÊN BẢN CUỐI CÙNG v12 - Sửa lỗi URL cho phiên bản 11.8.3

# --- PHẦN CẤU HÌNH ---
MARIADB_VERSION="11.8.3"
INSTALL_BASE_DIR="$HOME/database/mariadb"
DOWNLOAD_DIR="$HOME/src"
SOCKET_FILE="$INSTALL_BASE_DIR/tmp/mysql.sock"
PORT="3306"
SUPER_USER="admin"
SUPER_PASSWORD="admin" # <-- THAY ĐỔI MẬT KHẨU NÀY

# --- KẾT THÚC PHẦN CẤU HÌNH ---

# Các biến nội bộ
DATA_DIR="$INSTALL_BASE_DIR/data"
ARCH="x86_64"
# SỬA LỖI: Sửa lại cấu trúc URL cho đúng với phiên bản 11.8.3
DOWNLOAD_URL="https://archive.mariadb.org/mariadb-${MARIADB_VERSION}/bintar-linux-systemd-x86_64/mariadb-${MARIADB_VERSION}-linux-systemd-x86_64.tar.gz"
DOWNLOAD_FILE_PATH="$DOWNLOAD_DIR/mariadb-${MARIADB_VERSION}.tar.gz"
INSTALL_DIR_VERSIONED="$INSTALL_BASE_DIR/versions/mariadb-${MARIADB_VERSION}"
SYMLINK_DIR="$INSTALL_BASE_DIR/current"

# Hàm dọn dẹp
cleanup() {
    echo "-> Dọn dẹp file cài đặt..."
    rm -f "$DOWNLOAD_FILE_PATH"
    if pgrep -f "mariadbd-safe --defaults-file=${INSTALL_BASE_DIR}/my.cnf" > /dev/null; then
        echo "-> Đang cố gắng dừng server MariaDB..."
        "${SYMLINK_DIR}/bin/mariadb-admin" -u"${SUPER_USER}" -p"${SUPER_PASSWORD}" --socket="${SOCKET_FILE}" shutdown || echo "   Không thể dừng server, có thể nó đã tự tắt."
    fi
}
trap cleanup EXIT

# Bắt đầu script
echo "====================================================="
echo "  Bắt đầu cài đặt MariaDB ${MARIADB_VERSION} TỰ ĐỘNG"
echo "====================================================="

mkdir -p "$INSTALL_DIR_VERSIONED" "$DATA_DIR" "$INSTALL_BASE_DIR/tmp" "$DOWNLOAD_DIR"

echo "-> Bước 1: Tải MariaDB..."
wget -q --show-progress -c "$DOWNLOAD_URL" -O "$DOWNLOAD_FILE_PATH"

echo "-> Bước 1b: Kiểm tra file tải về bằng lệnh tar..."
if ! tar -tf "$DOWNLOAD_FILE_PATH" &> /dev/null; then
    echo "LỖI: File tải về không phải là file nén (tar.gz) hợp lệ."
    exit 1
fi
echo "   File hợp lệ."

echo "-> Bước 2: Giải nén file cài đặt..."
tar -xzf "$DOWNLOAD_FILE_PATH" -C "$INSTALL_DIR_VERSIONED" --strip-components=1

echo "-> Bước 3: Tạo symlink 'current'..."
ln -sfn "$INSTALL_DIR_VERSIONED" "$SYMLINK_DIR"

echo "-> Bước 4: Tạo file cấu hình my.cnf cho SERVER..."
cat > "$INSTALL_BASE_DIR/my.cnf" <<EOF
[mysqld]
basedir = ${SYMLINK_DIR}
datadir = ${DATA_DIR}
tmpdir  = ${INSTALL_BASE_DIR}/tmp
port    = ${PORT}
socket  = ${SOCKET_FILE}
bind-address = 0.0.0.0
user = $(whoami)
pid-file = ${INSTALL_BASE_DIR}/tmp/mariadb.pid
log_error = ${INSTALL_BASE_DIR}/tmp/mariadb-error.log
EOF

echo "-> Bước 5: Khởi tạo hệ thống cơ sở dữ liệu..."
"$SYMLINK_DIR/scripts/mariadb-install-db" --defaults-file="$INSTALL_BASE_DIR/my.cnf" --user=$(whoami)

echo "-> Bước 6: Cấu hình biến môi trường (PATH)..."
SHELL_CONFIG_FILE=""
if [[ "$SHELL" == *"bash"* ]]; then SHELL_CONFIG_FILE="$HOME/.bashrc"; elif [[ "$SHELL" == *"zsh"* ]]; then SHELL_CONFIG_FILE="$HOME/.zshrc"; fi
if [ -n "$SHELL_CONFIG_FILE" ] && ! grep -q "export PATH=\"${SYMLINK_DIR}/bin" "$SHELL_CONFIG_FILE"; then
    echo "   Thêm PATH vào ${SHELL_CONFIG_FILE}..."
    echo -e "\n# MariaDB custom installation\nexport PATH=\"${SYMLINK_DIR}/bin:\$PATH\"" >> "$SHELL_CONFIG_FILE"
fi

echo "-> Bước 7: Tạo các script tiện ích (start, stop, client)..."
cat > "$INSTALL_BASE_DIR/start.sh" <<EOF
#!/bin/bash
${SYMLINK_DIR}/bin/mariadbd-safe --defaults-file=${INSTALL_BASE_DIR}/my.cnf &
echo "Đã gửi yêu cầu khởi động MariaDB."
EOF
cat > "$INSTALL_BASE_DIR/stop.sh" <<EOF
#!/bin/bash
${SYMLINK_DIR}/bin/mariadb-admin -u${SUPER_USER} -p'${SUPER_PASSWORD}' --socket=${SOCKET_FILE} shutdown
echo "Đã gửi yêu cầu dừng MariaDB."
EOF
cat > "$INSTALL_BASE_DIR/client.sh" <<EOF
#!/bin/bash
${SYMLINK_DIR}/bin/mariadb -u${SUPER_USER} -p --socket=${SOCKET_FILE}
EOF
chmod +x "$INSTALL_BASE_DIR/start.sh" "$INSTALL_BASE_DIR/stop.sh" "$INSTALL_BASE_DIR/client.sh"

echo "-> Bước 8: Bắt đầu quá trình tự động hóa bảo mật..."
echo "   a. Khởi động server tạm thời..."
"${INSTALL_BASE_DIR}/start.sh"
echo -n "   b. Đang chờ MariaDB sẵn sàng..."
count=0
while [ ! -S "$SOCKET_FILE" ]; do
    if [ $count -gt 30 ]; then echo " Lỗi! Server không khởi động được."; exit 1; fi
    printf "."; sleep 1; ((count++))
done
echo " Sẵn sàng!"

SQL_SETUP="
ALTER USER 'root'@'localhost' IDENTIFIED BY '${SUPER_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
CREATE USER IF NOT EXISTS '${SUPER_USER}'@'%' IDENTIFIED BY '${SUPER_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO '${SUPER_USER}'@'%' WITH GRANT OPTION;
ALTER USER 'root'@'localhost' ACCOUNT LOCK;
FLUSH PRIVILEGES;
"
echo "   c. Thực thi các lệnh bảo mật và tạo người dùng..."
"${SYMLINK_DIR}/bin/mariadb" --socket="${SOCKET_FILE}" -u "$(whoami)" -e "${SQL_SETUP}"
echo "   d. Dừng server để hoàn tất quá trình cài đặt..."
"${INSTALL_BASE_DIR}/stop.sh"
sleep 2

# --- HOÀN TẤT ---
echo ""
echo "=========================================================="
echo "✅ HOÀN TẤT! Cài đặt và cấu hình MariaDB tự động thành công."
echo "=========================================================="
echo ""
echo " THÔNG TIN QUAN TRỌNG - VUI LÒNG LƯU LẠI"
echo "----------------------------------------------------------"
echo " Tài khoản 'root'@'localhost' mặc định đã bị VÔ HIỆU HÓA."
echo " Bạn sẽ quản trị MariaDB bằng tài khoản sau:"
echo "   > Tên người dùng: ${SUPER_USER}"
echo "   > Mật khẩu      : ${SUPER_PASSWORD}"
echo "----------------------------------------------------------"
echo ""
echo "Các bước tiếp theo:"
echo "1. Mở một terminal MỚI hoặc chạy: source ${SHELL_CONFIG_FILE:-~/.bashrc}"
echo "2. Khởi động server: cd ${INSTALL_BASE_DIR} && ./start.sh"
echo "3. Kết nối từ terminal bằng script mới:"
echo "   cd ${INSTALL_BASE_DIR} && ./client.sh"
echo ""
