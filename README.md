# CoreDeck for macOS (Native Apple Silicon)

> **The Ultimate Power-User HUD for Apple Silicon & Cloud Fleet.**  
> Built with pure native Swift 6 and SwiftUI. Zero external dependencies. 768 KB footprint.

---

## ⚡ Features

### 1. Dynamic Menu Bar HUD
* **Dynamic Reactor Indicator:**
  * `🟢` Optimal state (RAM < 75%, Swap < 0.5 GB)
  * `⚡` Elevated memory pressure
  * `🔥` Critical Swap thrashing / Memory overload (>88%)
  * `🟢 VPS` / `🔴 VPS`: Live heartbeat of your configured remote server infrastructure.
* **Toggleable Modes:** Switch between Detailed View (`🟢 11.2/16G | 💾 35G | 🔄 0.2G | 🟢 VPS`) and Compact Minimalist View.

### 2. Rich Popover Dashboard (SwiftUI Window)
* **Unified Memory (RAM) Gauge:** Live animated gradient progress bar showing Wired, Active, and Compressed pages via Darwin Mach kernel calls (`host_statistics64`).
* **Swap Memory Card:** Instantly highlights when macOS begins swapping unified memory to the SSD.
* **Disk Space Monitor:** Real-time APFS volume available capacity.

### 3. Top Memory Consumers (Hogs) with Instant Kill
* Real-time extraction of top 5 memory-hungry processes.
* Smart recognition of AI models (Ollama, PyTorch), browsers (Arc, Chrome, Safari), and dev tools (Docker, Xcode, agy).
* Direct **TERM** (graceful) and **KILL** (forced `SIGKILL`) buttons per process.

### 4. Emergency Action Controls
* **Flush Cache:** Runs filesystem and page cache sync (`Darwin.sync()`).
* **Eject AI VRAM:** Connects to local Ollama API (`localhost:11434`) and unloads all models currently occupying unified VRAM (`keep_alive: 0`).

### 5. Fleet Telemetry & Multi-Server Manager (Dual Mode)
* **Mode 1: Direct SSH Connection (Zero-Setup for Fresh Servers):**
  * Connects directly using standard SSH credentials from Hostinger / Hetzner / AWS / DigitalOcean (Host/IP, Port, User, Password or SSH Key).
  * Zero software to install on the remote machine – extracts native Linux telemetry (`/proc`) via OpenSSH.
* **Mode 2: HTTP Agent (1-Liner Script):**
  * One-command automated installer (`tools/install_agent.sh`) deploying a lightweight systemd micro-daemon on port 9123.
  * Token-based authentication (`X-API-Key` / `Bearer`).
* Multi-server profile management and live switcher directly from the HUD.
* Built-in connection test diagnostic tool.

---

## 📥 Download & Installation

### Option 1: Direct DMG (Recommended)
Download the signed installer DMG directly from the official website:
**[https://armako.co.uk/coredeck/](https://armako.co.uk/coredeck/)**

Direct download link:
* **[CoreDeck-Installer.dmg](https://armako.co.uk/coredeck/CoreDeck-Installer.dmg)** (2.9 MB, Apple Silicon Native)
* SHA256: `46805869904fc60a3c633d152b3ec3bc6d509dbe7a680d685697268970728f0d`

### Option 2: Homebrew
```bash
brew install --cask coredeck
```
Or via custom tap:
```bash
brew install --cask Arielkap/tap/coredeck
```

---

## 🛠️ Build & Package

To re-compile and package into a standalone `.app` bundle:
```bash
./package.sh
```

This compiles a release binary with full optimizations and produces `CoreDeck.app` and `CoreDeck-Installer.dmg`.
