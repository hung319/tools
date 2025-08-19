#!/bin/bash

# build_python_symlink.sh
# Script biên dịch và cài đặt Python 3.13, tự động build Tcl/Tk nếu cần.
# Sử dụng symlinks để lệnh `python` và `pip` trỏ đúng phiên bản 3.13.
# Cài đặt mọi thứ vào $HOME/.local mà không cần quyền root.

# --- Cấu hình ---
PYTHON_VERSION="3.13.0" # Thay bằng phiên bản 3.13.x mới nhất khi có
PYTHON_MAJOR_VERSION="3.13"
TCL_VERSION="8.6.14"
TK_VERSION="8.6.14"

# --- Đường dẫn ---
SRC_DIR="$HOME/src"
INSTALL_DIR="$HOME/.local"
BIN_DIR="$INSTALL_DIR/bin"

# Dừng script ngay khi có lỗi
set -euo pipefail

# --- Hàm Build Tcl/Tk (chỉ chạy khi cần) ---
build_tcl_tk() {
    echo "🏗️  Bắt đầu quá trình build Tcl/Tk từ mã nguồn..."
    mkdir -p "$SRC_DIR"
    cd "$SRC_DIR"

    # --- Build Tcl ---
    echo "    - Đang tải và biên dịch Tcl v${TCL_VERSION}..."
    wget -q --show-progress -O "tcl${TCL_VERSION}-src.tar.gz" "https://downloads.sourceforge.net/project/tcl/Tcl/${TCL_VERSION}/tcl${TCL_VERSION}-src.tar.gz"
    tar -xzf "tcl${TCL_VERSION}-src.tar.gz"
    cd "tcl${TCL_VERSION}/unix"
    ./configure --prefix="$INSTALL_DIR" --enable-threads > /dev/null
    make -j"$(nproc || echo 1)" > /dev/null
    make install > /dev/null
    cd ../..
    echo "    ✅ Cài đặt Tcl thành công."

    # --- Build Tk ---
    echo "    - Đang tải và biên dịch Tk v${TK_VERSION}..."
    wget -q --show-progress -O "tk${TK_VERSION}-src.tar.gz" "https://downloads.sourceforge.net/project/tcl/Tcl/${TK_VERSION}/tk${TK_VERSION}-src.tar.gz"
    tar -xzf "tk${TK_VERSION}-src.tar.gz"
    cd "tk${TK_VERSION}/unix"
    ./configure --prefix="$INSTALL_DIR" --with-tcl="$INSTALL_DIR/lib" --enable-threads > /dev/null
    make -j"$(nproc || echo 1)" > /dev/null
    make install > /dev/null
    cd ../..
    echo "    ✅ Cài đặt Tk thành công."
    
    echo "✅ Build và cài đặt Tcl/Tk hoàn tất."
}

# --- Hàm kiểm tra ---
check_dependencies() {
    echo "🔎 Đang kiểm tra các công cụ và thư viện cần thiết..."
    
    command -v gcc >/dev/null 2>&1 || { echo >&2 "❌ Lỗi: 'gcc' không tồn tại. Vui lòng cài đặt bộ công cụ build (build-essential)."; exit 1; }
    command -v make >/dev/null 2>&1 || { echo >&2 "❌ Lỗi: 'make' không tồn tại. Vui lòng cài đặt bộ công cụ build (build-essential)."; exit 1; }
    command -v wget >/dev/null 2>&1 || { echo >&2 "❌ Lỗi: 'wget' không tồn tại. Vui lòng cài đặt wget."; exit 1; }

    if pkg-config --exists tcl tk >/dev/null 2>&1; then
        echo "👍 Đã tìm thấy thư viện Tcl/Tk trên hệ thống. Sẽ sử dụng chúng."
        export TCLTK_CFLAGS=$(pkg-config --cflags tcl tk)
        export TCLTK_LIBS=$(pkg-config --libs tcl tk)
    else
        echo "⚠️ Không tìm thấy thư viện Tcl/Tk. Sẽ tự động build từ mã nguồn."
        build_tcl_tk
        export TCLTK_CFLAGS="-I${INSTALL_DIR}/include"
        export TCLTK_LIBS="-L${INSTALL_DIR}/lib -ltcl8.6 -ltk8.6"
    fi
}

# --- Hàm tải và giải nén Python ---
download_and_extract_python() {
    mkdir -p "$SRC_DIR"
    cd "$SRC_DIR"
    
    local tarball="Python-${PYTHON_VERSION}.tgz"
    local url="https://www.python.org/ftp/python/${PYTHON_VERSION}/${tarball}"

    echo "🌐 Đang tải Python ${PYTHON_VERSION}..."
    wget -q --show-progress -O "$tarball" "$url"
    
    echo "📦 Đang giải nén ${tarball}..."
    tar -xzf "$tarball"
    cd "Python-${PYTHON_VERSION}"
}

# --- Hàm biên dịch và cài đặt Python ---
build_and_install_python() {
    echo "🛠️  Bắt đầu quá trình biên dịch và cài đặt Python..."
    
    echo "    - Đang cấu hình bản build với hỗ trợ tkinter..."
    CPPFLAGS="${TCLTK_CFLAGS}" LDFLAGS="${TCLTK_LIBS}" ./configure \
        --prefix="$INSTALL_DIR" \
        --enable-optimizations \
        --with-ensurepip=install > /dev/null

    local core_count
    core_count=$(nproc || echo 1)
    echo "    - Đang biên dịch với ${core_count} lõi CPU (có thể mất vài phút)..."
    make -j"$core_count" > /dev/null
    
    echo "    - Đang cài đặt vào ${INSTALL_DIR}..."
    make install > /dev/null
    
    echo "✅ Quá trình biên dịch và cài đặt Python hoàn tất."
}

# --- Hàm tạo Symlink ---
create_symlinks() {
    echo "🔗 Đang tạo các liên kết để có thể dùng lệnh 'python' và 'pip' trực tiếp..."
    cd "$BIN_DIR"
    ln -sf "python${PYTHON_MAJOR_VERSION}" python
    ln -sf "pip${PYTHON_MAJOR_VERSION}" pip
    echo "✅ Tạo liên kết thành công: python -> python${PYTHON_MAJOR_VERSION}, pip -> pip${PYTHON_MAJOR_VERSION}."
}

# --- Hàm cấu hình Shell (chỉ thêm PATH) ---
setup_shell_env() {
    echo "🐚 Đang cấu hình môi trường shell..."
    
    local shell_type
    shell_type=$(basename "$SHELL")
    local rc_file

    if [ "$shell_type" = "bash" ]; then
        rc_file="$HOME/.bashrc"
    elif [ "$shell_type" = "zsh" ]; then
        rc_file="$HOME/.zshrc"
    else
        echo "⚠️ Không nhận diện được shell ($shell_type). Vui lòng thêm '$BIN_DIR' vào PATH thủ công."
        return
    fi
    
    echo "    - Sẽ cập nhật tệp: ${rc_file}"
    
    if ! grep -q "export PATH=\"${BIN_DIR}:\$PATH\"" "$rc_file"; then
        echo "    - Thêm ${BIN_DIR} vào PATH."
        echo -e '\n# Thêm thư mục cài đặt Python tùy chỉnh vào PATH' >> "$rc_file"
        echo "export PATH=\"${BIN_DIR}:\$PATH\"" >> "$rc_file"
    else
        echo "    - PATH đã được cấu hình từ trước."
    fi
    
    echo "✅ Cấu hình PATH hoàn tất."
}

# --- Main ---
main() {
    echo "🚀 Bắt đầu quá trình cài đặt Python ${PYTHON_VERSION} 🚀"
    
    check_dependencies
    download_and_extract_python
    build_and_install_python
    create_symlinks
    setup_shell_env
    
    echo ""
    echo "🎉 Cài đặt Python ${PYTHON_VERSION} thành công! 🎉"
    echo ""
    echo "Để áp dụng thay đổi, hãy chạy lệnh sau hoặc mở lại terminal:"
    echo "    source ~/.bashrc  (nếu bạn dùng bash)"
    echo "    source ~/.zshrc   (nếu bạn dùng zsh)"
    echo ""
    echo "Sau đó, kiểm tra phiên bản với các lệnh trực tiếp:"
    echo "    python --version"
    echo "    pip --version"
    echo "    python -m tkinter"
}

main
