#!/bin/bash

# Script cài đặt Python và pip cho user
# Sử dụng version cứng Python 3.13.7

set -e  # Dừng script nếu có lỗi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}Bắt đầu cài đặt Python và pip cho user...${NC}"

# Hàm hỏi người dùng Yes/No
ask_yes_no() {
    local prompt="$1 (y/N): "
    local response=""
    
    read -rp "$prompt" response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Version cứng
PYTHON_VERSION="3.12.8"
MAJOR_MINOR="3.12"
PYTHON_TGZ="Python-${PYTHON_VERSION}.tgz"
PYTHON_URL="https://www.python.org/ftp/python/${PYTHON_VERSION}/${PYTHON_TGZ}"

echo -e "${GREEN}✅ Sử dụng Python version cố định: $PYTHON_VERSION${NC}"

# Hàm detect shell rc
detect_shell_rc() {
    case "$SHELL" in
        *bash) 
            if [ -f "$HOME/.bashrc" ]; then
                echo "$HOME/.bashrc"
            elif [ -f "$HOME/.bash_profile" ]; then
                echo "$HOME/.bash_profile"
            else
                echo "$HOME/.bashrc"
            fi
            ;;
        *zsh) 
            if [ -f "$HOME/.zshrc" ]; then
                echo "$HOME/.zshrc"
            else
                echo "$HOME/.zshrc"
            fi
            ;;
        *fish) 
            if [ -f "$HOME/.config/fish/config.fish" ]; then
                echo "$HOME/.config/fish/config.fish"
            else
                echo "$HOME/.config/fish/config.fish"
            fi
            ;;
        *) 
            if [ -f "$HOME/.profile" ]; then
                echo "$HOME/.profile"
            else
                echo "$HOME/.profile"
            fi
            ;;
    esac
}

# Hàm kiểm tra và thêm vào shell config
add_to_shell_config() {
    echo -e "${YELLOW}Kiểm tra và thêm PATH vào shell config...${NC}"
    
    local shell_rc=$(detect_shell_rc)
    local shell_name=$(basename "$SHELL")
    
    echo -e "${BLUE}Phát hiện shell: $shell_name${NC}"
    echo -e "${BLUE}File config: $shell_rc${NC}"
    
    # Tạo file nếu không tồn tại
    if [ ! -f "$shell_rc" ]; then
        echo -e "${YELLOW}Tạo file config mới: $shell_rc${NC}"
        mkdir -p "$(dirname "$shell_rc")"
        touch "$shell_rc"
    fi
    
    local add_line='export PATH="$HOME/.local/bin:$PATH"'
    local fish_line='set -gx PATH "$HOME/.local/bin" $PATH'
    
    # Kiểm tra xem PATH đã được thêm chưa
    if ! grep -q "\.local/bin" "$shell_rc"; then
        echo -e "${YELLOW}Thêm PATH vào $shell_rc...${NC}"
        echo "" >> "$shell_rc"
        echo "# User local bin directory" >> "$shell_rc"
        
        if [[ "$shell_rc" == *"fish"* ]]; then
            echo "$fish_line" >> "$shell_rc"
        else
            echo "$add_line" >> "$shell_rc"
        fi
        
        echo -e "${GREEN}✅ Đã thêm PATH vào $shell_rc${NC}"
    else
        echo -e "${YELLOW}✅ PATH đã có trong $shell_rc${NC}"
    fi
    
    # Thêm vào PATH hiện tại
    export PATH="$HOME/.local/bin:$PATH"
    echo -e "${GREEN}✅ Đã thêm PATH vào session hiện tại${NC}"
}

# Tạo thư mục cài đặt
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
BIN_DIR="$PREFIX/bin"

mkdir -p "$SRC_DIR"
mkdir -p "$BIN_DIR"

echo -e "${YELLOW}Thư mục cài đặt: $PREFIX${NC}"
echo -e "${YELLOW}Thư mục source: $SRC_DIR${NC}"

# Kiểm tra xem Python đã được cài đặt chưa
CURRENT_PYTHON=""
CURRENT_PIP=""
NEEDS_UPGRADE=0

if [ -f "$BIN_DIR/python" ]; then
    CURRENT_PYTHON=$("$BIN_DIR/python" --version 2>&1 | awk '{print $2}')
    echo -e "${GREEN}Đã phát hiện Python $CURRENT_PYTHON đã cài đặt${NC}"
fi

if [ -f "$BIN_DIR/pip" ]; then
    CURRENT_PIP=$("$BIN_DIR/pip" --version 2>&1 | awk '{print $2}')
    echo -e "${GREEN}Đã phát hiện pip $CURRENT_PIP đã cài đặt${NC}"
fi

# Hỏi người dùng nếu đã có cài đặt
if [ -n "$CURRENT_PYTHON" ]; then
    echo -e "${CYAN}Python $CURRENT_PYTHON đã được cài đặt${NC}"
    
    if [ "$CURRENT_PYTHON" = "$PYTHON_VERSION" ]; then
        echo -e "${GREEN}Bạn đã sử dụng phiên bản $PYTHON_VERSION${NC}"
        
        if ask_yes_no "Bạn có muốn cài đặt lại Python?"; then
            echo -e "${YELLOW}Chuẩn bị cài đặt lại Python...${NC}"
        else
            echo -e "${GREEN}Giữ nguyên cài đặt hiện tại${NC}"
            
            # Vẫn kiểm tra và thêm PATH nếu cần
            add_to_shell_config
            
            echo -e "${GREEN}Python: $($BIN_DIR/python --version 2>&1)${NC}"
            echo -e "${GREEN}Pip: $($BIN_DIR/pip --version 2>&1)${NC}"
            exit 0
        fi
    else
        echo -e "${YELLOW}Phiên bản hiện tại: $CURRENT_PYTHON${NC}"
        echo -e "${YELLOW}Phiên bản sẽ cài: $PYTHON_VERSION${NC}"
        
        if ask_yes_no "Bạn có muốn nâng cấp lên Python $PYTHON_VERSION?"; then
            NEEDS_UPGRADE=1
            echo -e "${YELLOW}Chuẩn bị nâng cấp Python...${NC}"
        elif ask_yes_no "Bạn có muốn cài đặt lại Python $PYTHON_VERSION?"; then
            echo -e "${YELLOW}Chuẩn bị cài đặt lại Python...${NC}"
        else
            echo -e "${GREEN}Giữ nguyên cài đặt hiện tại${NC}"
            exit 0
        fi
    fi
fi

# Tải và cài đặt Python
cd "$SRC_DIR"
echo -e "${YELLOW}Đang tải Python $PYTHON_VERSION...${NC}"
echo -e "${BLUE}URL: $PYTHON_URL${NC}"

# Hàm tải Python
download_python() {
    echo -e "${BLUE}Đang tải $PYTHON_TGZ...${NC}"
    
    if command -v wget &> /dev/null; then
        if wget --spider -q "$PYTHON_URL" 2>/dev/null; then
            wget -q --show-progress "$PYTHON_URL"
            return 0
        fi
    elif command -v curl &> /dev/null; then
        if curl --output /dev/null --silent --head --fail "$PYTHON_URL"; then
            curl -LO --progress-bar "$PYTHON_URL"
            return 0
        fi
    fi
    
    echo -e "${RED}Không thể tải Python $PYTHON_VERSION${NC}"
    return 1
}

# Kiểm tra xem file đã tồn tại chưa
if [ -f "$PYTHON_TGZ" ]; then
    echo -e "${GREEN}✅ File $PYTHON_TGZ đã tồn tại, bỏ qua tải về${NC}"
else
    if ! download_python; then
        echo -e "${RED}❌ Lỗi: Không thể tải Python $PYTHON_VERSION${NC}"
        echo -e "${YELLOW}Vui lòng kiểm tra kết nối internet${NC}"
        exit 1
    fi
fi

# Kiểm tra kích thước file
FILE_SIZE=$(stat -c%s "$PYTHON_TGZ" 2>/dev/null || stat -f%z "$PYTHON_TGZ" 2>/dev/null || echo 0)
if [ "$FILE_SIZE" -lt 1000000 ]; then
    echo -e "${RED}❌ File tải về có vẻ bị lỗi (kích thước: $FILE_SIZE bytes)${NC}"
    echo -e "${YELLOW}Xóa file và thử tải lại...${NC}"
    rm -f "$PYTHON_TGZ"
    
    if ! download_python; then
        echo -e "${RED}❌ Lỗi: Không thể tải Python $PYTHON_VERSION${NC}"
        exit 1
    fi
fi

# Giải nén
echo -e "${YELLOW}Đang giải nén Python...${NC}"
if [ -f "$PYTHON_TGZ" ]; then
    tar -xzf "$PYTHON_TGZ"
    cd "Python-$PYTHON_VERSION"
else
    echo -e "${RED}❌ File $PYTHON_TGZ không tồn tại${NC}"
    exit 1
fi

# Cấu hình và biên dịch
echo -e "${YELLOW}Đang cấu hình Python...${NC}"
./configure --prefix="$PREFIX" --enable-optimizations --with-ensurepip=install

echo -e "${YELLOW}Đang biên dịch Python...${NC}"
CORES=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)
echo -e "${BLUE}Sử dụng $CORES cores để biên dịch${NC}"
make -j$CORES

# Cài đặt
echo -e "${YELLOW}Đang cài đặt Python...${NC}"
make install

# Tạo symbolic links
echo -e "${YELLOW}Tạo symbolic links...${NC}"
ln -sf "$PREFIX/bin/python3" "$BIN_DIR/python"
ln -sf "$PREFIX/bin/pip3" "$BIN_DIR/pip"

# Đảm bảo pip hoạt động
if [ ! -f "$BIN_DIR/pip" ]; then
    echo -e "${YELLOW}Đảm bảo pip được cài đặt...${NC}"
    "$BIN_DIR/python" -m ensurepip --default-pip
    "$BIN_DIR/python" -m pip install --upgrade pip
fi

# Kiểm tra và thêm vào shell config
add_to_shell_config

# Kiểm tra cài đặt
echo -e "${YELLOW}Kiểm tra cài đặt...${NC}"
if [ -f "$BIN_DIR/python" ] && [ -f "$BIN_DIR/pip" ]; then
    echo -e "${GREEN}✅ Cài đặt thành công!${NC}"
    echo "Python: $($BIN_DIR/python --version 2>&1)"
    echo "Pip: $($BIN_DIR/pip --version 2>&1)"
    echo ""
    echo -e "${YELLOW}Để sử dụng ngay lập tức, chạy:${NC}"
    echo "source $(detect_shell_rc)"
    echo ""
    echo -e "${YELLOW}Hoặc khởi động lại terminal${NC}"
else
    echo -e "${RED}❌ Cài đặt thất bại!${NC}"
    exit 1
fi

# Dọn dẹp
if ask_yes_no "Bạn có muốn dọn dẹp file source đã giải nén?"; then
    echo -e "${YELLOW}Dọn dẹp file tạm...${NC}"
    rm -rf "$SRC_DIR/Python-$PYTHON_VERSION"
    echo -e "${GREEN}✅ Đã dọn dẹp file source${NC}"
else
    echo -e "${YELLOW}📁 Giữ lại file source trong $SRC_DIR/${NC}"
fi

echo -e "${GREEN}🎉 Hoàn thành! Python $PYTHON_VERSION đã được cài đặt thành công!${NC}"
echo -e "${BLUE}📍 Python được cài tại: $PREFIX/bin/python${NC}"
echo -e "${BLUE}📍 Pip được cài tại: $PREFIX/bin/pip${NC}"
