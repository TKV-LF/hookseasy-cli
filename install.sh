#!/bin/bash

# Define the platform and architecture
ARCH=$(uname -m)
OS=$(uname)

# Determine binary URL based on platform and architecture
BINARY_URL=""
if [[ "$OS" == "Darwin" && "$ARCH" == "x86_64" ]]; then
    BINARY_URL="https://github.com/TKV-LF/tunnel-client-binaries/releases/download/latest/tunnel-darwin-amd64"
elif [[ "$OS" == "Darwin" && "$ARCH" == "arm64" ]]; then
    BINARY_URL="https://github.com/TKV-LF/tunnel-client-binaries/releases/download/latest/tunnel-darwin-arm64"
elif [[ "$OS" == "Linux" && "$ARCH" == "x86_64" ]]; then
    BINARY_URL="https://github.com/TKV-LF/tunnel-client-binaries/releases/download/latest/tunnel-linux-amd64"
elif [[ "$OS" == "Linux" && "$ARCH" == "aarch64" ]]; then
    BINARY_URL="https://github.com/TKV-LF/tunnel-client-binaries/releases/download/latest/tunnel-linux-arm64"
elif [[ "$OS" == "MINGW64_NT" && "$ARCH" == "x86_64" ]]; then
    BINARY_URL="https://github.com/TKV-LF/tunnel-client-binaries/releases/download/latest/tunnel-windows-amd64.exe"
elif [[ "$OS" == "MINGW64_NT" && "$ARCH" == "aarch64" ]]; then
    BINARY_URL="https://github.com/TKV-LF/tunnel-client-binaries/releases/download/latest/tunnel-windows-arm64.exe"
else
    echo "Unsupported platform: $OS $ARCH"
    exit 1
fi

# Download the binary
echo "Downloading tunnel client for $OS $ARCH..."
curl -L $BINARY_URL -o tunnel-client

# Make the binary executable
chmod +x tunnel-client

# Check if the binary is executable
if [[ ! -x ./tunnel-client ]]; then
    echo "Failed to make the binary executable."
    exit 1
fi

# Run the binary with the provided arguments
echo "Running tunnel client..."

# Check if 'token' and 'target-host' arguments are passed
if [[ $# -lt 4 ]]; then
    echo "Usage: curl -sSL https://tkv-lf.github.io/tunnel-client-binaries/install.sh | bash -s -- --token <your_token> --r <target_host>"
    exit 1
fi

./tunnel-client "$@"
