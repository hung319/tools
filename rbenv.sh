#!/usr/bin/env bash
#
# Script cài đặt rbenv VÀ tự động build dependencies (openssl, readline, zlib, libyaml)
# vào $HOME/.local mà không cần quyền root.
#

# Dừng script ngay lập tức nếu có lỗi
set -euo pipefail

## --- Định nghĩa Biến và Đường dẫn (Yêu cầu 1) ---

# Đặt thư mục cài đặt chính là $HOME/.local
export INSTALL_PREFIX="$HOME/.local"
export LOCAL_DIR="$INSTALL_PREFIX" # Tương thích với script gốc

# Thư mục chứa mã nguồn tải về
export SRC_DIR="$HOME/src"

# rbenv sẽ được cài vào $HOME/.local/rbenv
export RBENV_DIR="$INSTALL_PREFIX/rbenv"

# Số CPU để build
export CPU_COUNT
CPU_COUNT=$(nproc 2>/dev/null || echo 1) # Mặc định là 1 nếu nproc lỗi

# Tạo các thư mục cần thiết
mkdir -p "$INSTALL_PREFIX/bin"
mkdir -p "$INSTALL_PREFIX/lib/pkgconfig"
mkdir -p "$INSTALL_PREFIX/lib64/pkgconfig" # Cho các hệ thống 64-bit
mkdir -p "$INSTALL_PREFIX/include"
mkdir -p "$SRC_DIR"

## --- Thiết lập Môi trường Build Ngay Lập Tức ---
# Rất quan trọng: Đảm bảo các thư viện "thấy" nhau khi build
export PKG_CONFIG_PATH="$INSTALL_PREFIX/lib/pkgconfig:$INSTALL_PREFIX/lib64/pkgconfig:${PKG_CONFIG_PATH:-}"
export CPPFLAGS="-I$INSTALL_PREFIX/include"
export LDFLAGS="-L$INSTALL_PREFIX/lib -L$INSTALL_PREFIX/lib64"
export PATH="$INSTALL_PREFIX/bin:$PATH"

## --- Hàm Hỗ trợ ---
info() {
  echo "INFO: $1"
}
warn() {
  echo "WARN: $1" >&2
}
error() {
  echo "ERROR: $1" >&2
  exit 1
}

## --- Các hàm Build Dependencies (Yêu cầu 3) ---

# Phiên bản (LTS hoặc ổn định)
ZLIB_VERSION="1.3.1"
LIBYAML_VERSION="0.2.5"
READLINE_VERSION="8.2"
OPENSSL_VERSION="3.0.14" # Sử dụng 3.0.14 (LTS) ổn định

build_zlib() {
    info "--- 🚀 Bắt đầu build Zlib $ZLIB_VERSION ---"
    cd "$SRC_DIR"
    if [ ! -f "zlib-$ZLIB_VERSION.tar.gz" ]; then
        wget "https://www.zlib.net/zlib-$ZLIB_VERSION.tar.gz"
    fi
    rm -rf "zlib-$ZLIB_VERSION"
    tar -xf "zlib-$ZLIB_VERSION.tar.gz"
    (
        cd "zlib-$ZLIB_VERSION"
        ./configure --prefix="$INSTALL_PREFIX"
        make -j"$CPU_COUNT"
        make install
    )
    info "✅ Build Zlib hoàn tất."
}

build_libyaml() {
    info "--- 🚀 Bắt đầu build LibYAML $LIBYAML_VERSION ---"
    cd "$SRC_DIR"
    if [ ! -f "yaml-$LIBYAML_VERSION.tar.gz" ]; then
        wget "https://github.com/yaml/libyaml/releases/download/$LIBYAML_VERSION/yaml-$LIBYAML_VERSION.tar.gz"
    fi
    rm -rf "yaml-$LIBYAML_VERSION"
    tar -xf "yaml-$LIBYAML_VERSION.tar.gz"
    (
        cd "yaml-$LIBYAML_VERSION"
        ./configure --prefix="$INSTALL_PREFIX"
        make -j"$CPU_COUNT"
        make install
    )
    info "✅ Build LibYAML hoàn tất."
}

build_readline() {
    info "--- 🚀 Bắt đầu build Readline $READLINE_VERSION ---"
    cd "$SRC_DIR"
    if [ ! -f "readline-$READLINE_VERSION.tar.gz" ]; then
        wget "https://ftp.gnu.org/gnu/readline/readline-$READLINE_VERSION.tar.gz"
    fi
    rm -rf "readline-$READLINE_VERSION"
    tar -xf "readline-$READLINE_VERSION.tar.gz"
    (
        cd "readline-$READLINE_VERSION"
        # --with-curses=yes để đảm bảo nó liên kết với ncurses
        ./configure --prefix="$INSTALL_PREFIX" --with-curses
        make -j"$CPU_COUNT"
        make install
    )
    info "✅ Build Readline hoàn tất."
}

build_openssl() {
    info "--- 🚀 Bắt đầu build OpenSSL $OPENSSL_VERSION ---"
    cd "$SRC_DIR"
    local OPENSSL_ARCHIVE="openssl-$OPENSSL_VERSION.tar.gz"
    local OPENSSL_DIR="openssl-$OPENSSL_VERSION"

    if [ ! -f "$OPENSSL_ARCHIVE" ]; then
        info "📥 Đang tải OpenSSL ${OPENSSL_VERSION}..."
        wget -O "$OPENSSL_ARCHIVE" "https://www.openssl.org/source/$OPENSSL_ARCHIVE"
    fi
    rm -rf "$OPENSSL_DIR"
    info "📦 Đang giải nén..."
    tar -xzf "$OPENSSL_ARCHIVE"
    (
        cd "$OPENSSL_DIR"
        info "⚙️  Đang cấu hình OpenSSL..."
        # 'shared' rất quan trọng để build .so cho Ruby
        ./config shared --prefix="$INSTALL_PREFIX" --openssldir="$INSTALL_PREFIX/ssl"
        
        info "🚀 Đang build và cài đặt OpenSSL..."
        make -j"$CPU_COUNT"
        make install
    )
    # Tạo file .pc (như script của bạn)
    local OPENSSL_PC="$INSTALL_PREFIX/lib/pkgconfig/openssl.pc"
    if [ ! -f "$OPENSSL_PC" ]; then
        info "🧩 Đang tạo file openssl.pc để hỗ trợ pkg-config..."
        # Dùng 'cat <<EOF' thay vì 'cat >' để tránh lỗi quyền
        cat <<EOF > "$OPENSSL_PC"
prefix=$INSTALL_PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib64
includedir=\${prefix}/include

Name: OpenSSL
Description: Secure Sockets Layer and cryptography libraries
Version: ${OPENSSL_VERSION}
Libs: -L\${libdir} -lssl -lcrypto
Cflags: -I\${includedir}
EOF
        # Trên nhiều hệ thống 64-bit, OpenSSL cài vào lib64
        # Chỉnh sửa lại file .pc để trỏ đúng
        sed -i "s|libdir=\${exec_prefix}/lib|libdir=\${exec_prefix}/lib64|" "$OPENSSL_PC"
        # Nếu thư mục lib64 không tồn tại, dùng lib
        if [ ! -d "$INSTALL_PREFIX/lib64" ]; then
             sed -i "s|libdir=\${exec_prefix}/lib64|libdir=\${exec_prefix}/lib|" "$OPENSSL_PC"
        fi
    fi
    info "✅ Build OpenSSL hoàn tất."
}

## --- Hàm Kiểm tra Dependencies Chính (Yêu cầu 3) ---

check_or_build_deps() {
    info "Kiểm tra dependencies cho Ruby build..."
    
    # Đảm bảo pkg-config tồn tại
    if ! command -v pkg-config &>/dev/null; then
        warn "Không tìm thấy 'pkg-config'. Việc kiểm tra dependencies có thể không chính xác."
        warn "Đang tiếp tục, nhưng build có thể thất bại."
    fi

    # 1. OpenSSL
    if ! pkg-config --exists openssl; then
        warn "Không tìm thấy 'openssl' qua pkg-config. Đang thử build từ source..."
        build_openssl
    else
        info "  [OK] Tìm thấy OpenSSL."
    fi

    # 2. Readline
    if ! pkg-config --exists readline; then
        warn "Không tìm thấy 'readline' qua pkg-config. Đang thử build từ source..."
        build_readline
    else
        info "  [OK] Tìm thấy Readline."
    fi
    
    # 3. LibYAML
    # Tên .pc của libyaml là 'yaml-0.1'
    if ! pkg-config --exists yaml-0.1; then 
        warn "Không tìm thấy 'libyaml' (yaml-0.1) qua pkg-config. Đang thử build từ source..."
        build_libyaml
    else
        info "  [OK] Tìm thấy LibYAML."
    fi

    # 4. Zlib (thường không có .pc, kiểm tra header)
    if ! echo "#include <zlib.h>" | gcc -E $CPPFLAGS - >/dev/null 2>&1; then
         warn "Không tìm thấy header 'zlib.h'. Đang thử build từ source..."
         build_zlib
    else
        info "  [OK] Tìm thấy zlib.h."
    fi

    info "Hoàn tất kiểm tra và build dependencies."
}


## --- Bắt đầu Cài đặt ---

info "Bắt đầu kiểm tra các công cụ build cơ bản..."
ESSENTIAL_TOOLS=("git" "gcc" "make" "curl" "wget" "tar")
for tool in "${ESSENTIAL_TOOLS[@]}"; do
  if ! command -v "$tool" &>/dev/null; then
    error "Không tìm thấy công cụ '$tool'. Đây là yêu cầu bắt buộc."
    error "Vui lòng cài đặt '$tool' trước khi chạy lại script này."
  fi
done
info "Đã tìm thấy các công cụ build cơ bản."

# Chạy kiểm tra và build dependencies
check_or_build_deps


## --- Cài đặt rbenv và ruby-build ---

info "Bắt đầu cài đặt rbenv vào $RBENV_DIR..."

# Cài đặt hoặc cập nhật rbenv
if [ -d "$RBENV_DIR" ]; then
  info "Thư mục rbenv đã tồn tại. Đang cập nhật (git pull)..."
  (cd "$RBENV_DIR" && git pull)
else
  info "Đang clone rbenv từ GitHub..."
  git clone https://github.com/rbenv/rbenv.git "$RBENV_DIR"
fi

# Cài đặt hoặc cập nhật plugin ruby-build
RB_BUILD_DIR="$RBENV_DIR/plugins/ruby-build"
info "Cài đặt plugin ruby-build vào $RB_BUILD_DIR..."
mkdir -p "$(dirname "$RB_BUILD_DIR")"

if [ -d "$RB_BUILD_DIR" ]; then
  info "Thư mục ruby-build đã tồn tại. Đang cập nhật (git pull)..."
  (cd "$RB_BUILD_DIR" && git pull)
else
  info "Đang clone ruby-build từ GitHub..."
  git clone https://github.com/rbenv/ruby-build.git "$RB_BUILD_DIR"
fi

info "Cài đặt rbenv và ruby-build thành công."


## --- Cập nhật Shell Config (Yêu cầu 4) ---

info "Tự động cập nhật shell config..."

SHELL_CONFIG_FILE=""
CURRENT_SHELL="$(basename "$SHELL")"

if [ "$CURRENT_SHELL" = "bash" ]; then
  SHELL_CONFIG_FILE="$HOME/.bashrc"
elif [ "$CURRENT_SHELL" = "zsh" ]; then
  SHELL_CONFIG_FILE="$HOME/.zshrc"
else
  warn "Không thể tự động phát hiện shell config cho '$CURRENT_SHELL'."
fi

# Các dòng cấu hình MỚI (bao gồm cả env vars cho build)
CONFIG_LINES=(
    ""
    "# --- Cấu hình Ruby, rbenv, và Dependencies (Thêm bởi script) ---"
    '# Chỉ cho ruby-build tìm các thư viện đã build trong .local'
    'export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:$HOME/.local/lib64/pkgconfig:${PKG_CONFIG_PATH:-}"'
    'export CPPFLAGS="-I$HOME/.local/include"'
    'export LDFLAGS="-L$HOME/.local/lib -L$HOME/.local/lib64"'
    ''
    '# Cấu hình rbenv'
    'export PATH="$HOME/.local/bin:$HOME/.local/rbenv/bin:$PATH"'
    'eval "$(rbenv init -)"'
)

if [ -n "$SHELL_CONFIG_FILE" ] && [ -f "$SHELL_CONFIG_FILE" ]; then
  # Kiểm tra xem dòng 'rbenv init' đã tồn tại chưa
  if ! grep -q 'rbenv init' "$SHELL_CONFIG_FILE"; then
    info "Thêm cấu hình rbenv và build env vào $SHELL_CONFIG_FILE..."
    
    # Thêm vào cuối file
    printf "%s\n" "${CONFIG_LINES[@]}" >> "$SHELL_CONFIG_FILE"
    
    info "Đã thêm cấu hình."
  else
    info "Cấu hình 'rbenv init' dường như đã tồn tại trong $SHELL_CONFIG_FILE."
    warn "Vui lòng ĐẢM BẢO BẰNG TAY rằng bạn đã có các biến PKG_CONFIG_PATH, CPPFLAGS, LDFLAGS"
    warn "trỏ đến $HOME/.local (như trên) để build Ruby thành công."
  fi
  
  info "-------------------------------------------------------------------"
  info "✅ CÀI ĐẶT HOÀN TẤT!"
  info "Tất cả dependencies (openssl, zlib,...) đã được build vào $LOCAL_DIR"
  info "Vui lòng khởi động lại shell của bạn hoặc chạy lệnh sau để áp dụng:"
  info "  source $SHELL_CONFIG_FILE"
  info ""
  info "Sau đó, hãy thử cài đặt một phiên bản Ruby:"
  info "  rbenv install --list"
  info "  rbenv install 3.2.3"
  info "-------------------------------------------------------------------"
  
else
  # Trường hợp không tìm thấy file config hoặc shell không xác định
  warn "Vui lòng tự thêm các dòng sau vào file cấu hình shell của bạn:"
  printf "%s\n" "${CONFIG_LINES[@]}"
  info "Cài đặt rbenv và dependencies đã xong, nhưng cần cấu hình shell thủ công."
fi
