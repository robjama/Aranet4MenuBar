#!/bin/bash

set -e

echo "Building Aranet4MenuBar..."

# Set build directory
BUILD_DIR="build"
APP_NAME="Aranet4"
BUNDLE_ID="com.aranet.menubar"

# Clean build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Create app bundle structure
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Compile Swift files
echo "Compiling Swift files..."
swiftc \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    -sdk $(xcrun --show-sdk-path --sdk macosx) \
    -target arm64-apple-macos11.0 \
    -framework AppKit \
    -framework SwiftUI \
    -framework CoreBluetooth \
    -framework Combine \
    Aranet4Data.swift \
    BluetoothManager.swift \
    StatusItemController.swift \
    MenuBarView.swift \
    AppDelegate.swift \
    main.swift

echo "Creating app bundle..."

# Copy Info.plist
cp Info.plist "$APP_BUNDLE/Contents/"

# Create PkgInfo
echo "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Sign the app (optional, for development)
if command -v codesign &> /dev/null; then
    echo "Signing app..."
    codesign --force --deep --sign - --entitlements Aranet4MenuBar.entitlements "$APP_BUNDLE"
fi

echo "Build complete! App bundle: $APP_BUNDLE"
echo "To run the app: open $APP_BUNDLE"
