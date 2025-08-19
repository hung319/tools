#!/bin/bash
set -e

# === CONFIG ===
PG_VERSION="16.3"
PG_SRC="postgresql-$PG_VERSION"
PG_DIR="$HOME/pgsql"
PG_PREFIX="$PG_DIR/pg16local"
PG_DATA="$PG_DIR/data"
NSS_DIR="$PG_DIR/fakeuser"
NSS_SRC="nss_wrapper-1.1.15"
PORT=5432
TMPDIR="${TMPDIR:-$HOME/.local/tmp}"

PG_USER="hung319"
PG_PASSWORD="11042006"

mkdir -p "$PG_DIR" "$NSS_DIR" "$TMPDIR" "$PG_PREFIX"

# === Build OpenSSL ===
OPENSSL_VERSION="1.1.1u"
cd "$TMPDIR"
curl -LO "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz"
tar -xzf "openssl-$OPENSSL_VERSION.tar.gz"
cd "openssl-$OPENSSL_VERSION"
./config --prefix="$PG_PREFIX/openssl" --openssldir="$PG_PREFIX/openssl"
make -j$(nproc)
make install

# === Build libxml2 (2.14.5) ===
LIBXML2_VERSION="2.14.5"
cd "$TMPDIR"
curl -LO "https://download.gnome.org/sources/libxml2/2.14/libxml2-$LIBXML2_VERSION.tar.xz"
tar -xf "libxml2-$LIBXML2_VERSION.tar.xz"
cd "libxml2-$LIBXML2_VERSION"
./configure --prefix="$PG_PREFIX/libxml2" --without-python
make -j$(nproc)
make install

# === Download và build PostgreSQL ===
cd "$PG_DIR"
curl -LO "https://ftp.postgresql.org/pub/source/v$PG_VERSION/$PG_SRC.tar.gz"
tar -xzf "$PG_SRC.tar.gz"
cd "$PG_SRC"

./configure --prefix="$PG_PREFIX" \
  --with-openssl \
  --with-libxml \
  --with-includes="$PG_PREFIX/openssl/include:$PG_PREFIX/libxml2/include/libxml2" \
  --with-libraries="$PG_PREFIX/openssl/lib:$PG_PREFIX/libxml2/lib" \
  --without-icu

make -j$(nproc)
make install

# === Build toàn bộ extension trong contrib ===
cd contrib
for d in */; do
    cd "$d"
    make -j$(nproc) || true
    make install || true
    cd ..
done

# === Build nss_wrapper ===
cd "$NSS_DIR"
curl -LO "https://ftp.samba.org/pub/cwrap/${NSS_SRC}.tar.gz"
tar -xzf "${NSS_SRC}.tar.gz"
cd "$NSS_SRC"
mkdir -p build && cd build
cmake ..
make -j$(nproc)

# === Fake passwd & group dựa trên PG_USER ===
cd "$PG_DIR"
uid=$(id -u)
gid=$(id -g)
echo "$PG_USER:x:$uid:$gid:PostgreSQL User:$HOME:/bin/bash" > "$PG_DIR/passwd.fake"
echo "$PG_USER:x:$gid:" > "$PG_DIR/group.fake"

# === Export env (runtime) ===
export LD_PRELOAD="$NSS_DIR/$NSS_SRC/build/src/libnss_wrapper.so"
export NSS_WRAPPER_PASSWD="$PG_DIR/passwd.fake"
export NSS_WRAPPER_GROUP="$PG_DIR/group.fake"
export PATH="$PG_PREFIX/bin:$PATH"
export LD_LIBRARY_PATH="$PG_PREFIX/openssl/lib:$PG_PREFIX/libxml2/lib:$LD_LIBRARY_PATH"
export PGUSER="$PG_USER"
export PGPASSWORD="$PG_PASSWORD"
export PGDATABASE="$PG_USER"
export PGHOST="0.0.0.0"

# === Add vào shell config nếu chưa có ===
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
export LD_PRELOAD="\$HOME/pgsql/fakeuser/nss_wrapper-1.1.15/build/src/libnss_wrapper.so"
export NSS_WRAPPER_PASSWD="\$HOME/pgsql/passwd.fake"
export NSS_WRAPPER_GROUP="\$HOME/pgsql/group.fake"
export PATH="\$HOME/pgsql/pg16local/bin:\$PATH"
export LD_LIBRARY_PATH="\$HOME/pgsql/pg16local/openssl/lib:\$HOME/pgsql/pg16local/libxml2/lib:\$LD_LIBRARY_PATH"
export PGUSER="$PG_USER"
export PGPASSWORD="$PG_PASSWORD"
export PGDATABASE="$PG_USER"
export PGHOST="0.0.0.0"
EOF
)

if ! grep -q "NSS_WRAPPER_PASSWD" "$PROFILE_FILE"; then
    echo "$EXPORTS" >> "$PROFILE_FILE"
    echo "📝 Đã thêm cấu hình vào $PROFILE_FILE"
fi

# === Init database cluster ===
"$PG_PREFIX/bin/initdb" -D "$PG_DATA"

# === Cấu hình postgresql.conf ===
sed -i "s/^#\?port = .*/port = $PORT/" "$PG_DATA/postgresql.conf"
sed -i "s/^#\?listen_addresses = .*/listen_addresses = '*'/" "$PG_DATA/postgresql.conf"

# === Cho phép remote access ===
cat <<EOF >> "$PG_DATA/pg_hba.conf"

# Cho phép remote access
host    all             all             0.0.0.0/0               scram-sha-256
EOF

# === Start PostgreSQL (wait) ===
"$PG_PREFIX/bin/pg_ctl" -D "$PG_DATA" -l "$PG_DIR/logfile" -w start

# === Tạo user PostgreSQL và DB ===
echo "DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$PG_USER') THEN
      CREATE ROLE $PG_USER WITH LOGIN SUPERUSER PASSWORD '$PG_PASSWORD';
   ELSE
      ALTER ROLE $PG_USER WITH PASSWORD '$PG_PASSWORD';
   END IF;
END
\$\$;" | "$PG_PREFIX/bin/psql" -U "$PG_USER" -p $PORT postgres

"$PG_PREFIX/bin/createdb" -U "$PG_USER" -p $PORT "$PG_USER" || true

"$PG_PREFIX/bin/psql" -U "$PG_USER" -p "$PORT" -d "$PG_USER" -c "CREATE EXTENSION IF NOT EXISTS pgcrypto;"

echo
echo "✅ PostgreSQL $PG_VERSION đã được cài thành công non-root!"
echo "🔐 User: $PG_USER | Password: $PG_PASSWORD"
echo "📦 Extension: pgcrypto đã được bật"
echo "🌐 PGHOST mặc định: 0.0.0.0"
echo "🧠 source $PROFILE_FILE để dùng ngay"
