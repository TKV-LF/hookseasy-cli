#!/bin/bash

# Exit on any error
set -e

# Base URL of the GitHub release
BASE_URL="https://github.com/TKV-LF/tunnel-client-binaries/releases/latest"

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
ARCHIVE="source-code.tar.gz"

# Download the archive
echo "Downloading the binary archive..."
curl -sSL "${BASE_URL}/${ARCHIVE}" -o "${ARCHIVE}"

# Debugging: Check the downloaded file
echo "Downloaded file: ${ARCHIVE}"
ls -l "${ARCHIVE}"

# Check if the file exists and is non-empty
if [[ ! -s "${ARCHIVE}" ]]; then
    echo "Error: Archive file is empty or not found. Check your URL or release assets."
    exit 1
fi

# Attempt to extract the archive
echo "Extracting the archive..."
tar -xzf "${ARCHIVE}" || { echo "Failed to extract archive. Debugging its contents..."; file "${ARCHIVE}"; exit 1; }

# List extracted files for debugging
echo "Extracted files:"
ls -l
