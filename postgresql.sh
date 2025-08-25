#!/bin/bash

set -e

# === CONFIG ===
# Phiên bản của các phần mềm
PG_VERSION="16.3"
OPENSSL_VERSION="1.1.1u"
LIBXML2_VERSION="2.14.5"
NSS_WRAPPER_VERSION="1.1.15"

# Đường dẫn cài đặt cho các thư viện phụ thuộc (openssl, libxml2)
# Giữ ở ~/.local để không lẫn với PostgreSQL
DEPS_INSTALL_PREFIX="$HOME/.local"

# (THAY ĐỔI) Đường dẫn cho PostgreSQL và tất cả dữ liệu runtime
# Tất cả mọi thứ của PostgreSQL (binary, lib, data, log) sẽ nằm ở đây
PG_RUNTIME_DIR="$HOME/pgsql"
PG_DATA="$PG_RUNTIME_DIR/data"
NSS_DIR="$PG_RUNTIME_DIR/fakeuser"

# Cấu hình khác
PORT=5432
TMPDIR="${TMPDIR:-$HOME/.tmp-build}" # Thư mục tạm để build, tách riêng
PG_USER="hung319"
PG_PASSWORD="11042006" # Bạn nên thay đổi mật khẩu này

# === Setup ===
# Tạo các thư mục cần thiết
mkdir -p "$DEPS_INSTALL_PREFIX/bin" "$DEPS_INSTALL_PREFIX/lib" "$PG_RUNTIME_DIR" "$NSS_DIR" "$TMPDIR" "$PG_DATA"

# (TỐI ƯU) Đặt các biến môi trường để trình biên dịch và runtime tìm đúng thư viện
# Cần cả đường dẫn của DEPS và PG sau khi cài đặt
export CFLAGS="-I$DEPS_INSTALL_PREFIX/include"
export LDFLAGS="-L$DEPS_INSTALL_PREFIX/lib"
export LD_LIBRARY_PATH="$PG_RUNTIME_DIR/lib:$DEPS_INSTALL_PREFIX/lib:$LD_LIBRARY_PATH"
export PATH="$PG_RUNTIME_DIR/bin:$DEPS_INSTALL_PREFIX/bin:$PATH"

# --- Build OpenSSL ---
echo "🔎 Kiểm tra OpenSSL..."
if [ ! -f "$DEPS_INSTALL_PREFIX/lib/libssl.so" ]; then
    echo "🚀 OpenSSL chưa được cài đặt. Bắt đầu build v$OPENSSL_VERSION..."
    cd "$TMPDIR"
    curl -LO "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz"
    tar -xzf "openssl-$OPENSSL_VERSION.tar.gz"
    cd "openssl-$OPENSSL_VERSION"
    ./config --prefix="$DEPS_INSTALL_PREFIX" --openssldir="$DEPS_INSTALL_PREFIX/ssl"
    make -j$(nproc)
    make install_sw # Chỉ cài đặt thư viện, bỏ qua docs để nhanh hơn
else
    echo "✅ OpenSSL đã được cài đặt. Bỏ qua."
fi

# --- Build libxml2 ---
echo "🔎 Kiểm tra libxml2..."
if [ ! -f "$DEPS_INSTALL_PREFIX/lib/libxml2.so" ]; then
    echo "🚀 libxml2 chưa được cài đặt. Bắt đầu build v$LIBXML2_VERSION..."
    cd "$TMPDIR"
    curl -LO "https://download.gnome.org/sources/libxml2/${LIBXML2_VERSION%.*}/libxml2-$LIBXML2_VERSION.tar.xz"
    tar -xf "libxml2-$LIBXML2_VERSION.tar.xz"
    cd "libxml2-$LIBXML2_VERSION"
    ./configure --prefix="$DEPS_INSTALL_PREFIX" --without-python
    make -j$(nproc)
    make install
else
    echo "✅ libxml2 đã được cài đặt. Bỏ qua."
fi

# --- Download và build PostgreSQL ---
PG_SRC="postgresql-$PG_VERSION"
echo "🔎 Kiểm tra PostgreSQL..."
# (THAY ĐỔI) Kiểm tra psql ở đường dẫn cài đặt mới
if [ ! -f "$PG_RUNTIME_DIR/bin/psql" ]; then
    echo "🚀 PostgreSQL chưa được cài đặt. Bắt đầu build v$PG_VERSION..."
    cd "$TMPDIR" # Build trong thư mục tạm
    curl -LO "https://ftp.postgresql.org/pub/source/v$PG_VERSION/$PG_SRC.tar.gz"
    tar -xzf "$PG_SRC.tar.gz"
    cd "$PG_SRC"

    # (THAY ĐỔI) --prefix trỏ thẳng vào PG_RUNTIME_DIR
    # Configure sẽ tự động sử dụng OpenSSL và libxml2 đã cài ở ~/.local nhờ các biến môi trường
    ./configure --prefix="$PG_RUNTIME_DIR" \
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
if [ ! -f "$NSS_DIR/$NSS_SRC/build/src/libnss_wrapper.so" ]; then
    echo "🚀 nss_wrapper chưa được cài đặt. Bắt đầu build..."
    cd "$NSS_DIR"
    curl -LO "https://ftp.samba.org/pub/cwrap/${NSS_SRC}.tar.gz"
    tar -xzf "${NSS_SRC}.tar.gz"
    cd "$NSS_SRC"
    mkdir -p build && cd build
    cmake .. -DCMAKE_INSTALL_PREFIX="$NSS_DIR"
    make -j$(nproc)
else
    echo "✅ nss_wrapper đã được build. Bỏ qua."
fi

# --- Fake passwd & group dựa trên PG_USER (giữ nguyên) ---
cd "$PG_RUNTIME_DIR"
uid=$(id -u)
gid=$(id -g)
echo "$PG_USER:x:$uid:$gid:PostgreSQL User:$HOME:/bin/bash" > "$PG_RUNTIME_DIR/passwd.fake"
echo "$PG_USER:x:$gid:" > "$PG_RUNTIME_DIR/group.fake"

# --- Export env (runtime) ---
# Cập nhật lại các biến môi trường cho session hiện tại
export LD_PRELOAD="$NSS_DIR/$NSS_SRC/build/src/libnss_wrapper.so"
export NSS_WRAPPER_PASSWD="$PG_RUNTIME_DIR/passwd.fake"
export NSS_WRAPPER_GROUP="$PG_RUNTIME_DIR/group.fake"
export PGUSER="$PG_USER"
export PGPASSWORD="$PG_PASSWORD"
export PGDATABASE="$PG_USER"
export PGHOST="0.0.0.0"

# --- Add vào shell config nếu chưa có ---
SHELL_NAME=$(basename "$SHELL")
if [ "$SHELL_NAME" = "bash" ]; then
    PROFILE_FILE="$HOME/.bashrc"
elif [ "$SHELL_NAME" = "zsh" ]; then
    PROFILE_FILE="$HOME/.zshrc"
else
    PROFILE_FILE="$HOME/.profile"
fi

# (THAY ĐỔI) Cập nhật PATH và LD_LIBRARY_PATH cho file cấu hình shell
EXPORTS=$(cat <<EOF

# PostgreSQL local setup
export LD_PRELOAD="\$HOME/pgsql/fakeuser/nss_wrapper-$NSS_WRAPPER_VERSION/build/src/libnss_wrapper.so"
export NSS_WRAPPER_PASSWD="\$HOME/pgsql/passwd.fake"
export NSS_WRAPPER_GROUP="\$HOME/pgsql/group.fake"
export PATH="\$HOME/pgsql/bin:\$HOME/.local/bin:\$PATH"
export LD_LIBRARY_PATH="\$HOME/pgsql/lib:\$HOME/.local/lib:\$LD_LIBRARY_PATH"
export PGUSER="$PG_USER"
export PGPASSWORD="$PG_PASSWORD"
export PGDATABASE="$PG_USER"
export PGHOST="0.0.0.0"
EOF
)

if ! grep -q "NSS_WRAPPER_PASSWD" "$PROFILE_FILE"; then
    echo "📝 Đã thêm cấu hình vào $PROFILE_FILE"
    echo "$EXPORTS" >> "$PROFILE_FILE"
fi

# --- Init database cluster ---
if [ ! -f "$PG_DATA/PG_VERSION" ]; then
    echo "🚀 Khởi tạo database cluster..."
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
fi

# --- Start PostgreSQL (wait) ---
echo "🚀 Khởi động PostgreSQL..."
pg_ctl -D "$PG_DATA" -l "$PG_RUNTIME_DIR/logfile" -w start

# --- Tạo user PostgreSQL và DB ---
echo "👤 Tạo role và database cho user '$PG_USER'..."
psql -U "$PG_USER" -p $PORT -d postgres -c "DO \$\$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$PG_USER') THEN CREATE ROLE $PG_USER WITH LOGIN SUPERUSER PASSWORD '$PG_PASSWORD'; ELSE ALTER ROLE $PG_USER WITH PASSWORD '$PG_PASSWORD'; END IF; END \$\$;"

createdb -U "$PG_USER" -p $PORT "$PG_USER" || true
psql -U "$PG_USER" -p "$PORT" -d "$PG_USER" -c "CREATE EXTENSION IF NOT EXISTS pgcrypto;"

echo
echo "✅ PostgreSQL $PG_VERSION đã được cài đặt và cấu hình thành công!"
echo "   - Toàn bộ PostgreSQL và dữ liệu được cài tại: $PG_RUNTIME_DIR"
echo "   - Các thư viện phụ thuộc (OpenSSL,...) tại: $DEPS_INSTALL_PREFIX"
echo "🔐 User: $PG_USER | Password: $PG_PASSWORD"
echo "📦 Extension 'pgcrypto' đã được kích hoạt."
echo "🌐 PGHOST mặc định: 0.0.0.0"
echo "💡 Để sử dụng ngay, hãy chạy: source $PROFILE_FILE"
