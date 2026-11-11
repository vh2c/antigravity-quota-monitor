#!/bin/bash
# Instalador do Antigravity Quota para macOS
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/build.sh"

echo "Instalando em /Applications..."
cp -R "$SCRIPT_DIR/Antigravity Quota.app" "/Applications/"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "/Applications/Antigravity Quota.app"

echo "✅ Antigravity Quota instalado com sucesso em /Applications!"
echo "Você pode abri-lo pelo Spotlight ou no Finder > Aplicativos."
