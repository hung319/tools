#!/bin/bash
set -e

# ==============================================================================
# Script cài đặt MySQL 8 không cần quyền root
# - Cài đặt binaries & libs vào: ~/.local
# - Lưu trữ data & config trong: ~/database/mysql
# - Tải file cài đặt về: ~/src
# ==============================================================================

# ==== CONFIG ====
MYSQL_VERSION="8.0.38" # Đã cập nhật lên phiên bản ổn định gần đây
MYSQL_USER="myuser"
MYSQL_PASS="mypassword"
MYSQL_PORT="3307"

### THAY ĐỔI: Cấu trúc thư mục mới theo yêu cầu ###
# Thư mục chứa file tải về
SRC_DIR="$HOME/src"
# Thư mục cài đặt chính cho binaries và libs
INSTALL_DIR="$HOME/.local"
# Thư mục cho data và config
DATABASE_DIR="$HOME/database/mysql"
MYSQL_DATA="$DATABASE_DIR/data"
MY_CNF="$DATABASE_DIR/my.cnf"
SOCKET_FILE="$DATABASE_DIR/mysql.sock"
# Thư mục lib (nằm trong thư mục cài đặt chính)
LIB_DIR="$INSTALL_DIR/lib"


# ==== Detect architecture ====
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  MYSQL_PKG="mysql-${MYSQL_VERSION}-linux-glibc2.28-x86_64.tar.xz" ;;
    aarch64) MYSQL_PKG="mysql-${MYSQL_VERSION}-linux-glibc2.28-aarch64.tar.xz" ;;
    *) echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
esac
MYSQL_URL="https://dev.mysql.com/get/Downloads/MySQL-8.0/$MYSQL_PKG"


# ==== Create dirs ====
echo "🚀 Chuẩn bị các thư mục..."
mkdir -p "$SRC_DIR" "$INSTALL_DIR" "$DATABASE_DIR" "$MYSQL_DATA" "$LIB_DIR"


# ==== Update environment in shell config ====
SHELL_CONFIG_FILE=""
if [[ "$SHELL" == *"bash"* ]]; then
    SHELL_CONFIG_FILE="$HOME/.bashrc"
elif [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_CONFIG_FILE="$HOME/.zshrc"
fi

if [ -n "$SHELL_CONFIG_FILE" ]; then
    echo "🖋️ Cập nhật file cấu hình shell: $SHELL_CONFIG_FILE"
    # Thêm PATH cho binaries của MySQL
    if ! grep -q "export PATH=$INSTALL_DIR/bin" "$SHELL_CONFIG_FILE"; then
        echo "export PATH=$INSTALL_DIR/bin:\$PATH" >> "$SHELL_CONFIG_FILE"
    fi
    # Thêm LD_LIBRARY_PATH cho các thư viện tự biên dịch
    if ! grep -q "export LD_LIBRARY_PATH=$LIB_DIR" "$SHELL_CONFIG_FILE"; then
        echo "export LD_LIBRARY_PATH=$LIB_DIR:\$LD_LIBRARY_PATH" >> "$SHELL_CONFIG_FILE"
    fi
else
    echo "⚠️ Không tìm thấy file .bashrc hoặc .zshrc. Vui lòng tự thêm PATH và LD_LIBRARY_PATH."
fi

# Xuất biến môi trường cho phiên hiện tại
export PATH="$INSTALL_DIR/bin:$PATH"
export LD_LIBRARY_PATH="$LIB_DIR:$LD_LIBRARY_PATH"


# ==== Download & extract MySQL ====
### THAY ĐỔI: Chuyển vào thư mục src để làm việc ###
cd "$SRC_DIR"

echo "📥 Đang tải MySQL..."
if [ ! -f "$MYSQL_PKG" ]; then
    wget -c "$MYSQL_URL"
fi

echo "📦 Đang giải nén MySQL vào $INSTALL_DIR..."
### THAY ĐỔI: Giải nén trực tiếp vào INSTALL_DIR và bỏ qua thư mục cha ###
# --strip-components=1 sẽ loại bỏ thư mục cấp cao nhất (vd: mysql-8.0.38-...)
tar -xf "$MYSQL_PKG" -C "$INSTALL_DIR" --strip-components=1


# ==== Build dependencies ====
echo "🛠️ Đang biên dịch các thư viện phụ thuộc..."

# libaio
LIBAIO_VER="0.3.113"
wget -nc "https://ftp.debian.org/debian/pool/main/liba/libaio/libaio_${LIBAIO_VER}.orig.tar.gz"
tar -xf "libaio_${LIBAIO_VER}.orig.tar.gz"
cd "libaio-${LIBAIO_VER}/"
make
cp src/libaio.so.1.* "$LIB_DIR/"
cd "$LIB_DIR"
ln -sf libaio.so.1.* libaio.so.1
cd "$SRC_DIR" # Quay lại thư mục src

# ncurses (cần cho mysql client)
NCURSES_VER="6.4"
wget -nc "https://ftp.gnu.org/pub/gnu/ncurses/ncurses-${NCURSES_VER}.tar.gz"
tar -xf "ncurses-${NCURSES_VER}.tar.gz"
cd "ncurses-${NCURSES_VER}/"
./configure --prefix="$INSTALL_DIR" --with-shared --without-debug --without-ada --enable-widec
make -j$(nproc)
make install
cd "$SRC_DIR" # Quay lại thư mục src


# ==== Config file ====
echo "📝 Tạo file cấu hình tại $MY_CNF..."
### THAY ĐỔI: Cập nhật đường dẫn trong file config ###
cat > "$MY_CNF" <<EOF
[mysqld]
basedir=$INSTALL_DIR
datadir=$MYSQL_DATA
port=$MYSQL_PORT
socket=$SOCKET_FILE
user=$(whoami)
bind-address=0.0.0.0

[client]
socket=$SOCKET_FILE
port=$MYSQL_PORT
EOF


# ==== Init MySQL data dir ====
echo "🚀 Khởi tạo cơ sở dữ liệu..."
"$INSTALL_DIR/bin/mysqld" --defaults-file="$MY_CNF" --initialize-insecure --user=$(whoami)


# ==== Start MySQL (background) ====
echo "🔥 Khởi động server MySQL..."
"$INSTALL_DIR/bin/mysqld" --defaults-file="$MY_CNF" --user=$(whoami) &

# Chờ server khởi động
echo "⏳ Chờ server sẵn sàng..."
sleep 10


# ==== Setup users ====
echo "🔑 Thiết lập người dùng và mật khẩu..."
"$INSTALL_DIR/bin/mysql" --socket="$SOCKET_FILE" -u root -e "
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_PASS}';
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${MYSQL_PASS}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASS}';
GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
"

echo ""
echo "✅ Cài đặt MySQL ${MYSQL_VERSION} hoàn tất!"
echo "======================================================"
echo "Vui lòng chạy 'source $SHELL_CONFIG_FILE' hoặc mở lại terminal để cập nhật môi trường."
echo ""
echo "👉 Lệnh khởi động server:"
echo "   mysqld --defaults-file=$MY_CNF"
echo ""
echo "👉 Lệnh kết nối:"
echo "   mysql -u ${MYSQL_USER} -p -h 127.0.0.1 -P ${MYSQL_PORT}"
echo "   (Mật khẩu: ${MYSQL_PASS})"
echo ""
echo "👉 Lệnh tắt server:"
echo "   mysqladmin -u root -p shutdown"
echo "======================================================"
