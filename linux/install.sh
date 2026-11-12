#!/usr/bin/env bash
set -e

echo "⚡ Installing Antigravity Quota Monitor for Linux..."

TARGET_DIR="${HOME}/.local/share/antigravity-quota"
BIN_DIR="${HOME}/.local/bin"
APP_DIR="${HOME}/.local/share/applications"
ICON_DIR="${HOME}/.local/share/icons/hicolor/256x256/apps"

mkdir -p "${TARGET_DIR}" "${BIN_DIR}" "${APP_DIR}" "${ICON_DIR}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Copy core engine and linux app
cp -r "${REPO_DIR}/core" "${TARGET_DIR}/"
cp "${SCRIPT_DIR}/antigravity-quota.py" "${TARGET_DIR}/"
cp "${SCRIPT_DIR}/antigravity-quota" "${TARGET_DIR}/"
chmod +x "${TARGET_DIR}/antigravity-quota" "${TARGET_DIR}/antigravity-quota.py"

# Create symlink in ~/.local/bin
ln -sf "${TARGET_DIR}/antigravity-quota" "${BIN_DIR}/antigravity-quota"

# Copy Icon if exists
if [ -f "${SCRIPT_DIR}/antigravity-quota.png" ]; then
    cp "${SCRIPT_DIR}/antigravity-quota.png" "${ICON_DIR}/"
fi

# Install Desktop Entry
sed -e "s|^Exec=.*|Exec=${BIN_DIR}/antigravity-quota|" \
    "${SCRIPT_DIR}/antigravity-quota.desktop" > "${APP_DIR}/antigravity-quota.desktop"
chmod +x "${APP_DIR}/antigravity-quota.desktop"

# Update desktop database if available
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${APP_DIR}" || true
fi

echo "✅ Installed successfully!"
echo "👉 You can run it via terminal: 'antigravity-quota' (or 'antigravity-quota --cli')"
echo "👉 Or find 'Antigravity Quota' directly in your application menu!"
