#!/bin/bash
# Script de compilação do Antigravity Quota para macOS
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Compilando binário nativo Swift (ARM64)..."
mkdir -p "$SCRIPT_DIR/bin"
swiftc -O "$SCRIPT_DIR/src/QuotaApp.swift" -o "$SCRIPT_DIR/bin/AntigravityQuota"

echo "Criando bundle Antigravity Quota.app..."
APP_BUNDLE="$SCRIPT_DIR/Antigravity Quota.app"
rm -rf "$APP_BUNDLE"

osacompile -o "$APP_BUNDLE" -e 'do shell script "pkill -x AntigravityQuota 2>/dev/null; sleep 0.1; \"'$SCRIPT_DIR'/bin/AntigravityQuota\" > /dev/null 2>&1 &"'

# Ícone
if [ -f "/Applications/Antigravity IDE.app/Contents/Resources/Antigravity IDE.icns" ]; then
    cp "/Applications/Antigravity IDE.app/Contents/Resources/Antigravity IDE.icns" "$APP_BUNDLE/Contents/Resources/applet.icns" 2>/dev/null || true
fi

touch "$APP_BUNDLE"
echo "✅ Build concluído com sucesso em: $APP_BUNDLE"
