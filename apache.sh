#!/bin/bash

# Dừng script ngay lập tức nếu có lỗi.
set -e

# --- CÁC BIẾN CẤU HÌNH ---
APACHE_VERSION="2.4.65"
APR_VERSION="1.7.6"
APR_UTIL_VERSION="1.6.3"

# Các thư viện phụ thuộc khác
PCRE2_VERSION="10.43"
ZLIB_VERSION="1.3.1"
OPENSSL_VERSION="3.3.1"

# Đường dẫn cài đặt
DEPS_PREFIX="$HOME/.local"
INSTALL_PREFIX="$HOME/.local/apache"
SOURCE_DIR="$HOME/src"

# --- HÀM HỖ TRỢ ---
download_and_extract() {
    local url=$1
    local filename=$(basename "$url")
    local dirname=${filename%.tar.gz}

    if [ ! -f "$filename" ]; then
        echo "   -> Đang tải xuống $filename..."
        wget -q --show-progress "$url"
    fi
    echo "   -> Đang giải nén $filename..."
    rm -rf "$dirname"
    tar -xzf "$filename"
}

# --- BẮT ĐẦU SCRIPT ---

echo "🚀 Bắt đầu quá trình cài đặt Apache tự động hoàn chỉnh (không cần root)."

# 1. Kiểm tra các công cụ biên dịch
if ! command -v gcc &> /dev/null || ! command -v make &> /dev/null; then
    echo "❌ Lỗi: Không tìm thấy 'gcc' hoặc 'make'. Vui lòng cài đặt các công cụ build cơ bản."
    exit 1
fi

# 2. Tạo các thư mục
echo ">> Tạo các thư mục cần thiết..."
mkdir -p "$SOURCE_DIR"
mkdir -p "$DEPS_PREFIX"
cd "$SOURCE_DIR"

# 3. KIỂM TRA VÀ CÀI ĐẶT CÁC THƯ VIỆN PHỤ THUỘC
echo ">> Kiểm tra và cài đặt các thư viện phụ thuộc..."
if ! [ -f "$DEPS_PREFIX/include/zlib.h" ]; then
    echo "   -> Cài đặt Zlib..."
    download_and_extract "https://www.zlib.net/zlib-${ZLIB_VERSION}.tar.gz"
    cd "zlib-${ZLIB_VERSION}" && ./configure --prefix="$DEPS_PREFIX" && make -j$(nproc) && make install && cd "$SOURCE_DIR"
else echo "✅ Zlib đã tồn tại. Bỏ qua."; fi
if ! [ -f "$DEPS_PREFIX/include/pcre2.h" ]; then
    echo "   -> Cài đặt PCRE2..."
    download_and_extract "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${PCRE2_VERSION}/pcre2-${PCRE2_VERSION}.tar.gz"
    cd "pcre2-${PCRE2_VERSION}" && ./configure --prefix="$DEPS_PREFIX" && make -j$(nproc) && make install && cd "$SOURCE_DIR"
else echo "✅ PCRE2 đã tồn tại. Bỏ qua."; fi
if ! [ -f "$DEPS_PREFIX/include/openssl/ssl.h" ]; then
    echo "   -> Cài đặt OpenSSL..."
    download_and_extract "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
    cd "openssl-${OPENSSL_VERSION}" && ./config --prefix="$DEPS_PREFIX" --openssldir="$DEPS_PREFIX/ssl" no-shared && make -j$(nproc) && make install_sw && cd "$SOURCE_DIR"
else echo "✅ OpenSSL đã tồn tại. Bỏ qua."; fi

# 4. CÀI ĐẶT APACHE HTTP SERVER
echo ">> Bắt đầu quá trình cài đặt Apache HTTP Server..."
download_and_extract "https://dlcdn.apache.org/httpd/httpd-${APACHE_VERSION}.tar.gz"
download_and_extract "https://dlcdn.apache.org/apr/apr-${APR_VERSION}.tar.gz"
download_and_extract "https://dlcdn.apache.org/apr/apr-util-${APR_UTIL_VERSION}.tar.gz"

echo "   -> Sắp xếp mã nguồn APR và APR-Util..."
mv "apr-${APR_VERSION}" "httpd-${APACHE_VERSION}/srclib/apr"
mv "apr-util-${APR_UTIL_VERSION}" "httpd-${APACHE_VERSION}/srclib/apr-util"

cd "httpd-${APACHE_VERSION}"
echo "   -> Cấu hình biên dịch Apache..."
CPPFLAGS="-I$DEPS_PREFIX/include" LDFLAGS="-L$DEPS_PREFIX/lib" ./configure \
    --prefix="$INSTALL_PREFIX" \
    --with-included-apr \
    --with-pcre="$DEPS_PREFIX/bin/pcre2-config" \
    --with-ssl="$DEPS_PREFIX" \
    --with-zlib="$DEPS_PREFIX"

echo "   -> Bắt đầu biên dịch và cài đặt Apache..."
make -j$(nproc)
make install
cd "$SOURCE_DIR"

# 5. TỰ ĐỘNG SỬA LỖI "bad user name daemon"
echo ">> Tự động cấu hình User và Group trong httpd.conf..."
CURRENT_USER=$(whoami)
CURRENT_GROUP=$(id -gn)
CONFIG_FILE="$INSTALL_PREFIX/conf/httpd.conf"

if [ -f "$CONFIG_FILE" ]; then
    sed -i "s/User daemon/User $CURRENT_USER/" "$CONFIG_FILE"
    sed -i "s/Group daemon/Group $CURRENT_GROUP/" "$CONFIG_FILE"
    echo "✅ Đã tự động cập nhật User thành '$CURRENT_USER' và Group thành '$CURRENT_GROUP'."
else
    echo "⚠️ Không tìm thấy tệp cấu hình tại $CONFIG_FILE. Vui lòng kiểm tra lại."
fi

# 6. CẬP NHẬT CẤU HÌNH SHELL
echo ">> Cập nhật cấu hình shell..."
CURRENT_SHELL=$(basename "$SHELL")
SHELL_CONFIG_FILE=""
case "$CURRENT_SHELL" in
    bash) SHELL_CONFIG_FILE="$HOME/.bashrc" ;;
    zsh) SHELL_CONFIG_FILE="$HOME/.zshrc" ;;
esac

APACHE_PATH_EXPORT="export PATH=\"$INSTALL_PREFIX/bin:\$PATH\""
if [ -n "$SHELL_CONFIG_FILE" ] && [ -f "$SHELL_CONFIG_FILE" ]; then
    if ! grep -qF "$APACHE_PATH_EXPORT" "$SHELL_CONFIG_FILE"; then
        echo "   -> Thêm đường dẫn Apache vào $SHELL_CONFIG_FILE..."
        echo -e "\n# Add Apache to PATH" >> "$SHELL_CONFIG_FILE"
        echo "$APACHE_PATH_EXPORT" >> "$SHELL_CONFIG_FILE"
        echo "✅ Cập nhật $SHELL_CONFIG_FILE thành công."
    else
        echo "✅ Đường dẫn Apache đã tồn tại trong $SHELL_CONFIG_FILE. Bỏ qua."
    fi
else
    echo "⚠️ Không tìm thấy tệp cấu hình cho shell '$CURRENT_SHELL'. Vui lòng thêm thủ công:"
    echo "   $APACHE_PATH_EXPORT"
fi


# --- HOÀN TẤT ---
echo -e "\n🎉 Cài đặt Apache hoàn tất!"
echo "Thư mục cài đặt: $INSTALL_PREFIX"
echo ""
echo "VUI LÒNG CHẠY LỆNH SAU ĐỂ CẬP NHẬT MÔI TRƯỜNG:"
echo "   source ${SHELL_CONFIG_FILE:-your-shell-config-file}"
echo "Hoặc mở một cửa sổ terminal mới."
echo ""
echo "Sau đó, bạn có thể quản lý server bằng các lệnh:"
echo "   - Bắt đầu:      apachectl start"
echo "   - Dừng lại:      apachectl stop"
echo "   - Khởi động lại: apachectl restart"
