# OpenSSL Installation Guide - Replace System Version

## Overview

This guide will help you safely replace your current OpenSSL installation with the latest stable version (OpenSSL 3.5.1 LTS or higher) in the default system location.

## Prerequisites Check

First, check your current OpenSSL version and system details:

```bash
# Check current OpenSSL version
openssl version -a

# Check system architecture
uname -a

# Check if you have the required tools
which gcc || which clang
which make
which perl
```

## Required Dependencies

Install the build dependencies:

**For Ubuntu/Debian:**

```bash
sudo apt update
sudo apt install -y build-essential checkinstall zlib1g-dev libssl-dev
sudo apt install -y perl-modules-5.* perl-doc
```

## Step 1: Backup Current Installation

> [!IMPORTANT]
> Always backup your current OpenSSL installation before proceeding:

```bash
# Create backup directory
sudo mkdir -p /opt/openssl-backup-$(date +%Y%m%d)

# Backup current OpenSSL binaries and libraries
sudo cp -r /usr/local/bin/openssl* /opt/openssl-backup-$(date +%Y%m%d)/ 2>/dev/null || true
sudo cp -r /usr/local/lib/libssl* /opt/openssl-backup-$(date +%Y%m%d)/ 2>/dev/null || true
sudo cp -r /usr/local/lib/libcrypto* /opt/openssl-backup-$(date +%Y%m%d)/ 2>/dev/null || true
sudo cp -r /usr/local/include/openssl /opt/openssl-backup-$(date +%Y%m%d)/ 2>/dev/null || true

# Also backup system locations
sudo cp -r /usr/bin/openssl* /opt/openssl-backup-$(date +%Y%m%d)/ 2>/dev/null || true
sudo cp -r /usr/lib/libssl* /opt/openssl-backup-$(date +%Y%m%d)/ 2>/dev/null || true
sudo cp -r /usr/lib/libcrypto* /opt/openssl-backup-$(date +%Y%m%d)/ 2>/dev/null || true

echo "Backup completed in /opt/openssl-backup-$(date +%Y%m%d)/"
```

## Step 2: Download and Verify OpenSSL 3.5.1

OpenSSL 3.5.1 can be downloaded from the official [GitHub releases page](https://github.com/openssl/openssl/releases/)

```bash
# Create working directory
mkdir -p ~/openssl-build && cd ~/openssl-build

# Download OpenSSL 3.5.0
wget https://github.com/openssl/openssl/releases/download/openssl-3.5.1/openssl-3.5.1.tar.gz
wget https://github.com/openssl/openssl/releases/download/openssl-3.5.1/openssl-3.5.1.tar.gz.sha256

# Verify the download
sha256sum -c openssl-3.5.1.tar.gz.sha256

# Extract the archive
tar -xzf openssl-3.5.1.tar.gz
cd openssl-3.5.1
```

## Step 3: Remove Old OpenSSL (Optional but Recommended)

> [!WARNING]  
> This step removes the existing OpenSSL. Only proceed if you have backups and understand the risks.

```bash
# Remove old OpenSSL installations (be very careful)
sudo rm -f /usr/local/bin/openssl
sudo rm -f /usr/local/lib/libssl.*
sudo rm -f /usr/local/lib/libcrypto.*
sudo rm -rf /usr/local/include/openssl
sudo rm -rf /usr/local/lib/engines*
sudo rm -rf /usr/local/share/man/man1/openssl*
sudo rm -rf /usr/local/share/man/man3/SSL*
sudo rm -rf /usr/local/share/man/man3/crypto*

# Update library cache
sudo ldconfig
```

## Step 4: Configure OpenSSL 3.5.1

Choose the appropriate configuration based on your system:

**For most Linux systems (recommended):**

```bash
./Configure --prefix=/usr/local --openssldir=/usr/local/ssl \
    --libdir=lib \
    shared \
    zlib-dynamic \
    "-Wl,-rpath,\$(LIBRPATH)"
```

**For systems requiring specific paths:**

```bash
# If you want to install to system default locations
./Configure --prefix=/usr --openssldir=/etc/ssl \
    --libdir=lib \
    shared \
    zlib-dynamic \
    "-Wl,-rpath,\$(LIBRPATH)"
```

## Step 5: Compile OpenSSL

```bash
# Build OpenSSL (this may take several minutes)
make -j$(nproc)

# Run tests (recommended but optional)
make test
```

## Step 6: Install OpenSSL

```bash
# Install OpenSSL (requires root privileges)
sudo make install

# Update library cache
sudo ldconfig

# Update PATH (add to your shell profile for permanent effect) - only if openssl configured to /usr/local in step 4
export PATH="/usr/local/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"
```

## Step 7: Update System Configuration

> [!NOTE]
> Run these commands (in Step 7) only if you have installed OpenSSL to `/usr/local`.

### Update shell profile for permanent PATH changes:

**For Bash users:**

```bash
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"' >> ~/.bashrc
echo 'export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"' >> ~/.bashrc
source ~/.bashrc
```

**For Zsh users:**

```bash
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
echo 'export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"' >> ~/.zshrc
echo 'export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Update system library configuration:

```bash
# Create library configuration file
echo "/usr/local/lib" | sudo tee /etc/ld.so.conf.d/openssl.conf
sudo ldconfig
```

## Step 8: Verify Installation

> [!NOTE]
> The below commands won't work if you have installed OpenSSL other than to `/usr/local`.

```bash
# Check new OpenSSL version
/usr/local/bin/openssl version -a

# Verify library linking
ldd /usr/local/bin/openssl

# Test basic functionality
echo "Testing OpenSSL..." | /usr/local/bin/openssl dgst -sha256
```

**Check which OpenSSL is being used by default:**

```bash
which openssl
openssl version -a
```

## Step 9: Configure FIPS Provider (If Needed)

If you need FIPS compliance:

```bash
# Install FIPS configuration
sudo /usr/local/bin/openssl fipsinstall -out /usr/local/ssl/fipsmodule.cnf -module /usr/local/lib/ossl-modules/fips.so
```

## Troubleshooting

### If applications can't find the new OpenSSL:

1. **Update library cache:**

   ```bash
   sudo ldconfig
   ```

2. **Create symbolic links (if needed):**

   ```bash
   sudo ln -sf /usr/local/lib/libssl.so.3 /usr/lib/libssl.so.3
   sudo ln -sf /usr/local/lib/libcrypto.so.3 /usr/lib/libcrypto.so.3
   ```

3. **Set environment variables:**
   ```bash
   export OPENSSL_ROOT_DIR=/usr/local
   export OPENSSL_INCLUDE_DIR=/usr/local/include
   export OPENSSL_LIBRARIES=/usr/local/lib
   ```

### If build fails:

1. **Check dependencies:**

   ```bash
   # Install missing dependencies
   sudo apt install build-essential perl zlib1g-dev  # Ubuntu/Debian
   ```

2. **Clean and reconfigure:**
   ```bash
   make clean
   ./Configure [your-options-here]
   make -j$(nproc)
   ```

### Rolling Back (If Something Goes Wrong):

```bash
# Restore from backup
sudo cp -r /opt/openssl-backup-$(date +%Y%m%d)/* /usr/local/
sudo ldconfig
```

> [!IMPORTANT]
> This process replaces system OpenSSL, which can affect other applications. Always test in a development environment first!
