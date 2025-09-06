#!/usr/bin/env bash
set -e

PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
PERL_VERSION="5.40.0"
PERL_URL="https://www.cpan.org/src/5.0/perl-$PERL_VERSION.tar.gz"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# Tải source Perl
if [ ! -f "perl-$PERL_VERSION.tar.gz" ]; then
    wget "$PERL_URL"
fi

# Giải nén
if [ ! -d "perl-$PERL_VERSION" ]; then
    tar xf "perl-$PERL_VERSION.tar.gz"
fi

cd "perl-$PERL_VERSION"

# Configure để build shared libperl
./Configure -des -Dprefix="$PREFIX" -Duseshrplib

# Build
make -j"$(nproc)"

# Install
make install

echo "✅ Installed Perl + libperl.so into $PREFIX"

echo
echo "👉 Add this to your shell config (~/.bashrc or ~/.zshrc):"
echo "export PATH=\"$PREFIX/bin:\$PATH\""
echo "export LD_LIBRARY_PATH=\"$PREFIX/lib:\$LD_LIBRARY_PATH\""
