#!/bin/bash
# Script de compilação do Antigravity Quota para macOS
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Compilando binários nativos Swift (ARM64)..."
mkdir -p "$SCRIPT_DIR/bin"
swiftc -O "$SCRIPT_DIR/src/QuotaApp.swift" -o "$SCRIPT_DIR/bin/AntigravityQuota"
swiftc -O "$SCRIPT_DIR/src/QuotaWatcher.swift" -o "$SCRIPT_DIR/bin/AntigravityWatcher"

echo "Criando bundle Antigravity Quota.app..."
APP_BUNDLE="$SCRIPT_DIR/Antigravity Quota.app"
rm -rf "$APP_BUNDLE"

osacompile -o "$APP_BUNDLE" -e 'do shell script "pkill -x AntigravityQuota 2>/dev/null; sleep 0.1; \"'$SCRIPT_DIR'/bin/AntigravityQuota\" > /dev/null 2>&1 &"'

# Ícone branco oficial do Antigravity
ICON_SOURCE=""
if [ -f "$SCRIPT_DIR/icon.icns" ]; then
    ICON_SOURCE="$SCRIPT_DIR/icon.icns"
elif [ -f "/Applications/Antigravity.app/Contents/Resources/icon.icns" ]; then
    ICON_SOURCE="/Applications/Antigravity.app/Contents/Resources/icon.icns"
fi

if [ -n "$ICON_SOURCE" ]; then
    cp "$ICON_SOURCE" "$APP_BUNDLE/Contents/Resources/icon.icns"
    cp "$ICON_SOURCE" "$APP_BUNDLE/Contents/Resources/applet.icns"
fi

# Remove catálogo Assets.car do AppleScript para priorizar icon.icns
rm -f "$APP_BUNDLE/Contents/Resources/Assets.car"
/usr/libexec/PlistBuddy -c "Delete :CFBundleIconName" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :CFBundleIconFile icon.icns" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string icon.icns" "$APP_BUNDLE/Contents/Info.plist"

# Marca e Metadados vh2c.com.br
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier br.com.vh2c.antigravityquota" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string br.com.vh2c.antigravityquota" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :NSHumanReadableCopyright 'Copyright © 2026 VH2C (vh2c.com.br)'" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || /usr/libexec/PlistBuddy -c "Add :NSHumanReadableCopyright string 'Copyright © 2026 VH2C (vh2c.com.br)'" "$APP_BUNDLE/Contents/Info.plist"

touch "$APP_BUNDLE"
echo "✅ Build concluído com sucesso!"
