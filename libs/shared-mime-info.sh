PREFIX=$HOME/.local
SRC_DIR=$HOME/src
VER=2.4

mkdir -p $SRC_DIR
cd $SRC_DIR

curl -LO https://gitlab.freedesktop.org/xdg/shared-mime-info/-/archive/$VER/shared-mime-info-$VER.tar.gz
tar -xf shared-mime-info-$VER.tar.gz
cd shared-mime-info-$VER

meson setup _build --prefix=$PREFIX --libdir=lib --buildtype=release
meson compile -C _build -j"$(nproc)"
meson install -C _build
