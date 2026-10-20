# MacCare

A lightweight, modern native macOS system monitor and maintenance tool built with Swift and SwiftUI.

MacCare provides real-time hardware sensor monitoring (CPU, GPU, RAM, SSD, and battery temperatures) via Apple's native IOKit framework, paired with a safe system cleanup utility to reclaim disk space.

---

## Features

### Real-Time Hardware Telemetry
* **Direct Sensor Telemetry:** Reads thermal data directly from Apple Silicon PMU die clusters, NAND storage controllers, and battery gas gauges via `IOHIDEventSystemClient` with legacy AppleSMC fallback on Intel Macs.
* **Granular Component Metrics:**
  * CPU core and cluster temperatures
  * GPU die temperatures
  * Unified Memory (RAM / LPDDR) controller temperature
  * Internal SSD (NAND) controller temperature
  * Battery pack temperature
* **Menu Bar Extra:** Compact live temperature readout in the macOS menu bar with an instant dropdown summary panel.
* **Custom Refresh Intervals:** Configurable telemetry polling (1s, 2s, 3s, 5s).
* **Unit Conversion:** Full support for Celsius (°C) and Fahrenheit (°F).

### System Cleaner
* **Targeted Cleanup Targets:**
  * User and system caches (`~/Library/Caches`, `/Library/Caches`)
  * Stale diagnostic reports and crash logs (`.log`, `.crash`, `.ips` older than 7 days)
  * Xcode development artifacts (`DerivedData` and archived builds)
  * Homebrew package and download caches
  * Quick inspection of Trash and user Downloads
* **Safety First:**
  * Strict path boundary validation prevents directory traversal.
  * Symlinks are never followed during deletion.
  * Core operating system files and personal documents are strictly protected.
  * System-level caches require explicit administrator authorization via native macOS prompts.

### Modern Interface & Themes
* **Theme Switching:** Instant support for System Default, Dark Mode, and Light Mode with a single-click sidebar toggle or preferences panel.
* **Localization:** Built-in support for English (default) and Turkish (Türkçe), switchable on the fly without restarting.
* **Launch at Login:** Native integration with Apple's modern `SMAppService` API.
* **Minimalist Aesthetics:** Monochromatic titanium hardware silhouette, glassmorphism cards, and smooth micro-interactions.

---

## Requirements

* macOS 14.0 (Sonoma) or later
* Apple Silicon (M1/M2/M3/M4/M5) or Intel Mac
* Swift 6.0+ / Xcode 15+ (for building from source)

---

## Building from Source

MacCare is configured as a standalone Swift Package and can be compiled using the standard Swift toolchain without requiring full Xcode project overhead.

### 1. Clone the repository
```bash
git clone https://github.com/your-username/maccare.git
cd maccare
```

### 2. Run in development mode
```bash
swift run MacCare
```

### 3. Build standalone `.app` bundle
Use the included build script to compile a release binary and package `MacCare.app` with the high-resolution app icon:
```bash
chmod +x build-app.sh
./build-app.sh
```

The output bundle will be located at `./MacCare.app`.

---

## Architecture & Security

* **No External Dependencies:** Zero third-party packages or pods. Built entirely on Apple system frameworks (`SwiftUI`, `AppKit`, `IOKit`, `ServiceManagement`).
* **Non-Root Execution:** Telemetry is gathered via user-space IOHID client APIs. Root privileges are never held permanently; elevated privileges are only requested on-demand when deleting protected `/Library/Caches` folders.
* **Path Canonicalization:** All deletion paths are canonicalized using `resolvingSymlinksInPath().standardizedFileURL` and matched against a hardcoded whitelist before any file operations occur.

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
