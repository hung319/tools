#!/bin/bash
set -e

# === CONFIG ===
PG_VERSION="16.3"
PG_SRC="postgresql-$PG_VERSION"
PG_DIR="$HOME/pgsql"
PG_PREFIX="$PG_DIR/pg16local"
PG_DATA="$PG_DIR/data"
NSS_DIR="$HOME/fakeuser"
NSS_SRC="nss_wrapper-1.1.15"
PORT=5432
TMPDIR="${TMPDIR:-$HOME/.tmp}"

# === Tùy chỉnh user và password ===
PG_USER="yuu"
PG_PASSWORD="oniichan123"

# === Tạo thư mục cần thiết ===
mkdir -p "$PG_DIR" "$NSS_DIR" "$TMPDIR" "$PG_PREFIX"

# === Tải và cài OpenSSL (non-root) ===
cd "$TMPDIR"
OPENSSL_VERSION="1.1.1u"
curl -LO "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz"
tar -xzf "openssl-$OPENSSL_VERSION.tar.gz"
cd "openssl-$OPENSSL_VERSION"
./config --prefix="$PG_PREFIX/openssl" --openssldir="$PG_PREFIX/openssl"
make -j$(nproc)
make install

# === Tải và cài PostgreSQL ===
cd "$PG_DIR"
curl -LO "https://ftp.postgresql.org/pub/source/v$PG_VERSION/$PG_SRC.tar.gz"
tar -xzf "$PG_SRC.tar.gz"
cd "$PG_SRC"

./configure --prefix="$PG_PREFIX" \
  --with-openssl \
  --with-includes="$PG_PREFIX/openssl/include" \
  --with-libraries="$PG_PREFIX/openssl/lib" \
  --without-icu

make -j$(nproc)
make install

# === Build tất cả extension trong contrib/ ===
cd contrib
for d in */; do
    cd "$d"
    make -j$(nproc) || true
    make install || true
    cd ..
done

# === Cài nss_wrapper ===
cd "$NSS_DIR"
curl -LO "https://ftp.samba.org/pub/cwrap/${NSS_SRC}.tar.gz"
tar -xzf "${NSS_SRC}.tar.gz"
cd "$NSS_SRC"
mkdir build && cd build
cmake ..
make -j$(nproc)

# === Tạo user giả mạo ===
cd "$PG_DIR"
uid=$(id -u)
gid=$(id -g)
echo "postgres:x:$uid:$gid:PostgreSQL User:/home/container:/bin/bash" > "$PG_DIR/passwd.fake"
echo "postgres:x:$gid:" > "$PG_DIR/group.fake"

# === Export biến môi trường ===
export LD_PRELOAD="$NSS_DIR/$NSS_SRC/build/src/libnss_wrapper.so"
export NSS_WRAPPER_PASSWD="$PG_DIR/passwd.fake"
export NSS_WRAPPER_GROUP="$PG_DIR/group.fake"
export PATH="$PG_PREFIX/bin:$PATH"
export LD_LIBRARY_PATH="$PG_PREFIX/openssl/lib:$LD_LIBRARY_PATH"

# === Ghi lại vào profile nếu chưa có ===
SHELL_NAME=$(basename "$SHELL")
if [ "$SHELL_NAME" = "bash" ]; then
    PROFILE_FILE="$HOME/.bashrc"
elif [ "$SHELL_NAME" = "zsh" ]; then
    PROFILE_FILE="$HOME/.zshrc"
else
    PROFILE_FILE="$HOME/.profile"
fi

EXPORTS=$(cat <<EOF

# PostgreSQL local setup
export LD_PRELOAD="$LD_PRELOAD"
export NSS_WRAPPER_PASSWD="$NSS_WRAPPER_PASSWD"
export NSS_WRAPPER_GROUP="$NSS_WRAPPER_GROUP"
export PATH="$PG_PREFIX/bin:\$PATH"
export LD_LIBRARY_PATH="$PG_PREFIX/openssl/lib:\$LD_LIBRARY_PATH"
EOF
)

if ! grep -q "NSS_WRAPPER_PASSWD" "$PROFILE_FILE"; then
    echo "$EXPORTS" >> "$PROFILE_FILE"
    echo "📝 Đã thêm cấu hình vào $PROFILE_FILE"
fi

# === Khởi tạo database ===
"$PG_PREFIX/bin/initdb" -D "$PG_DATA"

# === Cấu hình postgresql.conf ===
sed -i "s/^#\?port = .*/port = $PORT/" "$PG_DATA/postgresql.conf"
sed -i "s/^#\?listen_addresses = .*/listen_addresses = '*'/" "$PG_DATA/postgresql.conf"

# === Thêm quyền vào pg_hba.conf ===
cat <<EOF >> "$PG_DATA/pg_hba.conf"

# Cho phép remote access
host    all             all             0.0.0.0/0               scram-sha-256
EOF

# === Khởi động PostgreSQL ===
"$PG_PREFIX/bin/pg_ctl" -D "$PG_DATA" -l "$PG_DIR/logfile" start

# === Tạo user PostgreSQL và enable pgcrypto ===
echo "CREATE USER $PG_USER WITH SUPERUSER PASSWORD '$PG_PASSWORD';" | "$PG_PREFIX/bin/psql" -U postgres -p $PORT || \
echo "ALTER USER $PG_USER WITH PASSWORD '$PG_PASSWORD';" | "$PG_PREFIX/bin/psql" -U postgres -p $PORT

# === Enable pgcrypto ===
"$PG_PREFIX/bin/psql" -U "$PG_USER" -p "$PORT" -c "CREATE EXTENSION IF NOT EXISTS pgcrypto;"

# === Xong rồi đó Yuu Onii-chan 💖 ===
echo
echo "✅ PostgreSQL $PG_VERSION đã cài thành công non-root!"
echo "📦 Extensions đã được build"
echo "🔐 User: $PG_USER | Password: $PG_PASSWORD"
echo "🧠 Biến môi trường đã thêm vào $PROFILE_FILE (nhớ source nhé!)"
