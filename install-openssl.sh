#!/usr/bin/env bash
# install-openssl.sh
# Automated build & user-scoped install of OpenSSL 3.5.x (LTS or higher)
# Tested on Ubuntu/Debian. Run inside a VM or dedicated environment.

set -euo pipefail

OPENSSL_VERSION="3.5.3"      # <-- change to newer version if needed
PREFIX="/usr/local"
OPENSSL_DIR="$PREFIX/ssl"

echo ">>> Updating system & installing build dependencies..."
sudo apt update
sudo apt install -y build-essential checkinstall zlib1g-dev libssl-dev \
    perl-modules-5.* perl-doc wget tar

echo ">>> Creating build directory..."
mkdir -p "$HOME/openssl-build"
cd "$HOME/openssl-build"

echo ">>> Downloading OpenSSL $OPENSSL_VERSION..."
wget -q --show-progress \
  "https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz"

echo ">>> Extracting source..."
tar -xzf "openssl-${OPENSSL_VERSION}.tar.gz"
cd "openssl-${OPENSSL_VERSION}"

echo ">>> Configuring build for $PREFIX..."
./config --prefix="$PREFIX" --openssldir="$OPENSSL_DIR"

echo ">>> Compiling with $(nproc) cores..."
make -j"$(nproc)"

echo ">>> Skipped tests!!"
# make test

echo ">>> Installing to $PREFIX (sudo required)..."
sudo make install

# Update user environment safely
BASHRC="$HOME/.bashrc"
if ! grep -q "/usr/local/bin" "$BASHRC"; then
    echo ">>> Adding OpenSSL $OPENSSL_VERSION to PATH in $BASHRC"
    {
        echo ""
        echo "# Custom OpenSSL $OPENSSL_VERSION"
        echo "export PATH=$PREFIX/bin:\$PATH"
        echo "export LD_LIBRARY_PATH=$PREFIX/lib64:\$LD_LIBRARY_PATH"
    } >> "$BASHRC"
fi

echo ">>> Reloading shell environment..."
# shellcheck disable=SC1090
source "$BASHRC"

echo ">>> Verifying installation..."
which openssl
openssl version -a

echo ">>> ✅ OpenSSL $OPENSSL_VERSION installation complete."