#!/bin/bash
set -e

# --- Các biến cấu hình ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
GTK4_VER="4.20.0"
GTK4_URL="https://download.gnome.org/sources/gtk/4.20/gtk-$GTK4_VER.tar.xz"

# --- Chuẩn bị thư mục ---
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Tải và giải nén ---
if [ ! -f "gtk-$GTK4_VER.tar.xz" ]; then
    curl -LO "$GTK4_URL"
fi

rm -rf "gtk-$GTK4_VER"
tar -xf "gtk-$GTK4_VER.tar.xz"
cd "gtk-$GTK4_VER"

# ==============================================================================
# THIẾT LẬP MÔI TRƯỜNG BUILD ĐẦY ĐỦ (Phần quan trọng nhất)
# ==============================================================================
echo "--- 🔩 Thiết lập môi trường build toàn diện ---"

# Xác định đường dẫn thư viện đa kiến trúc (multi-arch), ví dụ: /lib/x86_64-linux-gnu
# Lệnh `uname -m` sẽ trả về kiến trúc máy của bạn (vd: x86_64, aarch64)
MULTIARCH_LIB_DIR="$PREFIX/lib/$(uname -m)-linux-gnu"

# Thiết lập PATH để tìm các công cụ đã build trước đó (g-ir-scanner, glib-compile-resources...)
export PATH="$PREFIX/bin:$PATH"

# Thiết lập đường dẫn để linker tìm thư viện (.so) lúc chạy và build
# Thêm cả hai đường dẫn `lib` và `lib/<multiarch>` để tăng tính tương thích
export LD_LIBRARY_PATH="$PREFIX/lib:$MULTIARCH_LIB_DIR:${LD_LIBRARY_PATH:-}"

# Thiết lập đường dẫn để pkg-config tìm file .pc
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$MULTIARCH_LIB_DIR/pkgconfig:${PKG_CONFIG_PATH:-}"

# Thêm các cờ cho trình biên dịch (compiler) và trình liên kết (linker) một cách tường minh
# Điều này giúp các script build "cứng đầu" nhất cũng có thể tìm thấy dependencies
export CFLAGS="-I$PREFIX/include"
export CPPFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib -L$MULTIARCH_LIB_DIR -Wl,-rpath,$PREFIX/lib -Wl,-rpath,$MULTIARCH_LIB_DIR"


# --- Biên dịch và cài đặt với Meson ---
echo "--- ⚙️  Bắt đầu quá trình build GTK4 ---"

meson setup _build --prefix="$PREFIX" \
    -Dintrospection=enabled \
    -Ddocumentation=false \
    -Dbuildtype=release

meson compile -C _build -j"$(nproc)"
meson install -C _build

# --- Lưu các biến môi trường vào ~/.bashrc (giữ nguyên logic của bạn) ---
# Persist env vars
for VAR in PKG_CONFIG_PATH LD_LIBRARY_PATH PATH; do
    if ! grep -q "export $VAR=\$HOME/.local" ~/.bashrc; then
        echo "export $VAR=\$HOME/.local/${VAR,,}:\$$VAR" >> ~/.bashrc
    fi
done

echo ""
echo "✅ GTK4 $GTK4_VER đã được cài đặt vào $PREFIX"
