#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "🔨 Kompilacja wersji produkcyjnej (Release)..."
swift build -c release

APP_NAME="CoreDeck.app"
APP_DIR="$DIR/$APP_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📦 Tworzenie struktury paczki macOS $APP_NAME..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Kopiowanie binarki (763 KB)
cp .build/release/CoreDeck "$MACOS_DIR/CoreDeck"
chmod +x "$MACOS_DIR/CoreDeck"

# Kopiowanie ikony aplikacji
if [ -f "$DIR/AppIcon.icns" ]; then
    echo "🎨 Instalacja AppIcon.icns..."
    cp "$DIR/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

# Tworzenie Info.plist
cat << 'EOF' > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>CoreDeck</string>
    <key>CFBundleIdentifier</key>
    <string>com.arielkap.CoreDeck</string>
    <key>CFBundleName</key>
    <string>CoreDeck</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.1.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

SIGN_ID=$(security find-identity -v -p codesigning | grep -o '"Developer ID Application: [^"]*"' | head -n 1 || true)
if [ -z "$SIGN_ID" ]; then
    SIGN_ID=$(security find-identity -v -p codesigning | grep -o '"Apple Development: [^"]*"' | head -n 1 || true)
fi

if [ -n "$SIGN_ID" ]; then
    echo "✍️ Podpisywanie oficjalnym certyfikatem Apple ($SIGN_ID)..."
    eval codesign --force --deep --sign $SIGN_ID \"$APP_DIR\"
else
    echo "✍️ Podpisywanie ad-hoc..."
    codesign --force --deep --sign - "$APP_DIR"
fi

echo "✅ Sukces! Aplikacja $APP_NAME jest gotowa w $APP_DIR"

# Tworzenie profesjonalnego instalatora DMG
echo "💿 Tworzenie instalatora .DMG..."
DMG_NAME="CoreDeck-Installer.dmg"
DMG_ROOT="/tmp/coredeck_dmg_staging"
hdiutil detach /Volumes/CoreDeck -force 2>/dev/null || true
rm -rf "$DMG_ROOT" "$DIR/$DMG_NAME"
mkdir -p "$DMG_ROOT"

cp -R "$APP_DIR" "$DMG_ROOT/"
ln -s /Applications "$DMG_ROOT/Applications"

hdiutil create -volname "CoreDeck" -srcfolder "$DMG_ROOT" -ov -format UDZO "$DIR/$DMG_NAME" >/dev/null
rm -rf "$DMG_ROOT"

echo "🎉 Gotowy instalator DMG: $DIR/$DMG_NAME"
ls -lh "$DIR/$DMG_NAME"
