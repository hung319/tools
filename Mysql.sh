#!/bin/bash
set -e

# ==== CONFIG ====
MYSQL_VERSION="8.0.34"
MYSQL_USER="hung319"
MYSQL_PASS="11042006"
MYSQL_PORT="3307"
MYSQL_DIR="$HOME/mysql"
MYSQL_DATA="$MYSQL_DIR/data"
LIB_DIR="$HOME/.local/lib"

# ==== Detect architecture ====
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  MYSQL_PKG="mysql-${MYSQL_VERSION}-linux-glibc2.12-x86_64.tar.xz" ;;
    aarch64) MYSQL_PKG="mysql-${MYSQL_VERSION}-linux-glibc2.17-aarch64.tar.xz" ;;
    *) echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
esac

# ==== Update LD_LIBRARY_PATH in bashrc ====
if ! grep -q "LD_LIBRARY_PATH" ~/.bashrc; then
    echo "export LD_LIBRARY_PATH=$LIB_DIR:\$LD_LIBRARY_PATH" >> ~/.bashrc
fi

# ==== Create dirs ====
mkdir -p "$MYSQL_DIR" "$MYSQL_DATA" "$LIB_DIR"
cd "$MYSQL_DIR"

# ==== Download & extract MySQL ====
if [ ! -f "$MYSQL_PKG" ]; then
    wget "https://dev.mysql.com/get/Downloads/MySQL-8.0/$MYSQL_PKG"
fi
tar -xf "$MYSQL_PKG"

# Lấy chính xác thư mục MySQL đã giải nén
MYSQL_BASE=$(find "$MYSQL_DIR" -maxdepth 1 -type d -name "mysql-${MYSQL_VERSION}-linux-glibc2.*" | head -n 1)

# ==== Add MySQL bin to PATH in bashrc ====
if ! grep -q "$MYSQL_BASE/bin" ~/.bashrc; then
    echo "export PATH=$MYSQL_BASE/bin:\$PATH" >> ~/.bashrc
fi

# ==== Build dependencies ====
# libaio
wget -nc http://ftp.de.debian.org/debian/pool/main/liba/libaio/libaio_0.3.112.orig.tar.xz
tar -xf libaio_0.3.112.orig.tar.xz
cd libaio-0.3.112/
make
cp src/libaio.so.1.* "$LIB_DIR/"
cd "$LIB_DIR"
ln -sf libaio.so.1.* libaio.so.1
cd "$MYSQL_DIR"

# ncurses
wget -nc https://ftp.gnu.org/pub/gnu/ncurses/ncurses-6.4.tar.gz
tar -xf ncurses-6.4.tar.gz
cd ncurses-6.4/
./configure --prefix=$HOME/.local --with-shared
make
make install
cd "$MYSQL_DIR"

# libtinfo (amd64 & arm64)
case "$ARCH" in
    x86_64)  LIBTINFO_DEB="libtinfo5_6.2+20201114-2+deb11u2_amd64.deb" ;;
    aarch64) LIBTINFO_DEB="libtinfo5_6.2+20201114-2+deb11u2_arm64.deb" ;;
esac
wget -nc "http://ftp.de.debian.org/debian/pool/main/n/ncurses/$LIBTINFO_DEB"
ar -x "$LIBTINFO_DEB"
tar -xf data.tar.* || true
cp lib/x86_64-linux-gnu/libtinfo.so.5.9 "$LIB_DIR/" 2>/dev/null || true
cp lib/aarch64-linux-gnu/libtinfo.so.5.9 "$LIB_DIR/" 2>/dev/null || true
cd "$LIB_DIR"
ln -sf libtinfo.so.5.9 libtinfo.so.5
cd "$MYSQL_DIR"

# ==== Init MySQL data dir ====
"$MYSQL_BASE/bin/mysqld" --initialize-insecure \
  --user=$(whoami) \
  --basedir="$MYSQL_BASE" \
  --datadir="$MYSQL_DATA" \
  --port=$MYSQL_PORT

# ==== Start MySQL (background) ====
"$MYSQL_BASE/bin/mysqld" --user=$(whoami) \
  --basedir="$MYSQL_BASE" \
  --datadir="$MYSQL_DATA" \
  --port=$MYSQL_PORT &

sleep 5

# ==== Setup users ====
"$MYSQL_BASE/bin/mysql" -u root -e "
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_PASS}';
FLUSH PRIVILEGES;
CREATE USER '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASS}';
GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
"

echo "✅ MySQL ${MYSQL_VERSION} setup completed!"
echo "👉 Start server with:"
echo "   mysqld --user=\$(whoami) --basedir=$MYSQL_BASE --datadir=$MYSQL_DATA --port=$MYSQL_PORT"
echo "👉 Connect with:"
echo "   mysql -u ${MYSQL_USER} -p${MYSQL_PASS} -P ${MYSQL_PORT}"
