#!/bin/bash

# Configuration
OWNER="vngcloud"
REPO="gnab-releases"
BINARY_NAME="gnab"
INSTALL_PATH="/usr/local/bin"

# 1. Detect OS and Architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    arm64|aarch64) ARCH="arm64" ;;
    *) echo "❌ Error: Unsupported architecture: $ARCH"; exit 1 ;;
esac

# 2. Get latest version tag from GitHub Public API
echo "🔍 Checking for the latest version of $BINARY_NAME..."
LATEST_TAG=$(curl -s "https://api.github.com/repos/$OWNER/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_TAG" ]; then
    echo "❌ Error: Could not find the latest release."
    exit 1
fi

# 3. Construct Download URL (Matching your GoReleaser template)
# Example: gnab_0.0.1_darwin_arm64.tar.gz
FILENAME="${BINARY_NAME}_${LATEST_TAG#v}_${OS}_${ARCH}.tar.gz"
DOWNLOAD_URL="https://github.com/vngcloud/$REPO/releases/download/$LATEST_TAG/$FILENAME"

echo "📥 Downloading $FILENAME ($LATEST_TAG)..."

# 4. Create a temporary directory for extraction
TEMP_DIR=$(mktemp -d)
curl -Ls "$DOWNLOAD_URL" -o "$TEMP_DIR/package.tar.gz"

if [ $? -ne 0 ]; then
    echo "❌ Error: Download failed. Please check if version $LATEST_TAG exists for ${OS}/${ARCH}."
    exit 1
fi

# 5. Extract and Install
tar -xzf "$TEMP_DIR/package.tar.gz" -C "$TEMP_DIR"

echo "🚀 Installing to $INSTALL_PATH..."
if [ -w "$INSTALL_PATH" ]; then
    mv "$TEMP_DIR/$BINARY_NAME" "$INSTALL_PATH/"
else
    echo "🔑 Requesting sudo permission to move binary to $INSTALL_PATH"
    sudo mv "$TEMP_DIR/$BINARY_NAME" "$INSTALL_PATH/"
fi

# 6. Cleanup
rm -rf "$TEMP_DIR"

# 7. Final Check
echo "✨ Successfully installed $BINARY_NAME!"
$BINARY_NAME version
