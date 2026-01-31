#!/bin/bash
# uninstall.sh - Bootstrap script to run the Node.js uninstaller
# This runs the local TypeScript uninstaller

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Clear screen for clean output
clear

echo "QMD History Search Uninstaller"
echo ""

# Check if npx is available
if ! command -v npx &> /dev/null; then
    echo "Error: npx is required but not installed."
    echo ""
    echo "Please install Node.js first:"
    echo "  https://nodejs.org/"
    exit 1
fi

# Check if dependencies are installed
if [[ ! -d "${SCRIPT_DIR}/node_modules" ]]; then
    echo "Installing dependencies..."
    echo ""
    cd "$SCRIPT_DIR"
    npm install
    echo ""
fi

echo "Running uninstaller..."
echo ""

# Run the local TypeScript uninstaller
cd "$SCRIPT_DIR"
npx tsx uninstall.ts
