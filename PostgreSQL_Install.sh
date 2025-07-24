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

# === Tùy chỉnh user và password ===
PG_USER="yuu"              # 👤 Username muốn tạo
PG_PASSWORD="oniichan123"  # 🔐 Password cho user đó

# === Ensure directories ===
mkdir -p "$PG_DIR" "$NSS_DIR"
cd "$PG_DIR"

# === Download and extract PostgreSQL ===
curl -LO "https://ftp.postgresql.org/pub/source/v$PG_VERSION/$PG_SRC.tar.gz"
tar -xzf "$PG_SRC.tar.gz"
cd "$PG_SRC"
./configure --prefix="$PG_PREFIX" --without-icu
make -j$(nproc)
make install

# === Download and build nss_wrapper ===
cd "$NSS_DIR"
curl -LO "https://ftp.samba.org/pub/cwrap/${NSS_SRC}.tar.gz"
tar -xzf "${NSS_SRC}.tar.gz"
cd "$NSS_SRC"
mkdir build && cd build
cmake ..
make -j$(nproc)

# === Create fake passwd and group files ===
cd "$PG_DIR"
uid=$(id -u)
gid=$(id -g)
echo "postgres:x:$uid:$gid:PostgreSQL User:/home/container:/bin/bash" > "$PG_DIR/passwd.fake"
echo "postgres:x:$gid:" > "$PG_DIR/group.fake"

# === Export fake user environment ===
export LD_PRELOAD="$NSS_DIR/$NSS_SRC/build/src/libnss_wrapper.so"
export NSS_WRAPPER_PASSWD="$PG_DIR/passwd.fake"
export NSS_WRAPPER_GROUP="$PG_DIR/group.fake"
export PATH="$PG_PREFIX/bin:$PATH"

# === Detect shell config file ===
SHELL_NAME=$(basename "$SHELL")
if [ "$SHELL_NAME" = "bash" ]; then
    PROFILE_FILE="$HOME/.bashrc"
elif [ "$SHELL_NAME" = "zsh" ]; then
    PROFILE_FILE="$HOME/.zshrc"
else
    PROFILE_FILE="$HOME/.profile"
fi

# === Add exports to shell config file if not already added ===
EXPORTS=$(cat <<EOF

# PostgreSQL local setup
export LD_PRELOAD="$LD_PRELOAD"
export NSS_WRAPPER_PASSWD="$NSS_WRAPPER_PASSWD"
export NSS_WRAPPER_GROUP="$NSS_WRAPPER_GROUP"
export PATH="$PG_PREFIX/bin:\$PATH"
EOF
)

if ! grep -q "NSS_WRAPPER_PASSWD" "$PROFILE_FILE"; then
    echo "$EXPORTS" >> "$PROFILE_FILE"
    echo "📝 Đã thêm cấu hình vào $PROFILE_FILE"
fi

# === Initialize PostgreSQL ===
"$PG_PREFIX/bin/initdb" -D "$PG_DATA"

# === Configure PostgreSQL ===
sed -i "s/^#\?port = .*/port = $PORT/" "$PG_DATA/postgresql.conf"
sed -i "s/^#\?listen_addresses = .*/listen_addresses = '*'/" "$PG_DATA/postgresql.conf"

# === Start PostgreSQL ===
"$PG_PREFIX/bin/pg_ctl" -D "$PG_DATA" -l "$PG_DIR/logfile" start

# === Tạo user và đặt mật khẩu ===
echo "CREATE USER $PG_USER WITH SUPERUSER PASSWORD '$PG_PASSWORD';" | "$PG_PREFIX/bin/psql" -U postgres -p $PORT || \
echo "ALTER USER $PG_USER WITH PASSWORD '$PG_PASSWORD';" | "$PG_PREFIX/bin/psql" -U postgres -p $PORT

# === Done ===
echo
echo "✅ PostgreSQL $PG_VERSION đã được cài và chạy ở port $PORT"
echo "👤 User: $PG_USER"
echo "🔐 Pass: $PG_PASSWORD"
echo "🧠 Các biến môi trường đã thêm vào $PROFILE_FILE (dùng 'source $PROFILE_FILE' để áp dụng)"
