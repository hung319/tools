#!/bin/bash

# ==============================================================================
# Script cài đặt MariaDB không cần quyền root (Phiên bản 10 - Tối ưu tốc độ)
#
# Các tính năng:
# - Sử dụng toàn bộ lõi CPU để biên dịch nhanh hơn.
# - Sửa lỗi "Access denied for user 'root'@'localhost'" sau khi cài đặt.
# - Vô hiệu hóa CONNECT engine để tránh lỗi biên dịch.
# - Dùng pkg-config để kiểm tra và tự cài đặt thư viện phụ thuộc.
# ==============================================================================

# --- Phần 1: Thiết lập biến và đường dẫn ---
set -e # Thoát ngay khi có lỗi
set -o pipefail # Bắt lỗi trong các pipe

# Phiên bản MariaDB và các thư viện phụ thuộc
MARIADB_VERSION="10.6.12"
ZLIB_VERSION="1.2.13"
NCURSES_VERSION="6.4"
LIBAIO_VERSION="0.3.113"

# Các thư mục chính
INSTALL_DIR="${HOME}/mariadb"
SOURCE_DIR="${HOME}/src"
DEPS_DIR="${HOME}/.local"
DATA_DIR="${INSTALL_DIR}/data"

# Thông tin kết nối cơ sở dữ liệu (có thể tùy chỉnh)
export MARIADB_USER="myuser"
export MARIADB_PASSWORD="mypassword"
export MARIADB_PORT="3307"

# Tạo các thư mục cần thiết
mkdir -p "${SOURCE_DIR}" "${INSTALL_DIR}" "${DEPS_DIR}" "${DATA_DIR}"
echo "✅ Các thư mục đã được chuẩn bị."

# --- Phần 2: Kiểm tra và cài đặt thư viện phụ thuộc ---

# Thiết lập môi trường để ưu tiên các thư viện cục bộ
export PKG_CONFIG_PATH="${DEPS_DIR}/lib/pkgconfig:${PKG_CONFIG_PATH}"
export CPPFLAGS="-I${DEPS_DIR}/include"
export LDFLAGS="-L${DEPS_DIR}/lib"

# Dùng pkg-config để kiểm tra thư viện
check_lib() {
    local lib_name=$1
    if pkg-config --exists "${lib_name}"; then
        return 0
    else
        return 1
    fi
}

# --- Cài đặt zlib ---
install_zlib() {
    echo "🛠️ Đang biên dịch và cài đặt zlib..."
    cd "${SOURCE_DIR}"
    wget -c "https://www.zlib.net/zlib-${ZLIB_VERSION}.tar.gz"
    tar -xzf "zlib-${ZLIB_VERSION}.tar.gz"
    cd "zlib-${ZLIB_VERSION}"
    ./configure --prefix="${DEPS_DIR}"
    make -j$(nproc)
    make install
    echo "✅ zlib đã được cài đặt vào ${DEPS_DIR}"
}

# --- Cài đặt ncurses ---
install_ncurses() {
    echo "🛠️ Đang biên dịch và cài đặt ncurses..."
    cd "${SOURCE_DIR}"
    wget -c "https://ftp.gnu.org/pub/gnu/ncurses/ncurses-${NCURSES_VERSION}.tar.gz"
    tar -xzf "ncurses-${NCURSES_VERSION}.tar.gz"
    cd "ncurses-${NCURSES_VERSION}"
    ./configure --prefix="${DEPS_DIR}" \
                --with-shared \
                --without-debug \
                --without-ada \
                --enable-widec \
                --with-pkg-config-libdir="${DEPS_DIR}/lib/pkgconfig"
    make -j$(nproc)
    make install
    echo "✅ ncurses đã được cài đặt vào ${DEPS_DIR}"
}

# --- Cài đặt libaio ---
install_libaio() {
    echo "🛠️ Đang biên dịch và cài đặt libaio..."
    cd "${SOURCE_DIR}"
    rm -rf "libaio-${LIBAIO_VERSION}"
    wget -c "https://ftp.debian.org/debian/pool/main/liba/libaio/libaio_${LIBAIO_VERSION}.orig.tar.gz"
    tar -xzf "libaio_${LIBAIO_VERSION}.orig.tar.gz"
    cd "libaio-${LIBAIO_VERSION}"
    make -j$(nproc)
    make prefix="${DEPS_DIR}" install
    mkdir -p "${DEPS_DIR}/lib/pkgconfig"
    cat > "${DEPS_DIR}/lib/pkgconfig/libaio.pc" <<EOL
prefix=${DEPS_DIR}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: libaio
Description: Asynchronous I/O library
Version: ${LIBAIO_VERSION}
Libs: -L\${libdir} -laio
Cflags: -I\${includedir}
EOL
    echo "✅ libaio đã được cài đặt vào ${DEPS_DIR}"
}

echo "🔄 Đang kiểm tra các thư viện phụ thuộc bằng pkg-config..."
if ! check_lib "zlib"; then echo "🔎 Không tìm thấy zlib. Bắt đầu cài đặt."; install_zlib; fi
if ! check_lib "ncursesw"; then echo "🔎 Không tìm thấy ncursesw. Bắt đầu cài đặt."; install_ncurses; fi
if ! check_lib "libaio"; then echo "🔎 Không tìm thấy libaio. Bắt đầu cài đặt."; install_libaio; fi
echo "✅ Tất cả các thư viện phụ thuộc đã sẵn sàng."

# --- Phần 3: Tải và giải nén MariaDB ---
cd "${SOURCE_DIR}"
MARIADB_TARBALL="mariadb-${MARIADB_VERSION}.tar.gz"
MARIADB_URL="https://archive.mariadb.org/mariadb-${MARIADB_VERSION}/source/${MARIADB_TARBALL}"

if [ ! -f "${MARIADB_TARBALL}" ]; then
    echo "📥 Đang tải MariaDB ${MARIADB_VERSION}..."
    wget "${MARIADB_URL}"
else
    echo "📁 Đã tìm thấy file tải về của MariaDB."
fi

echo "📦 Đang giải nén..."
rm -rf "mariadb-${MARIADB_VERSION}"
tar -xzf "${MARIADB_TARBALL}"

# --- Phần 4: Biên dịch và Cài đặt MariaDB ---
cd "mariadb-${MARIADB_VERSION}"
rm -rf build
mkdir -p build && cd build

echo "⚙️ Đang cấu hình quá trình biên dịch MariaDB..."
cmake .. \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
    -DMYSQL_DATADIR="${DATA_DIR}" \
    -DCMAKE_PREFIX_PATH="${DEPS_DIR}" \
    -DCMAKE_INSTALL_RPATH="${DEPS_DIR}/lib" \
    -DWITH_SSL=system \
    -DWITHOUT_TOKUDB=1 \
    -DWITHOUT_CONNECT_STORAGE_ENGINE=1

echo "🛠️ Đang biên dịch MariaDB với toàn bộ CPU..."
# TĂNG TỐC: Sử dụng toàn bộ lõi CPU
make -j$(nproc)

echo "⏳ Đang cài đặt MariaDB..."
make install

# --- Phần 5: Khởi tạo Cơ sở dữ liệu ---
cd "${INSTALL_DIR}"

echo "🚀 Đang khởi tạo cơ sở dữ liệu ban đầu..."
./scripts/mysql_install_db --user=$(whoami) --datadir="${DATA_DIR}" --basedir="${INSTALL_DIR}"

# Tạo file cấu hình my.cnf
cat > "${INSTALL_DIR}/my.cnf" <<EOL
[mysqld]
basedir=${INSTALL_DIR}
datadir=${DATA_DIR}
socket=${INSTALL_DIR}/mysql.sock
port=${MARIADB_PORT}
user=$(whoami)

[client]
socket=${INSTALL_DIR}/mysql.sock
port=${MARIADB_PORT}
EOL

echo "🔑 Đang thiết lập người dùng và mật khẩu..."
./bin/mysqld_safe --defaults-file="${INSTALL_DIR}/my.cnf" --skip-grant-tables --skip-networking --nowatch &
MARIADB_PID=$!

echo "⏳ Chờ server khởi động để thiết lập bảo mật..."
for i in {30..0}; do
    if ./bin/mysqladmin ping --socket="${INSTALL_DIR}/mysql.sock" &>/dev/null; then
        break
    fi
    echo -n "."
    sleep 1
done
if [ "$i" = 0 ]; then
    echo "❌ Không thể khởi động MariaDB."
    exit 1
fi
echo ""

./bin/mysql --socket="${INSTALL_DIR}/mysql.sock" -u root <<-EOSQL
    FLUSH PRIVILEGES;
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_PASSWORD}';
    CREATE USER '${MARIADB_USER}'@'localhost' IDENTIFIED BY '${MARIADB_PASSWORD}';
    GRANT ALL PRIVILEGES ON *.* TO '${MARIADB_USER}'@'localhost' WITH GRANT OPTION;
    FLUSH PRIVILEGES;
EOSQL

kill "${MARIADB_PID}"
wait "${MARIADB_PID}" 2>/dev/null

# --- Phần 6: Cấu hình biến môi trường cho Shell ---
SHELL_CONFIG_FILE=""
CURRENT_SHELL=$(basename "$SHELL")

if [ "$CURRENT_SHELL" = "bash" ]; then
    SHELL_CONFIG_FILE="${HOME}/.bashrc"
elif [ "$CURRENT_SHELL" = "zsh" ]; then
    SHELL_CONFIG_FILE="${HOME}/.zshrc"
fi

if [ -n "$SHELL_CONFIG_FILE" ]; then
    echo "🖋️ Đang thêm biến môi trường vào ${SHELL_CONFIG_FILE}..."
    if ! grep -q "# MariaDB Custom Install" "${SHELL_CONFIG_FILE}"; then
        cat >> "${SHELL_CONFIG_FILE}" <<-EOL

# MariaDB Custom Install
export MARIADB_HOME="${INSTALL_DIR}"
export PATH="\$MARIADB_HOME/bin:\$PATH"
export MARIADB_USER="${MARIADB_USER}"
export MARIADB_PASSWORD="${MARIADB_PASSWORD}"
export MARIADB_PORT="${MARIADB_PORT}"
EOL
        echo "✅ Đã thêm biến môi trường. Vui lòng chạy 'source ${SHELL_CONFIG_FILE}' hoặc mở lại terminal."
    else
        echo "✔️ Các biến môi trường của MariaDB đã tồn tại trong ${SHELL_CONFIG_FILE}."
    fi
else
    echo "⚠️ Không thể tự động phát hiện file cấu hình cho shell '${CURRENT_SHELL}'."
fi

# --- Phần 7: Hoàn tất và Hướng dẫn ---
echo ""
echo "🎉 Cài đặt MariaDB hoàn tất! 🎉"
echo "======================================================"
echo "  Thư mục cài đặt: ${INSTALL_DIR}"
echo "  Thư mục dữ liệu: ${DATA_DIR}"
echo "  Thư mục libs:    ${DEPS_DIR} (dùng chung)"
echo "  Người dùng:      ${MARIADB_USER}"
echo "  Mật khẩu:        ${MARIADB_PASSWORD}"
echo "  Cổng:            ${MARIADB_PORT}"
echo "======================================================"
echo ""
echo "Để bắt đầu, hãy làm theo các bước sau:"
echo "1. Mở một terminal mới hoặc chạy lệnh: source ${SHELL_CONFIG_FILE}"
echo "2. Khởi động server MariaDB:"
echo "   mysqld_safe --defaults-file=\${MARIADB_HOME}/my.cnf &"
echo "3. Kết nối tới server:"
echo "   mysql -u \${MARIADB_USER} -p"
echo "   (Nhập mật khẩu: ${MARIADB_PASSWORD})"
echo "4. Để dừng server:"
echo "   mysqladmin -u \${MARIADB_USER} -p shutdown"
echo ""
