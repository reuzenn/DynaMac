#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "=========================================="
echo "Building DynaMac (macOS Release Bundle)"
echo "=========================================="

# 1. Terminate running DynaMac instance if active
if pgrep -x "DynaMac" > /dev/null; then
    echo "Stopping existing DynaMac process..."
    pkill -x "DynaMac" || true
    sleep 0.5
fi

# 2. Build Release using Xcode project
echo "Compiling release target via xcodebuild..."
xcodebuild -project DynaMac.xcodeproj \
           -scheme DynaMac \
           -configuration Release \
           -quiet \
           build

# 3. Locate the built artifact from DerivedData
BUILD_DIR="$(xcodebuild -project DynaMac.xcodeproj -scheme DynaMac -configuration Release -showBuildSettings | grep " TARGET_BUILD_DIR =" | head -n 1 | awk -F' = ' '{print $2}')"
XCODE_APP="$BUILD_DIR/DynaMac.app"

if [ ! -d "$XCODE_APP" ]; then
    echo "Error: Built application not found at $XCODE_APP"
    exit 1
fi

echo "Packaging application bundle..."
APP_BUNDLE="$DIR/DynaMac.app"
rm -rf "$APP_BUNDLE"
cp -R "$XCODE_APP" "$APP_BUNDLE"

# 4. Ensure AppIcon and Info.plist are properly configured
if [ -f "$DIR/DynaMac/AppIcon.icns" ]; then
    mkdir -p "$APP_BUNDLE/Contents/Resources"
    cp "$DIR/DynaMac/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
    /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || true
fi

# 5. Codesign the bundle cleanly
echo "Signing application bundle..."
codesign --force --deep --sign - "$APP_BUNDLE"

# 6. Install to /Applications
echo "Installing DynaMac.app to /Applications..."
rm -rf "/Applications/DynaMac.app"
cp -R "$APP_BUNDLE" "/Applications/DynaMac.app"

# 7. Register with macOS LaunchServices and update system caches
echo "Registering with LaunchServices..."
touch "/Applications/DynaMac.app"
touch "$APP_BUNDLE"
/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f -R "/Applications/DynaMac.app" "$APP_BUNDLE" 2>/dev/null || true

echo "=========================================="
echo "Build and installation completed successfully."
echo "Workspace bundle: $APP_BUNDLE"
echo "Applications path: /Applications/DynaMac.app"
echo "=========================================="
