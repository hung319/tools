#!/bin/bash

# --- Cấu hình ---
# Dừng script ngay lập tức nếu có lệnh nào thất bại
set -e

# Các thư mục cài đặt
INSTALL_DIR="$HOME/.local"
SOURCE_DIR="$HOME/src"
NUM_CORES=$(nproc) # Lấy số nhân CPU để build nhanh hơn

# --- Thiết lập môi trường ---
echo "--- Thiết lập môi trường và thư mục ---"
mkdir -p "$INSTALL_DIR/bin"
mkdir -p "$SOURCE_DIR"

# Thêm đường dẫn của thư mục cài đặt vào các biến môi trường
# để các tiến trình build có thể tìm thấy thư viện và tệp thực thi.
export PATH="$INSTALL_DIR/bin:$PATH"
export LD_LIBRARY_PATH="$INSTALL_DIR/lib:$INSTALL_DIR/lib64:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="$INSTALL_DIR/lib/pkgconfig:$INSTALL_DIR/lib64/pkgconfig:$PKG_CONFIG_PATH"
export CMAKE_PREFIX_PATH="$INSTALL_DIR:$CMAKE_PREFIX_PATH"

echo "Thư mục cài đặt: $INSTALL_DIR"
echo "Thư mục mã nguồn: $SOURCE_DIR"
echo "Sử dụng $NUM_CORES nhân CPU để biên dịch."
echo "----------------------------------------"
sleep 2

# --- 1. Kiểm tra trình biên dịch C++17 ---
echo "--- 1. Kiểm tra trình biên dịch C++17 ---"
COMPILER_OK=false
if command -v g++ >/dev/null; then
    GCC_VERSION=$(g++ -dumpversion | cut -d. -f1)
    if [ "$GCC_VERSION" -ge 7 ]; then
        echo "✅ Tìm thấy GCC phiên bản $GCC_VERSION (đạt yêu cầu >= 7)."
        COMPILER_OK=true
    fi
elif command -v clang++ >/dev/null; then
    CLANG_VERSION=$(clang++ --version | head -n 1 | grep -oP 'version \K[0-9]+' | cut -d. -f1)
    if [ "$CLANG_VERSION" -ge 5 ]; then
        echo "✅ Tìm thấy Clang phiên bản $CLANG_VERSION (đạt yêu cầu >= 5)."
        COMPILER_OK=true
    fi
fi

if [ "$COMPILER_OK" = false ]; then
    echo "❌ Không tìm thấy trình biên dịch C++17 tương thích (GCC 7+ hoặc Clang 5+)."
    echo "Vui lòng cài đặt 'build-essential' hoặc một trình biên dịch phù hợp."
    echo "Ví dụ trên Ubuntu/Debian: sudo apt-get update && sudo apt-get install build-essential"
    exit 1
fi
echo "----------------------------------------"
sleep 1

# --- 2. Cài đặt các Dependency nếu cần ---

# ZLIB
echo "--- 2.1. Kiểm tra và cài đặt zlib ---"
if [ ! -f "$INSTALL_DIR/lib/libz.a" ]; then
    echo "zlib chưa được cài đặt. Bắt đầu tải và build..."
    cd "$SOURCE_DIR"
    wget https://www.zlib.net/zlib-1.3.1.tar.gz -O zlib.tar.gz
    tar -xzf zlib.tar.gz
    cd zlib-1.3.1
    ./configure --prefix="$INSTALL_DIR"
    make -j"$NUM_CORES"
    make install
    cd ..
    rm -rf zlib-1.3.1 zlib.tar.gz
    echo "✅ Cài đặt zlib thành công."
else
    echo "✅ zlib đã được cài đặt."
fi
echo "----------------------------------------"
sleep 1

# OpenSSL
echo "--- 2.2. Kiểm tra và cài đặt OpenSSL ---"
if [ ! -f "$INSTALL_DIR/lib/libssl.a" ]; then
    echo "OpenSSL chưa được cài đặt. Bắt đầu tải và build..."
    cd "$SOURCE_DIR"
    git clone --depth 1 --branch openssl-3.3.1 https://github.com/openssl/openssl.git
    cd openssl
    ./config --prefix="$INSTALL_DIR" --openssldir="$INSTALL_DIR/ssl" no-shared
    make -j"$NUM_CORES"
    make install_sw
    cd ..
    rm -rf openssl
    echo "✅ Cài đặt OpenSSL thành công."
else
    echo "✅ OpenSSL đã được cài đặt."
fi
echo "----------------------------------------"
sleep 1

# gperf
echo "--- 2.3. Kiểm tra và cài đặt gperf ---"
if ! command -v gperf >/dev/null; then
    echo "gperf chưa được cài đặt. Bắt đầu tải và build..."
    cd "$SOURCE_DIR"
    wget http://ftp.gnu.org/pub/gnu/gperf/gperf-3.1.tar.gz
    tar -xzf gperf-3.1.tar.gz
    cd gperf-3.1
    ./configure --prefix="$INSTALL_DIR"
    make -j"$NUM_CORES"
    make install
    cd ..
    rm -rf gperf-3.1 gperf-3.1.tar.gz
    echo "✅ Cài đặt gperf thành công."
else
    echo "✅ gperf đã được cài đặt."
fi
echo "----------------------------------------"
sleep 1

# CMake
echo "--- 2.4. Kiểm tra và cài đặt CMake ---"
if ! command -v cmake >/dev/null || [[ "$(cmake --version | head -n1 | cut -d' ' -f3 | cut -d'.' -f1)" -lt 3 ]] || [[ "$(cmake --version | head -n1 | cut -d' ' -f3 | cut -d'.' -f2)" -lt 10 ]]; then
    echo "CMake chưa được cài đặt hoặc phiên bản quá cũ. Bắt đầu tải và build..."
    cd "$SOURCE_DIR"
    git clone --depth 1 --branch v3.29.3 https://github.com/Kitware/CMake.git
    cd CMake
    ./bootstrap --prefix="$INSTALL_DIR"
    make -j"$NUM_CORES"
    make install
    cd ..
    rm -rf CMake
    echo "✅ Cài đặt CMake thành công."
else
    echo "✅ CMake đã được cài đặt."
fi
echo "----------------------------------------"
sleep 1

# --- 3. Build telegram-bot-api ---
echo "--- 3. Bắt đầu build telegram-bot-api ---"
cd "$HOME" # Chuyển về thư mục home để clone vào $HOME/src như yêu cầu
if [ ! -d "telegram-bot-api" ]; then
    echo "Tải mã nguồn telegram-bot-api..."
    git clone --recursive https://github.com/tdlib/telegram-bot-api.git
else
    echo "Thư mục telegram-bot-api đã tồn tại, bỏ qua bước tải."
fi

cd telegram-bot-api
echo "Tạo thư mục build..."
rm -rf build # Xóa thư mục build cũ nếu có
mkdir build
cd build

echo "Chạy CMake để cấu hình project..."
# CMAKE_PREFIX_PATH đã được export ở trên sẽ giúp CMake tìm thấy các thư viện
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" ..

echo "Biên dịch và cài đặt với $NUM_CORES nhân CPU..."
# Tham số -- -j$NUM_CORES được truyền tới công cụ build (make)
cmake --build . --target install -- -j"$NUM_CORES"

echo ""
echo "🎉🎉🎉 HOÀN TẤT! 🎉🎉🎉"
echo "telegram-bot-api và các dependency đã được cài đặt vào: $INSTALL_DIR"
echo "Bạn có thể cần thêm dòng sau vào file ~/.bashrc hoặc ~/.zshrc để sử dụng chúng trong các phiên terminal mới:"
echo ""
echo 'export PATH="$HOME/.local/bin:$PATH"'
echo 'export LD_LIBRARY_PATH="$HOME/.local/lib:$HOME/.local/lib64:$LD_LIBRARY_PATH"'
echo ""
