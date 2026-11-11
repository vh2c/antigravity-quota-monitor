#!/bin/bash
# Instalador do Antigravity Quota para macOS
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/build.sh"

echo "Instalando em /Applications..."
cp -R "$SCRIPT_DIR/Antigravity Quota.app" "/Applications/"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "/Applications/Antigravity Quota.app"

echo "Configurando inicialização automática via LaunchAgent..."
PLIST_PATH="$HOME/Library/LaunchAgents/com.antigravity.quotamonitor.plist"
mkdir -p "$HOME/Library/LaunchAgents"

cat << EOF > "$PLIST_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.antigravity.quotamonitor</string>
    <key>ProgramArguments</key>
    <array>
        <string>$SCRIPT_DIR/bin/AntigravityWatcher</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH"

echo "✅ Antigravity Quota instalado com sucesso!"
echo "O monitor automático está ativo e abrirá o popup sempre que o Antigravity iniciar."
