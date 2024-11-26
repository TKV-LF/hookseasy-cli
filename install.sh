#!/bin/bash

# Variables for your GitHub repository
REPO="TKV-LF/tunnel-client-binaries"
BINARY_NAME="tunnel"

# Function to determine the OS and Architecture
detect_platform() {
  local unameOut="$(uname -s)"
  local arch="$(uname -m)"
  
  case "${unameOut}" in
    Linux*)     os="linux";;
    Darwin*)    os="darwin";;
    CYGWIN*|MINGW*|MSYS*|Windows_NT*) os="windows";;
    *)          os="unknown";;
  esac

  case "${arch}" in
    x86_64)     arch="amd64";;
    arm64|aarch64) arch="arm64";;
    *)          arch="unknown";;
  esac

  if [[ "$os" == "unknown" || "$arch" == "unknown" ]]; then
    echo "Unsupported platform: $unameOut / $arch"
    exit 1
  fi

  echo "${os}-${arch}"
}

# Parse arguments
TOKEN=""
FORWARD_PORT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --token)
      TOKEN="$2"
      shift 2
      ;;
    --forward-port)
      FORWARD_PORT="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [[ -z "$TOKEN" || -z "$FORWARD_PORT" ]]; then
  echo "Usage: $0 --token <TOKEN> --forward-port <PORT>"
  exit 1
fi

# Detect platform and architecture
PLATFORM=$(detect_platform)
FILENAME="${BINARY_NAME}-${PLATFORM}"

if [[ "$PLATFORM" == *"windows"* ]]; then
  FILENAME="${FILENAME}.exe"
fi

# Download the binary
echo "Downloading the binary for ${PLATFORM}..."
DOWNLOAD_URL="https://github.com/${REPO}/releases/latest/download/${FILENAME}"
curl -L -o "${BINARY_NAME}" "${DOWNLOAD_URL}"

if [[ $? -ne 0 ]]; then
  echo "Failed to download the binary from ${DOWNLOAD_URL}"
  exit 1
fi

# Make the binary executable
chmod +x "${BINARY_NAME}"

# Run the binary with the provided arguments
echo "Running the binary with --token and --forward-port..."
./${BINARY_NAME} --token="${TOKEN}" --forward-port="${FORWARD_PORT}"
