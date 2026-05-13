#!/bin/bash
# Build macOS .app bundle via PyInstaller, then package as .pkg
# Usage: ./build_mac.sh

set -e

APP_NAME="故事板生成器"
APP_NAME_EN="StoryboardGenerator"
BUNDLE_ID="com.runninghub.storyboard"
VERSION="1.0.0"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="$PROJECT_DIR/dist"
PKG_DIR="$PROJECT_DIR/pkg_build"

echo "=== Step 1: Build .app bundle with PyInstaller ==="

# Use venv Python to ensure all dependencies are bundled
VENV_PYTHON="$PROJECT_DIR/.venv/bin/python"
if [ -x "$VENV_PYTHON" ]; then
    PYINSTALLER="$PROJECT_DIR/.venv/bin/pyinstaller"
else
    PYINSTALLER="pyinstaller"
fi

"$PYINSTALLER" \
    --name "$APP_NAME" \
    --onefile \
    --console \
    --add-data "$PROJECT_DIR/index.html:frontend" \
    --add-data "$PROJECT_DIR/favicon.png:frontend" \
    --exclude-module tkinter \
    --exclude-module matplotlib \
    --exclude-module numpy \
    --exclude-module pandas \
    --exclude-module scipy \
    --icon "$PROJECT_DIR/favicon.png" \
    "$PROJECT_DIR/backend/app.py"

echo "=== Step 1.5: Fix Info.plist for macOS compatibility ==="

# With --console mode, PyInstaller does NOT create a .app bundle
# So we create one manually from the standalone executable
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable (renamed to avoid conflict with launcher)
cp "$DIST_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME.bin"

# Create a launcher that opens Terminal.app and runs the backend
cat > "$APP_BUNDLE/Contents/MacOS/$APP_NAME" << 'LAUNCHER'
#!/bin/bash
APP_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_BIN="$APP_DIR/故事板生成器.bin"
osascript -e "tell application \"Terminal\"
    activate
    do script \"'$APP_BIN'\"
end tell"
LAUNCHER
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy icon - use Pillow to generate .icns from PNG
python3 -c "
from PIL import Image
import os
src = '$PROJECT_DIR/favicon.png'
out = '$APP_BUNDLE/Contents/Resources/AppIcon.icns'
img = Image.open(src)
if img.mode != 'RGBA':
    img = img.convert('RGBA')
img.save(out, 'ICNS')
"
ICON_NAME="AppIcon"

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>$ICON_NAME</string>
    <key>CFBundleIconName</key>
    <string>$ICON_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "=== Step 1.6: Sign .app bundle ==="
codesign --force --deep --sign - "$APP_BUNDLE"

echo "=== Step 2: Prepare .pkg package ==="

rm -rf "$PKG_DIR"
mkdir -p "$PKG_DIR/root/Applications"
cp -R "$DIST_DIR/$APP_NAME.app" "$PKG_DIR/root/Applications/"

# Build component package
pkgbuild \
    --root "$PKG_DIR/root" \
    --identifier "$BUNDLE_ID" \
    --version "$VERSION" \
    --install-location "/" \
    "$PKG_DIR/$APP_NAME.pkg"

# Build product archive
cat > "$PKG_DIR/Distribution.xml" << XML
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
    <title>$APP_NAME</title>
    <options customize="never" require-scripts="false" hostArchitectures="x86_64,arm64"/>
    <domains enable_anywhere="false" enable_currentUserHome="false" enable_localSystem="true"/>
    <choices-outline>
        <line choice="default">
            <line choice="$BUNDLE_ID"/>
        </line>
    </choices-outline>
    <choice id="default"/>
    <choice id="$BUNDLE_ID" visible="false">
        <pkg-ref id="$BUNDLE_ID"/>
    </choice>
    <pkg-ref id="$BUNDLE_ID" version="$VERSION">$APP_NAME.pkg</pkg-ref>
</installer-gui-script>
XML

productbuild \
    --distribution "$PKG_DIR/Distribution.xml" \
    --package-path "$PKG_DIR" \
    "$DIST_DIR/${APP_NAME_EN}-${VERSION}.pkg"

echo "=== Step 3: Create DMG disk image ==="

DMG_NAME="${APP_NAME_EN}-${VERSION}.dmg"
DMG_DIR="/tmp/dmg_staging_$$"
rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"
cp -R "$DIST_DIR/$APP_NAME.app" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDZO \
    "$DIST_DIR/$DMG_NAME"

rm -rf "$DMG_DIR"

echo ""
echo "=== Build complete ==="
echo "  .app:  $DIST_DIR/$APP_NAME.app"
echo "  .dmg:  $DIST_DIR/$DMG_NAME"
echo "  .pkg:  $DIST_DIR/${APP_NAME_EN}-${VERSION}.pkg (may not work on Sequoia+)"
echo ""
echo "  Recommended: distribute .dmg, users open it and drag app to Applications"
echo ""

# Cleanup
rm -rf "$PKG_DIR"
