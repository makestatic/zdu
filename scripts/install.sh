#!/usr/bin/env bash
set -e

# Color codes
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m"

OWNER="makestatic"
REPO="zdu"

# Detect OS and ARCH
echo "${BLUE}Detecting OS and architecture...${NC}"
OS="$(uname | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "$ARCH" in
    x86_64) ARCH="x86_64" ;;
    aarch64|arm64) ARCH="aarch64" ;;
    *) printf "${RED}❌ Unsupported architecture: %s${NC}\n" "$ARCH"; exit 1 ;;
esac

case "$OS" in
    darwin) OS="macos" ;;
    mingw*|cygwin*|msys*) OS="windows" ;;
    freebsd) OS="freebsd" ;;
esac

printf "${GREEN}Detected OS: %s, ARCH: %s${NC}\n" "$OS" "$ARCH"

# Fetch latest release tag
echo "${BLUE}Fetching latest release tag from GitHub...${NC}"
TAG=$(curl -s "https://api.github.com/repos/$OWNER/$REPO/releases/latest" \
      | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

FILE_NAME="${REPO}-${ARCH}-${OS}.tar.gz"
DOWNLOAD_URL="https://github.com/$OWNER/$REPO/releases/download/$TAG/$FILE_NAME"

# Try downloading prebuilt binary
TMP_DIR=$(mktemp -d)
echo "${BLUE}Downloading $FILE_NAME...${NC}"

if curl --fail -sL "$DOWNLOAD_URL" -o "$TMP_DIR/$FILE_NAME"; then
    echo "${BLUE}Extracting...${NC}"
    tar -xzf "$TMP_DIR/$FILE_NAME" -C "$TMP_DIR"

    EXTRACTED_DIR="$TMP_DIR/${REPO}-${ARCH}-${OS}"
    BIN="$EXTRACTED_DIR/zdu"

    if [ "$OS" = "windows" ]; then
        BIN="$BIN.exe"
    fi

    echo "${BLUE}Installing $BIN to /usr/local/bin...${NC}"
    sudo cp "$BIN" /usr/local/bin/zdu
    sudo chmod +x /usr/local/bin/zdu

    echo "${GREEN}zdu installed successfully!${NC}"
else
    echo "${YELLOW}[!] No prebuilt binary for $OS-$ARCH. Attempting to build from source...${NC}"
    git clone "https://github.com/$OWNER/$REPO.git" "$TMP_DIR/$REPO"
    cd "$TMP_DIR/$REPO"

    if command -v zig >/dev/null 2>&1; then
        echo "${BLUE}Building zdu using Zig...${NC}"
		make
		sudo make install
        echo "${GREEN}zdu built and installed successfully!${NC}"
    else
        echo "${RED}[!] Zig compiler not found. Please install Zig to build from source.${NC}"
        exit 1
    fi
fi

# Cleanup
rm -rf "$TMP_DIR"
