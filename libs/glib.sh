#!/bin/bash

# --- CẤU HÌNH GLIB 2.0 ---
GLIB_VERSION="2.86.1" 
GLIB_TARBALL="glib-$GLIB_VERSION.tar.xz"
DOWNLOAD_URL="https://download.gnome.org/sources/glib/2.86/$GLIB_TARBALL"
GLIB_DIR="glib-$GLIB_VERSION"
BUILD_DIR="build"

# Đường dẫn cài đặt (Sử dụng chung DEPS_PREFIX)
export PREFIX="$HOME/.local" 
export SRC_DIR="$HOME/src/py-build-deps"

# --- Màu sắc ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "\n${YELLOW}--- BẮT ĐẦU CÀI ĐẶT GLIB ${GLIB_VERSION} (Tối ưu hóa đường dẫn) ---${NC}"
set -e # Thoát nếu có lỗi

## 1. THIẾT LẬP BAN ĐẦU
echo -e "\n${YELLOW}--- THIẾT LẬP BIẾN MÔI TRƯỜNG & CÔNG CỤ ---${NC}"

# Đảm bảo các thư mục đã tồn tại
mkdir -p "${PREFIX}"
mkdir -p "${SRC_DIR}"

# Thiết lập PKG_CONFIG_PATH hiện tại để Meson tìm thấy các deps khác (như libffi)
# Tạm thời chỉ trỏ đến /lib, sẽ dùng script để ghi đè cài đặt.
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PREFIX}/lib64/pkgconfig:${PKG_CONFIG_PATH}"
export LDFLAGS="-L${PREFIX}/lib -L${PREFIX}/lib64 -Wl,-rpath,${PREFIX}/lib -Wl,-rpath,${PREFIX}/lib64 ${LDFLAGS}"
export CPPFLAGS="-I${PREFIX}/include ${CPPFLAGS}"
export PATH="${PREFIX}/bin:$PATH"

# ... (Phần kiểm tra công cụ meson/ninja/wget/tar) ...
for tool in meson ninja wget tar; do
    if ! command -v $tool &> /dev/null; then
        echo -e "${RED}❌ Lỗi: Công cụ '$tool' chưa được cài đặt. Vui lòng cài đặt nó.${NC}"
        exit 1
    fi
done
echo -e "${GREEN}✅ Các công cụ build (Meson/Ninja) đã sẵn sàng.${NC}"

## 2. TẢI VÀ GIẢI NÉN MÃ NGUỒN
echo -e "\n${YELLOW}--- TẢI VÀ GIẢI NÉN GLIB ---${NC}"
cd "$SRC_DIR"
if [ ! -f "$GLIB_TARBALL" ]; then wget "$DOWNLOAD_URL"; fi
if [ -d "$GLIB_DIR" ]; then rm -rf "$GLIB_DIR"; fi
tar xf "$GLIB_TARBALL"
cd "$GLIB_DIR"

## 3. BIÊN DỊCH VÀ CÀI ĐẶT (QUAN TRỌNG!)
echo -e "\n${YELLOW}--- BIÊN DỊCH VÀ CÀI ĐẶT GLIB ---${NC}"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "Đang cấu hình Meson. Sử dụng cờ -Dlibdir=lib để ép cài đặt vào ${PREFIX}/lib..."
# Cờ quan trọng:
# -Dlibdir=lib: Đảm bảo lib files (bao gồm pkgconfig) đi vào $PREFIX/lib thay vì $PREFIX/lib/x86_64-linux-gnu
if ! meson setup --prefix="$PREFIX" \
                 --buildtype=release \
                 -Dlibdir=lib \
                 -Dselinux=disabled \
                 -Dlibmount=disabled \
                 -Dman=false \
                 -Dgtk_doc=false \
                 -Dinstalled_tests=false \
                 ..; then
    echo -e "${RED}❌ LỖI CẤU HÌNH MESON.${NC}"
    exit 1
fi

echo "Đang biên dịch và cài đặt..."
ninja -j$(nproc) && ninja install
echo -e "${GREEN}✅ Cài đặt GLib $GLIB_VERSION hoàn tất.${NC}"

## 4. TỰ ĐỘNG CẬP NHẬT CẤU HÌNH SHELL
echo -e "\n${YELLOW}--- TỰ ĐỘNG CẬP NHẬT CẤU HÌNH SHELL ---${NC}"
SHELL_CONFIG_FILE=""
CURRENT_SHELL=$(basename "$SHELL")
if [ "$CURRENT_SHELL" = "bash" ]; then SHELL_CONFIG_FILE="$HOME/.bashrc";
elif [ "$CURRENT_SHELL" = "zsh" ]; then SHELL_CONFIG_FILE="$HOME/.zshrc";
fi

# Các dòng cấu hình cần thêm/kiểm tra
CONFIG_LINES=(
    "export PATH=\"$HOME/.local/bin:\$PATH\""
    "export PKG_CONFIG_PATH=\"$HOME/.local/lib/pkgconfig:\$PKG_CONFIG_PATH\""
    "export LD_LIBRARY_PATH=\"$HOME/.local/lib:\$LD_LIBRARY_PATH\""
)

if [ -n "$SHELL_CONFIG_FILE" ]; then
    echo "Phát hiện shell: $CURRENT_SHELL. Cập nhật file: $SHELL_CONFIG_FILE"
    CONFIG_NEEDED=false

    for line in "${CONFIG_LINES[@]}"; do
        if ! grep -q "$(echo "$line" | sed 's/[[:space:]]*//g')" "$SHELL_CONFIG_FILE"; then
            echo "Thêm dòng: $line"
            echo -e "\n# Cấu hình thư viện cục bộ (Được thêm bởi script build)" >> "$SHELL_CONFIG_FILE"
            echo "$line" >> "$SHELL_CONFIG_FILE"
            CONFIG_NEEDED=true
        fi
    done

    if $CONFIG_NEEDED; then
        echo -e "${GREEN}==> Cấu hình SHELL đã được cập nhật!${NC}"
        echo "Vui lòng chạy 'source $SHELL_CONFIG_FILE' hoặc khởi động lại terminal."
    else
        echo "Các biến môi trường đã tồn tại, không cần cập nhật."
    fi
else
    echo "${RED}Không thể tự động cập nhật PATH/PKG_CONFIG_PATH cho shell: $CURRENT_SHELL${NC}"
fi

## 5. KIỂM TRA KẾT QUẢ CUỐI CÙNG
echo -e "\n${YELLOW}--- KIỂM TRA SAU KHI CÀI ĐẶT ---${NC}"
# Cần chạy lệnh export thủ công để kiểm tra ngay lập tức
export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH"
if pkg-config --modversion glib-2.0 &> /dev/null; then
    echo -e "${GREEN}✅ GLib đã được tìm thấy qua pkg-config: $(pkg-config --modversion glib-2.0)${NC}"
else
    echo -e "${RED}❌ LỖI: pkg-config vẫn không tìm thấy glib-2.0. Vui lòng kiểm tra file cấu hình vừa tạo.${NC}"
fi
echo -e "------------------------------------------------------------------${NC}"
