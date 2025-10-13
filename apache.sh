#!/bin/bash

# Dừng script ngay lập tức nếu có lỗi.
set -e

# --- CÁC BIẾN CẤU HÌNH (ĐÃ CẬP NHẬT THEO YÊU CẦU) ---
APACHE_VERSION="2.4.65"
APR_VERSION="1.7.6"
APR_UTIL_VERSION="1.6.3" # Giữ nguyên

# Các thư viện phụ thuộc khác
PCRE2_VERSION="10.43"
ZLIB_VERSION="1.3.1"
OPENSSL_VERSION="3.3.1"

# Đường dẫn cài đặt
DEPS_PREFIX="$HOME/.local"
INSTALL_PREFIX="$HOME/.local/apache"
SOURCE_DIR="$HOME/src"

# --- HÀM HỖ TRỢ ---

# Hàm để tải và giải nén một tệp
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

echo "🚀 Bắt đầu quá trình cài đặt Apache phiên bản tùy chỉnh (không cần root)."
echo "   - httpd: ${APACHE_VERSION}"
echo "   - apr: ${APR_VERSION}"
echo "   - apr-util: ${APR_UTIL_VERSION}"


# 1. Kiểm tra các công cụ biên dịch cơ bản
if ! command -v gcc &> /dev/null || ! command -v make &> /dev/null; then
    echo "❌ Lỗi: Không tìm thấy 'gcc' hoặc 'make'."
    echo "Vui lòng cài đặt các công cụ build cơ bản (build-essential, base-devel) trước."
    exit 1
fi

# 2. Tạo các thư mục cần thiết
echo ">> Tạo các thư mục tại $SOURCE_DIR và $DEPS_PREFIX..."
mkdir -p "$SOURCE_DIR"
mkdir -p "$DEPS_PREFIX"
cd "$SOURCE_DIR"

# 3. KIỂM TRA VÀ CÀI ĐẶT CÁC THƯ VIỆN PHỤ THUỘC
echo ">> Bắt đầu kiểm tra và cài đặt các thư viện phụ thuộc..."

# --- ZLIB ---
if [ -f "$DEPS_PREFIX/include/zlib.h" ] && [ -f "$DEPS_PREFIX/lib/libz.a" ]; then
    echo "✅ Zlib đã được cài đặt. Bỏ qua."
else
    echo "⚠️ Zlib chưa được cài đặt. Bắt đầu cài đặt..."
    download_and_extract "https://www.zlib.net/zlib-${ZLIB_VERSION}.tar.gz"
    cd "zlib-${ZLIB_VERSION}" && ./configure --prefix="$DEPS_PREFIX" && make -j$(nproc) && make install && cd "$SOURCE_DIR"
fi

# --- PCRE2 ---
if [ -f "$DEPS_PREFIX/include/pcre2.h" ] && [ -f "$DEPS_PREFIX/lib/libpcre2-8.a" ]; then
    echo "✅ PCRE2 đã được cài đặt. Bỏ qua."
else
    echo "⚠️ PCRE2 chưa được cài đặt. Bắt đầu cài đặt..."
    download_and_extract "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${PCRE2_VERSION}/pcre2-${PCRE2_VERSION}.tar.gz"
    cd "pcre2-${PCRE2_VERSION}" && ./configure --prefix="$DEPS_PREFIX" && make -j$(nproc) && make install && cd "$SOURCE_DIR"
fi

# --- OPENSSL ---
if [ -f "$DEPS_PREFIX/include/openssl/ssl.h" ] && [ -f "$DEPS_PREFIX/lib/libssl.a" ]; then
    echo "✅ OpenSSL đã được cài đặt. Bỏ qua."
else
    echo "⚠️ OpenSSL chưa được cài đặt. Bắt đầu cài đặt..."
    download_and_extract "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
    cd "openssl-${OPENSSL_VERSION}" && ./config --prefix="$DEPS_PREFIX" --openssldir="$DEPS_PREFIX/ssl" no-shared && make -j$(nproc) && make install_sw && cd "$SOURCE_DIR"
fi


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

echo "   -> Bắt đầu biên dịch và cài đặt Apache (có thể mất vài phút)..."
make -j$(nproc)
make install
cd "$SOURCE_DIR"

# 5. CẬP NHẬT CẤU HÌNH SHELL
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
