#!/bin/bash

# Exit on any error
set -e

# Base URL of the GitHub release
BASE_URL="https://github.com/TKV-LF/tunnel-client-binaries/releases"

# Detect OS and architecture
OS=$(uname | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# Map architecture to standard names
if [[ "$ARCH" == "x86_64" ]]; then
    ARCH="amd64"
elif [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
    ARCH="arm64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Map Darwin to macOS
if [[ "$OS" == "darwin" ]]; then
    OS="darwin"
elif [[ "$OS" == "linux" ]]; then
    OS="linux"
elif [[ "$OS" == "mingw"* || "$OS" == "cygwin"* ]]; then
    OS="windows"
else
    echo "Unsupported operating system: $OS"
    exit 1
fi

# Construct the file name for the release archive
ARCHIVE="tunnel-client-binaires-public.tar.gz"

# Download the archive
echo "Downloading the binary archive..."
curl -sSL "${BASE_URL}/${ARCHIVE}" -o "${ARCHIVE}"

# Extract the archive
echo "Extracting the archive..."
tar -xzf "${ARCHIVE}"

# Determine the binary name
BINARY="tunnel-${OS}-${ARCH}"
if [[ "$OS" == "windows" ]]; then
    BINARY="${BINARY}.exe"
fi

# Verify the binary exists
if [[ ! -f "$BINARY" ]]; then
    echo "Binary not found for your platform: ${BINARY}"
    exit 1
fi

# Move the binary to the current directory
mv "$BINARY" ./tunnel

# Clean up extracted files and archive
rm -rf tunnel-* "$ARCHIVE"

# Ensure token and target URL are provided
TOKEN=$1
TARGET_URL=$2
if [[ -z "$TOKEN" || -z "$TARGET_URL" ]]; then
    echo "Usage: curl -sSL <install.sh URL> | bash -s <token> <target_url>"
    exit 1
fi

# Ensure the binary is executable
chmod +x tunnel

# Run the binary
echo "Running the tunnel..."
./tunnel -token "$TOKEN" -t "$TARGET_URL"
