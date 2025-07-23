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

# === Initialize PostgreSQL ===
"$PG_PREFIX/bin/initdb" -D "$PG_DATA"

# === Configure port and listen_addresses ===
sed -i "s/^#\?port = .*/port = $PORT/" "$PG_DATA/postgresql.conf"
sed -i "s/^#\?listen_addresses = .*/listen_addresses = '*'/" "$PG_DATA/postgresql.conf"

# === Start PostgreSQL ===
"$PG_PREFIX/bin/pg_ctl" -D "$PG_DATA" -l "$PG_DIR/logfile" start

# === Done ===
echo
echo "✅ PostgreSQL $PG_VERSION installed and running on port $PORT"
echo "➤ To use psql, createuser, etc., export these:"
echo "export LD_PRELOAD=$LD_PRELOAD"
echo "export NSS_WRAPPER_PASSWD=$NSS_WRAPPER_PASSWD"
echo "export NSS_WRAPPER_GROUP=$NSS_WRAPPER_GROUP"
