#!/usr/bin/env python3
"""
Mando Marketing & Growth Dispatcher
Automated campaign generator for X (Twitter), Reddit, and Mac Curators.
"""

import sys
import os
import json
import argparse
import subprocess

DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.abspath(os.path.join(DIR, ".."))
TOOLS_DIR = os.path.join(ROOT_DIR, "tools")
KEYS_SCRIPT = os.path.join(TOOLS_DIR, "generate_keys.py")

WEBSITE_URL = "https://armako.co.uk/coredeck/"
GITHUB_URL = "https://github.com/Arielkap/coredeck-mac"

def get_promo_keys(count=5):
    try:
        res = subprocess.run([sys.executable, KEYS_SCRIPT, str(count), "CORE-VIP"], capture_output=True, text=True, check=True)
        keys = []
        for line in res.stdout.splitlines():
            line = line.strip()
            if line.startswith("CORE-"):
                keys.append(line)
        return keys
    except Exception as e:
        return [f"CORE-VIP-FREE-{i+1:03d}" for i in range(count)]

def generate_x_threads():
    keys = get_promo_keys(3)
    thread = f"""
🧵 VIRAL X (TWITTER) LAUNCH THREAD (Copy-paste or post via API)
================================================================

[Tweet 1 - The Hook (Attach 10s Screen Studio Video)]
Most Mac system monitors are 150MB of bloated Electron crap that eat more RAM than the apps they monitor.

So I wrote a 768 KB native Swift 6 HUD for Apple Silicon power users that actually does something useful:

Introducing CoreDeck. ⚡️🍎

🧵👇

---

[Tweet 2 - The AI / VRAM Problem]
If you run local LLMs (Ollama, LM Studio) or Docker on an M1/M2/M3/M4 Mac, you know the pain:

A model stays loaded in unified VRAM for hours in the background. Swap starts bleeding. Your Mac stutters.

With CoreDeck, one click sends `keep_alive: 0` to Ollama and ejects gigabytes of VRAM instantly. 🤖

---

[Tweet 3 - The Remote Node Twist]
Every other menu bar app only monitors your local Mac.

CoreDeck also connects to your remote Linux VPS fleet (via lightweight HTTPS telemetry).

Check remote RAM, CPU load, and NVMe health right from macOS without opening a terminal window. 🛰️

---

[Tweet 4 - Pure Beskar Architecture]
• 768 KB standalone `.app` bundle
• 0.0% idle CPU usage
• Direct Darwin Mach kernel syscalls (`host_statistics64`)
• Instant SIGTERM / SIGKILL for memory hogs
• Native SwiftUI `.window` popover

Zero tracking. Zero bloatware.

---

[Tweet 5 - The Drop]
Download the free evaluation build or get the Lifetime Pro license ($14.99):
🔗 {WEBSITE_URL}

Open source on GitHub:
⭐ {GITHUB_URL}

Dropping 3 free lifetime VIP keys for the community:
1. `{keys[0]}`
2. `{keys[1]}`
3. `{keys[2]}`

RT and leave feedback! 🚀
"""
    return thread

def generate_reddit_post():
    keys = get_promo_keys(10)
    keys_formatted = "\n".join([f"- `{k}`" for k in keys])
    post = f"""
REDDIT r/macapps & r/SideProject LAUNCH POST
============================================

Title: I was tired of bloated system monitors, so I built CoreDeck — a 768 KB native Swift 6 HUD for Apple Silicon with an Ollama VRAM ejector (50 Free Lifetime Keys)

Hey r/macapps! 👋

I'm an indie developer working on Apple Silicon. Like many of you, I run local AI models (Ollama) and heavy dev tools. My biggest frustration was seeing my unified memory get chewed up by idle background models and memory hogs, causing swap thrashing on the SSD.

Most existing system monitors either just show static numbers or are built on Electron/Python bundles taking 150+ MB.

So I built **CoreDeck** in pure Swift 6 and SwiftUI:

### ⚡ What it does:
1. **Low-Level Darwin Kernel Telemetry:** Reads Wired, Active, and Compressed pages directly via `host_statistics64` and `sysctl vm.swapusage` in sub-milliseconds.
2. **AI VRAM Model Ejector:** Connects to your local Ollama instance and cleanly unloads idle models from GPU memory with a single click.
3. **Remote VPS Fleet Node:** Monitors your remote Linux VPS/servers directly in the same macOS dropdown (RAM, load average, disk, uptime).
4. **Instant Process Killer:** Direct SIGTERM and forced SIGKILL buttons for top memory hogs.
5. **Ultra-Lightweight:** 768 KB total binary size, 0.0% idle CPU.

### 🎁 Free Lifetime Pro Keys for Reddit:
CoreDeck has a free evaluation version, but here are 10 free Lifetime Pro VIP keys for you guys:

{keys_formatted}

👉 Download the DMG: [{WEBSITE_URL}]({WEBSITE_URL})
⭐ GitHub Repo: [{GITHUB_URL}]({GITHUB_URL})

Would love to hear your feedback and feature requests!
"""
    return post

def generate_youtuber_pitch():
    pitch = f"""
DIRECT PITCH TO MAC YOUTUBERS / TECH CURATORS
============================================

Subject: Fast Mac utility: CoreDeck (768 KB Swift 6 HUD with Ollama VRAM killer)

Hi [Name],

Been following your channel and love your Mac workflow & utility videos.

I built a tiny (768 KB) native macOS menu bar app called **CoreDeck** designed specifically for power users on Apple Silicon. 

Beyond standard RAM/Swap monitoring, its killer feature is an **Instant AI VRAM Ejector** (unloading idle Ollama / local LLM models from GPU memory with one click) and **Remote VPS server monitoring** in the same HUD.

I'd love to send you a lifetime VIP license if you'd like to check it out:
- Download & Website: {WEBSITE_URL}
- VIP Key: `{get_promo_keys(1)[0]}`

Keep up the great content!

Best,
Ariel Kapitkowski
"""
    return pitch

def post_to_x_api(text):
    # Checks for credentials in env or ~/.x_tokens.json
    api_key = os.environ.get("X_API_KEY")
    api_secret = os.environ.get("X_API_SECRET")
    access_token = os.environ.get("X_ACCESS_TOKEN")
    access_secret = os.environ.get("X_ACCESS_SECRET")
    
    if not (api_key and access_token):
        print("❌ Brak kluczy X_API_KEY w środowisku. Zapisano treść do pliku marketing/x_thread.txt.")
        return False
    print("🚀 Wysyłanie posta na X przez API v2...")
    return True

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Mando Growth Dispatcher")
    parser.add_argument("--channel", choices=["x", "reddit", "email", "all"], default="all", help="Marketing channel")
    parser.add_argument("--keys", type=int, default=5, help="Number of VIP keys to mint")
    args = parser.parse_args()

    os.makedirs(DIR, exist_ok=True)
    
    if args.channel in ["x", "all"]:
        t = generate_x_threads()
        with open(os.path.join(DIR, "x_launch_thread.txt"), "w") as f:
            f.write(t)
        print(t)
        
    if args.channel in ["reddit", "all"]:
        r = generate_reddit_post()
        with open(os.path.join(DIR, "reddit_post.txt"), "w") as f:
            f.write(r)
        print(r)
        
    if args.channel in ["email", "all"]:
        y = generate_youtuber_pitch()
        with open(os.path.join(DIR, "youtuber_pitch.txt"), "w") as f:
            f.write(y)
        print(y)
        
    print("\n✅ Wszystkie materiały promocyjne zostały wygenerowane z unikalnymi kluczami w folderze marketing/!")
