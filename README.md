# ⚡ Antigravity Quota Monitor

[![Powered by VH2C](https://img.shields.io/badge/Developed%20by-vh2c.com.br-blue.svg?style=flat-square)](https://vh2c.com.br)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Windows%20%7C%20Linux-lightgrey.svg?style=flat-square)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg?style=flat-square)](#)
[![Python](https://img.shields.io/badge/Python-3.8+-3776AB.svg?style=flat-square&logo=python&logoColor=white)](#)
[![PowerShell](https://img.shields.io/badge/PowerShell-WPF-5391FE.svg?style=flat-square)](#)

An elegant, native AI usage quota monitor for **Antigravity**. Displays real-time remaining percentages for weekly and 5-hour rolling limits across **Gemini Models**, **Claude & GPT**, and **Gemini 4 Argon**, featuring live countdown timers and two distinct viewing modes.

Developed with pride by [VH2C](https://vh2c.com.br).

---

## 📥 Downloads (Releases)

Pre-built binaries ready for use without compiling:

👉 **[Go to the Latest Releases Page](../../releases/latest)**

* 🍏 **macOS (Apple Silicon & Intel)**: Download `Antigravity-Quota-macOS-vh2c.zip`
* 🪟 **Windows (10 & 11)**: Download `Antigravity-Quota-Windows-vh2c.zip`
* 🐧 **Linux (Ubuntu, Debian, Fedora, Arch, etc.)**: Download `Antigravity-Quota-Linux-vh2c.tar.gz`

---

## ✨ Features

- ⚡ **Real-Time Local Data**: Connects directly to the running local Antigravity Language Server process via IPC/RPC. No manual API keys required.
- 🎛️ **Dual Viewing Modes**:
  - **Full Detailed Window**: Traditional clean card layout with full descriptions, progress bars, and countdown timers.
  - **Compact Radial HUD**: Sleek floating widget with tachometer-style radial gauges, arched labels, and status badges.
- 📐 **Vertical & Horizontal Layouts**: The HUD can run as a discreet lateral strip (sidebar) or as a horizontal bar (docked top or bottom).
- 🕒 **Rolling Reset Countdown**: Live countdown for each quota bucket (e.g., `3h 28m`, `2d 3h`).
- 🔄 **Non-Intrusive Background Auto-Refresh**: Periodically updates every 30 seconds silently in the background without stealing keyboard focus or interrupting typing.
- 🎨 **Official Antigravity Aesthetics**:
  - 100% solid `#181818` dark background.
  - `#1F1F1F` cards and fields.
  - High-contrast buttons (`#EEEEF0`) with strictly monochrome iconography.
  - High-contrast status badges (rich green, amber, crimson) tuned for optimal legibility.
- 🚀 **100% Local & Private**: Zero external telemetry; all communication remains strictly on `localhost`.

---

## 🕹️ Two Display Modes

| Mode | Description | Best For |
| :--- | :--- | :--- |
| **Full Detailed Window** | Full window with category cards, detailed model list, horizontal progress bars, and account metadata. | Detailed review and complete overview. |
| **Compact Radial HUD** | Floating tachometer-style radial gauges with outer tick rings and centered percentage badges. | Keeping open alongside your editor on the screen edge (left, right, top, or bottom). |

### Keyboard Shortcuts & Quick Actions

| Shortcut / Action | Function |
| :--- | :--- |
| `Cmd + M` | Toggle between **Full Window** and **Compact HUD** |
| `Cmd + O` | Toggle HUD orientation between **Vertical** and **Horizontal** |
| `Cmd + R` | Refresh quota data immediately |
| `Esc` | Close the application |
| **Double-Click on HUD** | Expand any gauge into the Full Detailed Window |
| **Right-Click on HUD** | Open the context menu with all actions and controls |
| **Drag Background** | Move the HUD anywhere on your screen |

---

## 🖥️ Installation & Usage

### 🍏 macOS

#### Option 1: Pre-built App (Recommended)
1. Download `Antigravity-Quota-macOS-vh2c.zip` from [Releases](../../releases/latest).
2. Unzip and move **Antigravity Quota.app** to your `/Applications` folder.
3. Launch via Spotlight (`Cmd + Space` -> *Antigravity Quota*) or pin to your Dock.

#### Option 2: Build from Source
```bash
git clone https://github.com/vh2c/antigravity-quota-monitor.git
cd antigravity-quota-monitor/macos
./install.sh
```

---

### 🪟 Windows

#### Option 1: Pre-packaged (Recommended)
1. Download `Antigravity-Quota-Windows-vh2c.zip` from [Releases](../../releases/latest).
2. Extract to any directory (e.g., `C:\Users\<user>\AppData\Local\AntigravityQuota`).
3. Right-click `install.ps1` and select **Run with PowerShell** (or double-click `AntigravityQuota.vbs`).
4. An **Antigravity Quota** shortcut will be automatically created in your Start Menu.

---

### 🐧 Linux (Ubuntu, Debian, Fedora, Arch, etc.)

#### Option 1: Tarball Download (Recommended)
1. Download `Antigravity-Quota-Linux-vh2c.tar.gz` from [Releases](../../releases/latest).
2. Extract and run the installer:
```bash
tar -xzvf Antigravity-Quota-Linux-vh2c.tar.gz
cd linux
./install.sh
```
3. Run `antigravity-quota` from terminal, or launch **Antigravity Quota** directly from your desktop Application Menu!

#### Option 2: CLI Terminal Mode (Headless / SSH)
If you are on a remote server or prefer terminal output:
```bash
antigravity-quota --cli
```

---

## 🚀 CI/CD & Automated GitHub Releases

This repository includes a ready-to-run GitHub Actions workflow in `.github/workflows/release.yml`. When a tag is pushed, GitHub builds and attaches the macOS, Windows, and Linux release packages automatically:

```bash
# Push release tag to trigger automated build:
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

---

## 🏢 About VH2C

Developed and maintained by [VH2C Soluções Tecnológicas](https://vh2c.com.br).

Questions, feedback, or suggestions? Open an [Issue](../../issues) or submit a Pull Request!

## 📄 License

Distributed under the [MIT License](LICENSE). Copyright © 2026 [VH2C](https://vh2c.com.br).
