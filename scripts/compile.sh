#!/bin/bash
# fluttercraft CLI - Compile Script (Bash)
# Compiles Dart CLI to native executable for Linux/macOS

set -e

TARGET="${1:-$(uname -s | tr '[:upper:]' '[:lower:]')}"
EXE_NAME="fluttercraft"

# Determine extension based on platform
case "$TARGET" in
    linux|darwin|macos)
        EXE_EXT=""
        ;;
    windows)
        EXE_EXT=".exe"
        ;;
    *)
        echo "Unknown target: $TARGET"
        echo "Usage: $0 [linux|macos|windows]"
        exit 1
        ;;
esac

# Define output path
OUTPUT_PATH="bin/$EXE_NAME$EXE_EXT"

echo ""
echo "========================================"
echo "  fluttercraft - Compiler"
echo "========================================"
echo ""
echo "Target:    $TARGET"
echo "Output:    $OUTPUT_PATH"
echo ""

# Create output directory
mkdir -p "bin"

# Check for fvm or dart
if command -v fvm &> /dev/null; then
    DART_CMD="fvm dart"
    echo "Using FVM Dart"
else
    DART_CMD="dart"
    echo "Using system Dart"
fi

# Compile
echo ""
echo "Compiling..."
$DART_CMD compile exe bin/fluttercraft.dart -o "$OUTPUT_PATH"

echo ""
echo "SUCCESS!"
echo "Executable: $OUTPUT_PATH"

# Show file size
if [[ "$OSTYPE" == "darwin"* ]]; then
    SIZE=$(stat -f%z "$OUTPUT_PATH" | awk '{printf "%.2f MB", $1/1048576}')
else
    SIZE=$(stat --printf="%s" "$OUTPUT_PATH" | awk '{printf "%.2f MB", $1/1048576}')
fi

echo "Size: $SIZE"
echo ""

# Test
echo "Testing executable..."
"$OUTPUT_PATH" --version

echo ""
echo "Done! You can now run:"
echo "  $OUTPUT_PATH"
echo "  $OUTPUT_PATH --help"



