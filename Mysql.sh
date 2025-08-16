#!/bin/bash
set -e

# ==== CONFIG ====
MYSQL_DIR="$HOME/mysql"              # Folder cài MySQL
DATA_DIR="$MYSQL_DIR/data"           # Data folder
MYSQL_VERSION="8.0.34"               # Phiên bản MySQL
PASS="11042006"                      # Mật khẩu root và user mới
NEW_USER="hung319"                   # User mới
PORT=3307                            # Port MySQL
# =================

mkdir -p "$MYSQL_DIR" "$DATA_DIR"
cd "$MYSQL_DIR"

# ==== Detect kiến trúc ====
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    MYSQL_PKG="mysql-${MYSQL_VERSION}-linux-glibc2.12-x86_64.tar.xz"
    LIBTINFO_DEB="libtinfo5_6.2+20201114-2+deb11u2_amd64.deb"
elif [[ "$ARCH" == "aarch64" ]]; then
    MYSQL_PKG="mysql-${MYSQL_VERSION}-linux-glibc2.17-aarch64.tar.xz"
    LIBTINFO_DEB="libtinfo5_6.2+20201114-2+deb11u2_arm64.deb"
else
    echo "❌ Kiến trúc $ARCH chưa được hỗ trợ!"
    exit 1
fi
echo "✅ Phát hiện kiến trúc: $ARCH"

# ==== Download & extract MySQL ====
if [ ! -f "$MYSQL_PKG" ]; then
    wget "https://dev.mysql.com/get/Downloads/MySQL-8.0/$MYSQL_PKG"
fi
tar -xf "$MYSQL_PKG"

MYSQL_BASE="$MYSQL_DIR/mysql-${MYSQL_VERSION}-linux-glibc2."*

# ==== Cài libaio ====
wget -q http://ftp.de.debian.org/debian/pool/main/liba/libaio/libaio_0.3.112.orig.tar.xz
tar -xf libaio_0.3.112.orig.tar.xz
cd libaio-0.3.112
make
cp src/libaio.so.1.* ~/.local/lib/
cd ~/.local/lib
ln -sf libaio.so.1.* libaio.so.1
cd "$MYSQL_DIR"

# ==== Cài ncurses ====
wget -q https://ftp.gnu.org/pub/gnu/ncurses/ncurses-6.4.tar.gz
tar -xf ncurses-6.4.tar.gz
cd ncurses-6.4
./configure --prefix=$HOME/.local --with-shared
make
make install
cd "$MYSQL_DIR"

# ==== Cài libtinfo phù hợp kiến trúc ====
wget -q "http://ftp.de.debian.org/debian/pool/main/n/ncurses/$LIBTINFO_DEB"
ar -x "$LIBTINFO_DEB"
tar -xf data.tar.xz
if [[ "$ARCH" == "x86_64" ]]; then
    cp lib/x86_64-linux-gnu/libtinfo.so.5.9 ~/.local/lib/
elif [[ "$ARCH" == "aarch64" ]]; then
    cp lib/aarch64-linux-gnu/libtinfo.so.5.9 ~/.local/lib/
fi
cd ~/.local/lib
ln -sf libtinfo.so.5.9 libtinfo.so.5
cd "$MYSQL_DIR"

# ==== Tạo config file ====
cat > "$MYSQL_DIR/my.cnf" <<EOF
[mysqld]
basedir=$MYSQL_BASE
datadir=$DATA_DIR
port=$PORT
socket=$MYSQL_DIR/mysql.sock
EOF

# ==== Khởi tạo MySQL ====
"$MYSQL_BASE/bin/mysqld" --defaults-file="$MYSQL_DIR/my.cnf" --initialize-insecure --user=$(whoami)

# ==== Đổi pass root + tạo user mới ====
"$MYSQL_BASE/bin/mysqld" --defaults-file="$MYSQL_DIR/my.cnf" --daemonize --user=$(whoami)
sleep 5
"$MYSQL_BASE/bin/mysql" -u root -e "
ALTER USER 'root'@'localhost' IDENTIFIED BY '$PASS';
CREATE USER '$NEW_USER'@'localhost' IDENTIFIED BY '$PASS';
GRANT ALL PRIVILEGES ON *.* TO '$NEW_USER'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;"

# ==== Done ====
echo ""
echo "✅ MySQL $MYSQL_VERSION đã được cài đặt thành công!"
echo "📂 Thư mục: $MYSQL_BASE"
echo "⚙️  Config: $MYSQL_DIR/my.cnf"
echo "🔑 Root & $NEW_USER password: $PASS"
echo ""
echo "👉 Lệnh chạy mysqld:"
echo "$MYSQL_BASE/bin/mysqld --defaults-file=$MYSQL_DIR/my.cnf --user=$(whoami)"
