#!/bin/bash

set -e

# === CONFIG ===
# Phiên bản của các phần mềm
PG_VERSION="16.3"
OPENSSL_VERSION="1.1.1w" # Cập nhật phiên bản OpenSSL
LIBXML2_VERSION="2.12.7" # Cập nhật phiên bản libxml2
NSS_WRAPPER_VERSION="1.1.15"

### THAY ĐỔI: Cấu trúc lại toàn bộ đường dẫn theo yêu cầu ###

# Thư mục chứa mã nguồn tải về để biên dịch
SRC_DIR="$HOME/src"

# Thư mục cài đặt cho PostgreSQL và các thư viện phụ thuộc (bin, lib, include, etc.)
INSTALL_DIR="$HOME/.local"

# Thư mục chứa dữ liệu, cấu hình, và các file runtime của PostgreSQL
DATABASE_DIR="$HOME/database/pgsql"
PG_DATA="$DATABASE_DIR/data"
NSS_DIR="$DATABASE_DIR/nss_wrapper" # nss_wrapper là một phần của runtime, đặt ở đây

# Cấu hình khác
PORT=5432
PG_USER="myuser"
PG_PASSWORD="mypassword" # Bạn nên thay đổi mật khẩu này

# === Setup ===
# Tạo các thư mục cần thiết
echo "🚀 Chuẩn bị các thư mục..."
mkdir -p "$SRC_DIR" "$INSTALL_DIR/bin" "$INSTALL_DIR/lib" "$DATABASE_DIR" "$NSS_DIR" "$PG_DATA"

# (TỐI ƯU) Đặt các biến môi trường để trình biên dịch và runtime tìm đúng thư viện
export CFLAGS="-I$INSTALL_DIR/include"
export LDFLAGS="-L$INSTALL_DIR/lib -Wl,-rpath,$INSTALL_DIR/lib" # -rpath giúp runtime tìm lib
export LD_LIBRARY_PATH="$INSTALL_DIR/lib:$LD_LIBRARY_PATH"
export PATH="$INSTALL_DIR/bin:$PATH"

# --- Build OpenSSL ---
echo "🔎 Kiểm tra OpenSSL..."
if [ ! -f "$INSTALL_DIR/lib/libssl.so" ]; then
    echo "🚀 OpenSSL chưa được cài đặt. Bắt đầu build v$OPENSSL_VERSION..."
    cd "$SRC_DIR" ### THAY ĐỔI: làm việc trong thư mục src
    curl -LO "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz"
    tar -xzf "openssl-$OPENSSL_VERSION.tar.gz"
    cd "openssl-$OPENSSL_VERSION"
    ./config --prefix="$INSTALL_DIR" --openssldir="$INSTALL_DIR/ssl"
    make -j$(nproc)
    make install_sw # Chỉ cài đặt thư viện, bỏ qua docs để nhanh hơn
else
    echo "✅ OpenSSL đã được cài đặt. Bỏ qua."
fi

# --- Build libxml2 ---
echo "🔎 Kiểm tra libxml2..."
if [ ! -f "$INSTALL_DIR/lib/libxml2.so" ]; then
    echo "🚀 libxml2 chưa được cài đặt. Bắt đầu build v$LIBXML2_VERSION..."
    cd "$SRC_DIR" ### THAY ĐỔI: làm việc trong thư mục src
    curl -LO "https://download.gnome.org/sources/libxml2/${LIBXML2_VERSION%.*}/libxml2-$LIBXML2_VERSION.tar.xz"
    tar -xf "libxml2-$LIBXML2_VERSION.tar.xz"
    cd "libxml2-$LIBXML2_VERSION"
    ./configure --prefix="$INSTALL_DIR" --without-python
    make -j$(nproc)
    make install
else
    echo "✅ libxml2 đã được cài đặt. Bỏ qua."
fi

# --- Download và build PostgreSQL ---
echo "🔎 Kiểm tra PostgreSQL..."
### THAY ĐỔI: Kiểm tra psql ở đường dẫn cài đặt mới
if [ ! -f "$INSTALL_DIR/bin/psql" ]; then
    echo "🚀 PostgreSQL chưa được cài đặt. Bắt đầu build v$PG_VERSION..."
    cd "$SRC_DIR" ### THAY ĐỔI: làm việc trong thư mục src
    curl -LO "https://ftp.postgresql.org/pub/source/v$PG_VERSION/postgresql-$PG_VERSION.tar.gz"
    tar -xzf "postgresql-$PG_VERSION.tar.gz"
    cd "postgresql-$PG_VERSION"

    ### THAY ĐỔI: --prefix trỏ thẳng vào INSTALL_DIR (~/.local)
    ./configure --prefix="$INSTALL_DIR" \
      --with-openssl \
      --with-libxml \
      --without-icu

    make -j$(nproc)
    make install

    # Build toàn bộ extension trong contrib
    echo "🚀 Bắt đầu build các extension trong contrib..."
    cd contrib
    # Vòng lặp an toàn hơn, bỏ qua các file không phải thư mục
    for d in */ ; do
        (cd "$d" && make -j$(nproc) && make install) || echo "⚠️ Lỗi khi build extension $d, bỏ qua..."
    done
else
    echo "✅ PostgreSQL đã được cài đặt. Bỏ qua."
fi

# --- Build nss_wrapper ---
NSS_SRC="nss_wrapper-$NSS_WRAPPER_VERSION"
echo "🔎 Kiểm tra nss_wrapper..."
### THAY ĐỔI: Kiểm tra file .so trong thư mục đích
if [ ! -f "$NSS_DIR/lib/libnss_wrapper.so" ]; then
    echo "🚀 nss_wrapper chưa được cài đặt. Bắt đầu build..."
    cd "$SRC_DIR" ### THAY ĐỔI: làm việc trong thư mục src
    curl -LO "https://ftp.samba.org/pub/cwrap/${NSS_SRC}.tar.gz"
    tar -xzf "${NSS_SRC}.tar.gz"
    cd "$NSS_SRC"
    mkdir -p build && cd build
    ### THAY ĐỔI: Cài đặt vào thư mục đích trong DATABASE_DIR
    cmake .. -DCMAKE_INSTALL_PREFIX="$NSS_DIR"
    make -j$(nproc)
    make install
else
    echo "✅ nss_wrapper đã được build. Bỏ qua."
fi

# --- Fake passwd & group dựa trên PG_USER ---
### THAY ĐỔI: Tạo file fake trong DATABASE_DIR
uid=$(id -u)
gid=$(id -g)
echo "$PG_USER:x:$uid:$gid:PostgreSQL User:$HOME:/bin/bash" > "$DATABASE_DIR/passwd.fake"
echo "$PG_USER:x:$gid:" > "$DATABASE_DIR/group.fake"

# --- Export env (runtime) ---
# Cập nhật lại các biến môi trường cho session hiện tại
export LD_PRELOAD="$NSS_DIR/lib/libnss_wrapper.so"
export NSS_WRAPPER_PASSWD="$DATABASE_DIR/passwd.fake"
export NSS_WRAPPER_GROUP="$DATABASE_DIR/group.fake"
export PGUSER="$PG_USER"
export PGPASSWORD="$PG_PASSWORD"
export PGDATABASE="$PG_USER"
export PGHOST="127.0.0.1" # Đổi thành 127.0.0.1 cho an toàn hơn

# --- Add vào shell config nếu chưa có ---
SHELL_NAME=$(basename "$SHELL")
if [ "$SHE_NAME" = "bash" ]; then
    PROFILE_FILE="$HOME/.bashrc"
elif [ "$SHELL_NAME" = "zsh" ]; then
    PROFILE_FILE="$HOME/.zshrc"
else
    PROFILE_FILE="$HOME/.profile"
fi

### THAY ĐỔI: Cập nhật PATH và LD_LIBRARY_PATH cho file cấu hình shell
EXPORTS=$(cat <<EOF

# PostgreSQL local setup
export LD_PRELOAD="$NSS_DIR/lib/libnss_wrapper.so"
export NSS_WRAPPER_PASSWD="$DATABASE_DIR/passwd.fake"
export NSS_WRAPPER_GROUP="$DATABASE_DIR/group.fake"
export PATH="$INSTALL_DIR/bin:\$PATH"
export LD_LIBRARY_PATH="$INSTALL_DIR/lib:\$LD_LIBRARY_PATH"
export PGUSER="$PG_USER"
export PGPASSWORD="$PG_PASSWORD"
export PGDATABASE="$PG_USER"
export PGHOST="127.0.0.1"
EOF
)

if ! grep -q "NSS_WRAPPER_PASSWD" "$PROFILE_FILE"; then
    echo "📝 Đã thêm cấu hình vào $PROFILE_FILE"
    echo "$EXPORTS" >> "$PROFILE_FILE"
fi

# --- Init database cluster ---
if [ ! -f "$PG_DATA/PG_VERSION" ]; then
    echo "🚀 Khởi tạo database cluster tại $PG_DATA..."
    initdb -D "$PG_DATA" --no-locale --encoding=UTF8
else
    echo "✅ Database cluster đã tồn tại, bỏ qua bước khởi tạo."
fi

# --- Cấu hình postgresql.conf ---
echo "🔧 Cấu hình postgresql.conf..."
sed -i "s/^#\?port = .*/port = $PORT/" "$PG_DATA/postgresql.conf"
sed -i "s/^#\?listen_addresses = .*/listen_addresses = '*'/" "$PG_DATA/postgresql.conf"

# --- Cho phép remote access ---
if ! grep -q "host    all             all             0.0.0.0/0" "$PG_DATA/pg_hba.conf"; then
    echo "🔧 Cấu hình pg_hba.conf cho phép truy cập từ xa..."
    echo "host    all             all             0.0.0.0/0               scram-sha-256" >> "$PG_DATA/pg_hba.conf"
    echo "host    all             all             ::1/128                 scram-sha-256" >> "$PG_DATA/pg_hba.conf"
fi

# --- Start PostgreSQL (wait) ---
echo "🚀 Khởi động PostgreSQL..."
pg_ctl -D "$PG_DATA" -l "$DATABASE_DIR/logfile" -w start

# --- Tạo user PostgreSQL và DB ---
echo "👤 Tạo role và database cho user '$PG_USER'..."
psql -U "$(whoami)" -p $PORT -d postgres -c "DO \$\$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$PG_USER') THEN CREATE ROLE $PG_USER WITH LOGIN SUPERUSER PASSWORD '$PG_PASSWORD'; ELSE ALTER ROLE $PG_USER WITH PASSWORD '$PG_PASSWORD'; END IF; END \$\$;"

createdb -U "$(whoami)" -p $PORT "$PG_USER" || true
psql -U "$PG_USER" -p "$PORT" -d "$PG_USER" -c "CREATE EXTENSION IF NOT EXISTS pgcrypto;"

echo
echo "✅ PostgreSQL $PG_VERSION đã được cài đặt và cấu hình thành công!"
echo "   - Binaries & Libs được cài tại: $INSTALL_DIR"
echo "   - Data & Config được lưu tại:   $DATABASE_DIR"
echo "   - Mã nguồn được tải về tại:      $SRC_DIR"
echo "🔐 User: $PG_USER | Password: $PG_PASSWORD"
echo "📦 Extension 'pgcrypto' đã được kích hoạt."
echo "💡 Để sử dụng ngay, hãy chạy: source $PROFILE_FILE"
echo "👉 Để khởi động server sau này: pg_ctl -D $PG_DATA start"
echo "👉 Để dừng server: pg_ctl -D $PG_DATA stop"
