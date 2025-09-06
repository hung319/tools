#!/usr/bin/env bash
set -e

PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
LIBEDIT_VERSION="20240517-3.1"
LIBEDIT_URL="https://thrysoee.dk/editline/libedit-$LIBEDIT_VERSION.tar.gz"

mkdir -p "$SRC_DIR" "$PREFIX/lib" "$PREFIX/include"
cd "$SRC_DIR"

# --- Tải libedit ---
if [ ! -f "libedit-$LIBEDIT_VERSION.tar.gz" ]; then
    echo "📥 Đang tải libedit..."
    wget "$LIBEDIT_URL"
else
    echo "☑️ Đã có file nén libedit."
fi

# --- Giải nén ---
tar -xzf "libedit-$LIBEDIT_VERSION.tar.gz"

# Tự động phát hiện thư mục
EDIT_DIR=$(tar -tzf "libedit-$LIBEDIT_VERSION.tar.gz" | head -1 | cut -f1 -d"/")
echo "➡️ Giải nén vào: $EDIT_DIR"

# --- Symlink headers từ ncursesw ---
echo "🔗 Đang xử lý symlink header..."
cd "$PREFIX/include"
if [ ! -e ncurses.h ] && [ -e ncursesw/ncurses.h ]; then
    ln -s ncursesw/ncurses.h ncurses.h
fi
for hdr in curses.h termcap.h term.h; do
    if [ ! -e $hdr ] && [ -e ncursesw/$hdr ]; then
        ln -s ncursesw/$hdr $hdr
    fi
done

# --- Symlink libtinfo ---
cd "$PREFIX/lib"
if [ ! -e "libtinfo.so" ] && [ -e libtinfow.so ]; then
    ln -s libtinfow.so libtinfo.so
fi

# --- Build & cài đặt ---
cd "$SRC_DIR/$EDIT_DIR"
echo "⚙️ Đang configure..."
export CPPFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib"

./configure --prefix="$PREFIX"

echo "🚀 Đang build..."
make -j"$(nproc)"
make install

echo "✅ libedit $LIBEDIT_VERSION đã được cài vào $PREFIX"
