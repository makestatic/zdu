#!/usr/bin/env bash
set -e

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m"

OWNER="makestatic"
REPO="zdu"

echo -e "${BLUE}Detecting OS and architecture...${NC}"

OS="$(uname | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "$ARCH" in
    x86_64) ARCH="x86_64" ;;
    aarch64|arm64) ARCH="aarch64" ;;
    *) echo -e "${RED}❌ Unsupported architecture: $ARCH${NC}"; exit 1 ;;
esac

case "$OS" in
    darwin) OS="macos" ;;
    mingw*|cygwin*|msys*) OS="windows" ;;
esac

echo -e "${GREEN}Detected OS: $OS, ARCH: $ARCH${NC}"

echo -e "${BLUE}Fetching latest release tag from GitHub...${NC}"
TAG=$(curl -s "https://api.github.com/repos/$OWNER/$REPO/releases/latest" | \
      grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

FILE_NAME="${REPO}-${ARCH}-${OS}.tar.gz"
DOWNLOAD_URL="https://github.com/$OWNER/$REPO/releases/download/$TAG/$FILE_NAME"

echo -e "${BLUE}Downloading $FILE_NAME...${NC}"
TMP_DIR=$(mktemp -d)
curl -sL "$DOWNLOAD_URL" -o "$TMP_DIR/$FILE_NAME"

echo -e "${BLUE}Extracting...${NC}"
tar -xzf "$TMP_DIR/$FILE_NAME" -C "$TMP_DIR"

EXTRACTED_DIR="$TMP_DIR/${REPO}-${ARCH}-${OS}"
BIN="$EXTRACTED_DIR/zdu"
if [ "$OS" = "windows" ]; then
    BIN="$BIN.exe"
fi

echo -e "${BLUE}Installing $BIN to /usr/local/bin...${NC}"
sudo cp "$BIN" /usr/local/bin/zdu
sudo chmod +x /usr/local/bin/zdu

echo -e "${GREEN}zdu installed successfully!${NC}"

rm -rf "$TMP_DIR"
