#!/bin/bash
set -e

# === CONFIG ===
PG_VERSION="18.0" # Cập nhật phiên bản
OPENSSL_VERSION="1.1.1w"
LIBXML2_VERSION="2.12.7"
NSS_WRAPPER_VERSION="1.1.15"

### CẤU TRÚC THƯ MỤC ###
SHARED_LIB_DIR="$HOME/.local"
PG_ROOT_DIR="$HOME/database/pgsql"
INSTALL_DIR="$PG_ROOT_DIR/postgresql-$PG_VERSION"
PG_DATA="$PG_ROOT_DIR/data"
NSS_DIR="$PG_ROOT_DIR/nss_wrapper"
SRC_DIR="$HOME/src"

### CẤU HÌNH KHÁC ###
PORT=5432
PG_USER="myuser"
PG_PASSWORD="mypassword"

# === Setup ===
echo "🚀 Chuẩn bị các thư mục..."
mkdir -p "$SRC_DIR" "$SHARED_LIB_DIR/bin" "$SHARED_LIB_DIR/lib" "$INSTALL_DIR" "$PG_DATA" "$NSS_DIR"

export CFLAGS="-I$SHARED_LIB_DIR/include"
export LDFLAGS="-L$SHARED_LIB_DIR/lib -Wl,-rpath,$SHARED_LIB_DIR/lib -Wl,-rpath,$INSTALL_DIR/lib"
export LD_LIBRARY_PATH="$INSTALL_DIR/lib:$SHARED_LIB_DIR/lib:$LD_LIBRARY_PATH"
export PATH="$INSTALL_DIR/bin:$SHARED_LIB_DIR/bin:$PATH"

# === KIỂM TRA NSS_WRAPPER (ĐÃ CẢI TIẾN) ===
USE_NSS_WRAPPER=false
BUILD_NSS_LOCALLY=false
LD_PRELOAD_LIB=""

echo "🔎 Kiểm tra nss_wrapper (logic mới)..."
if ! grep -q "^$(whoami):" /etc/passwd; then
    echo "👤 User '$(whoami)' không tồn tại trong /etc/passwd, nss_wrapper là cần thiết."
    USE_NSS_WRAPPER=true

    case "$LD_PRELOAD" in
        *libnss_wrapper.so*)
            echo "✅ Đã phát hiện libnss_wrapper.so trong biến môi trường LD_PRELOAD. Sẽ sử dụng nó."
            ;;
        *)
            SYSTEM_NSS_PATH=$(ldconfig -p | grep 'libnss_wrapper.so' | head -n 1 | awk 'NF>1{print $NF}' || true)
            if [ -n "$SYSTEM_NSS_PATH" ] && [ -f "$SYSTEM_NSS_PATH" ]; then
                echo "✅ Đã tìm thấy nss_wrapper của hệ thống tại: $SYSTEM_NSS_PATH. Sẽ sử dụng bản này."
                LD_PRELOAD_LIB="$SYSTEM_NSS_PATH"
            else
                echo "🔹 Không tìm thấy nss_wrapper có sẵn. Sẽ build một bản cục bộ."
                LD_PRELOAD_LIB="$NSS_DIR/lib/libnss_wrapper.so"
                BUILD_NSS_LOCALLY=true
            fi
            ;;
    esac
else
    echo "✅ User '$(whoami)' đã có trong /etc/passwd. Bỏ qua nss_wrapper."
fi

# --- Build thư viện chung ---
echo "🔎 Kiểm tra OpenSSL..."
if [ ! -f "$SHARED_LIB_DIR/lib/libssl.so" ]; then
    echo "🚀 Build OpenSSL v$OPENSSL_VERSION..."
    cd "$SRC_DIR"
    curl -LO "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz"
    tar -xzf "openssl-$OPENSSL_VERSION.tar.gz"
    cd "openssl-$OPENSSL_VERSION"
    ./config --prefix="$SHARED_LIB_DIR" --openssldir="$SHARED_LIB_DIR/ssl"
    make -j$(nproc)
    make install_sw
else
    echo "✅ OpenSSL đã được cài đặt."
fi

echo "🔎 Kiểm tra libxml2..."
if [ ! -f "$SHARED_LIB_DIR/lib/libxml2.so" ]; then
    echo "🚀 Build libxml2 v$LIBXML2_VERSION..."
    cd "$SRC_DIR"
    curl -LO "https://download.gnome.org/sources/libxml2/${LIBXML2_VERSION%.*}/libxml2-$LIBXML2_VERSION.tar.xz"
    tar -xf "libxml2-$LIBXML2_VERSION.tar.xz"
    cd "libxml2-$LIBXML2_VERSION"
    ./configure --prefix="$SHARED_LIB_DIR" --without-python
    make -j$(nproc)
    make install
else
    echo "✅ libxml2 đã được cài đặt."
fi

# --- Download và build PostgreSQL ---
echo "🔎 Kiểm tra PostgreSQL..."
if [ ! -f "$INSTALL_DIR/bin/psql" ]; then
    echo "🚀 Build PostgreSQL v$PG_VERSION..."
    cd "$SRC_DIR"
    curl -LO "https://ftp.postgresql.org/pub/source/v$PG_VERSION/postgresql-$PG_VERSION.tar.gz"
    tar -xzf "postgresql-$PG_VERSION.tar.gz"
    cd "postgresql-$PG_VERSION"

    echo "🔧 Tự động tìm và đổi tên tất cả thư mục 'specs' để tránh xung đột..."
    find . -type d -name specs -exec mv {} {}.bak \; || true
    echo "✅ Đã đổi tên xong."

    # SỬA LỖI: Bỏ thư mục 'build' và chạy configure ngay tại đây
    ./configure --prefix="$INSTALL_DIR" \
      --with-openssl \
      --with-libxml \
      --without-icu

    # SỬA LỖI: Build từng phần để bỏ qua tài liệu (docs)
    echo "🚀 Bắt đầu build server PostgreSQL chính..."
    make -j$(nproc)
    echo "🚀 Bắt đầu cài đặt server PostgreSQL chính..."
    make install

    echo "🚀 Bắt đầu build và cài đặt các extension trong contrib..."
    make -C contrib install -j$(nproc) || echo "⚠️  Một vài extension có thể đã không build được, nhưng quá trình vẫn tiếp tục."

else
    echo "✅ PostgreSQL đã được cài đặt."
fi

# --- (Các bước còn lại giữ nguyên) ---

if [ "$BUILD_NSS_LOCALLY" = true ]; then
    echo "🔎 Kiểm tra nss_wrapper..."
    if [ ! -f "$NSS_DIR/lib/libnss_wrapper.so" ]; then
        echo "🚀 Build nss_wrapper cục bộ..."
        cd "$SRC_DIR"
        curl -LO "https://ftp.samba.org/pub/cwrap/nss_wrapper-$NSS_WRAPPER_VERSION.tar.gz"
        tar -xzf "nss_wrapper-$NSS_WRAPPER_VERSION.tar.gz"
        cd "nss_wrapper-$NSS_WRAPPER_VERSION"
        mkdir -p build && cd build
        cmake .. -DCMAKE_INSTALL_PREFIX="$NSS_DIR"
        make -j$(nproc)
        make install
    else
        echo "✅ nss_wrapper cục bộ đã được build."
    fi

    uid=$(id -u)
    gid=$(id -g)
    echo "$PG_USER:x:$uid:$gid:PostgreSQL User:$HOME:/bin/bash" > "$PG_ROOT_DIR/passwd.fake"
    echo "$PG_USER:x:$gid:" > "$PG_ROOT_DIR/group.fake"
fi

SHELL_NAME=$(basename "$SHELL")
if [ "$SHELL_NAME" = "bash" ]; then
    PROFILE_FILE="$HOME/.bashrc"
elif [ "$SHELL_NAME" = "zsh" ]; then
    PROFILE_FILE="$HOME/.zshrc"
else
    PROFILE_FILE="$HOME/.profile"
fi

if ! grep -q "PostgreSQL $PG_VERSION local setup" "$PROFILE_FILE"; then
    COMMON_EXPORTS=$(cat <<EOF
export PATH="$INSTALL_DIR/bin:\$PATH"
export LD_LIBRARY_PATH="$INSTALL_DIR/lib:$SHARED_LIB_DIR/lib:\$LD_LIBRARY_PATH"
export PGUSER="$PG_USER"
export PGPASSWORD="$PG_PASSWORD"
export PGDATABASE="$PG_USER"
export PGHOST="127.0.0.1"
EOF
)
    if [ "$BUILD_NSS_LOCALLY" = true ]; then
        NSS_EXPORTS=$(cat <<EOF
export LD_PRELOAD="$LD_PRELOAD_LIB"
export NSS_WRAPPER_PASSWD="$PG_ROOT_DIR/passwd.fake"
export NSS_WRAPPER_GROUP="$PG_ROOT_DIR/group.fake"
EOF
)
        EXPORTS="# PostgreSQL $PG_VERSION local setup\n$NSS_EXPORTS\n$COMMON_EXPORTS"
    elif [ -n "$LD_PRELOAD_LIB" ]; then
         EXPORTS="# PostgreSQL $PG_VERSION local setup\nexport LD_PRELOAD=\"$LD_PRELOAD_LIB\"\n$COMMON_EXPORTS"
    else
        EXPORTS="# PostgreSQL $PG_VERSION local setup\n$COMMON_EXPORTS"
    fi
    echo "📝 Đã thêm cấu hình cho PostgreSQL $PG_VERSION vào $PROFILE_FILE"
    echo -e "\n$EXPORTS" >> "$PROFILE_FILE"
fi

source "$PROFILE_FILE"

if [ ! -f "$PG_DATA/PG_VERSION" ]; then
    echo "🚀 Khởi tạo database cluster..."
    initdb -D "$PG_DATA" --no-locale --encoding=UTF8
else
    echo "✅ Database cluster đã tồn tại."
fi

echo "🔧 Cấu hình postgresql.conf..."
sed -i "s/^#\?port = .*/port = $PORT/" "$PG_DATA/postgresql.conf"
sed -i "s/^#\?listen_addresses = .*/listen_addresses = '*'/" "$PG_DATA/postgresql.conf"

if ! grep -q "host    all             all             0.0.0.0/0" "$PG_DATA/pg_hba.conf"; then
    echo "🔧 Cấu hình pg_hba.conf..."
    echo "host    all             all             0.0.0.0/0               scram-sha-256" >> "$PG_DATA/pg_hba.conf"
    echo "host    all             all             ::1/128                 scram-sha-256" >> "$PG_DATA/pg_hba.conf"
fi

echo "🚀 Khởi động PostgreSQL..."
pg_ctl -D "$PG_DATA" -l "$PG_ROOT_DIR/logfile" -w start

echo "👤 Tạo role và database..."
psql -U "$(whoami)" -p $PORT -d postgres -c "DO \$\$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$PG_USER') THEN CREATE ROLE $PG_USER WITH LOGIN SUPERUSER PASSWORD '$PG_PASSWORD'; ELSE ALTER ROLE $PG_USER WITH PASSWORD '$PG_PASSWORD'; END IF; END \$\$;"

createdb -U "$(whoami)" -p $PORT "$PG_USER" || true
psql -U "$PG_USER" -p "$PORT" -d "$PG_USER" -c "CREATE EXTENSION IF NOT EXISTS pgcrypto;"

echo
echo "✅ PostgreSQL $PG_VERSION đã được cài đặt và cấu hình thành công!"
