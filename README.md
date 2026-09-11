# LumiCord

> Modernized client modification for **Discord iOS (v344.1+)** with React Native New Architecture (Fabric & Bridgeless) support. Forked and upgraded from BunnyTweak.

[![GitHub Release](https://img.shields.io/github/v/release/Lumice/BunnyTweak?color=7289da&label=Release)](https://github.com/Lumice/BunnyTweak/releases/latest)
[![Target Discord](https://img.shields.io/badge/Discord%20iOS-v344.1%2B-5865F2)](https://github.com/Lumice/BunnyTweak/releases/latest)
[![React Native](https://img.shields.io/badge/React%20Native-New%20Architecture%20(Bridgeless)-61DAFB)](https://reactnative.dev)
[![License](https://img.shields.io/badge/License-OSL%203.0-blue.svg)](LICENSE)

---

## ✨ Features & Upgrades

* **React Native New Architecture Support**: Full runtime injection via `RCTInstance` (`_loadScriptFromSource:` / `loadScriptFromSource:`) with fallback to legacy `RCTCxxBridge` for older builds.
* **Full Duplicate App Compatibility**: Retains separate OS-level bundle identifiers and sandboxes so you can install and run two Discord apps side-by-side using Signulous, Sideloadly, or AltStore without sandbox collisions.
* **Modernized Default Bundle (Revenge)**: Automatically loads the actively maintained [Revenge bundle](https://github.com/revenge-mod/revenge-bundle), supporting Discord's redesigned navigation, settings, and chat layout.
* **Recovery Menu**: Shake your device to open the in-app recovery sheet to clear caches, switch bundle URLs, or toggle safe mode.
* **Sideloading Hardening**: Automatically redirects missing AppGroups to `Documents/AppGroup`, fixes file/image pickers, and catches passkey/icon errors without crashing.

---

## 📥 Installation

Pre-built IPAs and rootless `.deb` packages can be downloaded from the **[Releases](https://github.com/Lumice/BunnyTweak/releases/latest)** tab.

| File | Description | Recommended Sideloading Tools |
| :--- | :--- | :--- |
| **`LumiCord.ipa`** | Clean, optimized IPA with all extensions stripped for maximum compatibility. | **Signulous (Duplicate App)**, Sideloadly, AltStore, SideStore, Feather, TrollStore |
| **`LumiCord-WithExtension.ipa`** | Includes the optional OpenInDiscord Safari extension. | TrollStore or Paid Apple Developer certs ($99/year) |
| **`dev.lumice.lumicord_*.deb`** | Rootless Debian package for jailbroken devices. | Sileo, Zebra |

### Installing with Signulous (Duplicate App Setup)
1. Download **`LumiCord.ipa`** from [Releases](https://github.com/Lumice/BunnyTweak/releases/latest).
2. Open the **[Signulous Dashboard](https://www.signulous.com/)** and navigate to **Upload App**.
3. Select `LumiCord.ipa`.
4. Enable the **Duplicate App** option (so it installs alongside your existing Discord).
5. Click **Sign App** and tap **Install App** once processing finishes.

### Installing with Sideloadly / AltStore
1. Download **`LumiCord.ipa`**.
2. Drag and drop into Sideloadly or import into AltStore.
3. Sign with your Apple ID and install.

---

## 🛒 Plugin Marketplace & Top Plugins

LumiCord supports the full community plugin ecosystem. You can install a complete in-app **Plugin Marketplace** directly inside Discord:

### How to Install the Marketplace (Plugin Browser):
1. In Discord, go to **User Settings** (gear icon).
2. Scroll down to the client mod settings section (**Revenge** or **LumiCord**) and tap **Plugins**.
3. Tap the **`+`** (Plus) button in the top-right corner.
4. Paste the Plugin Browser marketplace URL:
   ```text
   https://revenge.nexpid.xyz/plugin-browser/
   ```
5. Tap **Install** and confirm. You will now have a **Plugin Browser** tab in Settings to search, browse, and 1-tap install plugins!

### Top Recommended Plugins:
* **Clean URLs**: `https://revenge.nexpid.xyz/clean-urls/` (strips tracking parameters from links)
* **Message Preview**: `https://revenge.nexpid.xyz/message-preview/` (preview formatting before sending)
* **Char Counter**: `https://revenge.nexpid.xyz/char-counter/` (real-time message length counter)
* **Use System Emoji**: `https://revenge.nexpid.xyz/use-system-emoji/` (use native Apple iOS emojis)
* **Cloud Sync**: `https://revenge.nexpid.xyz/cloud-sync/` (cloud backup for plugins and settings)

---

## 🛠️ Building & Creating New Releases

### Via GitHub Actions (Easiest / Automated):
You can build a patched IPA for any newer Discord version directly using GitHub Actions:

```bash
gh workflow run deploy.yml --repo Lumice/BunnyTweak \
  -f ipa_url="<DIRECT_DOWNLOAD_URL_TO_DECRYPTED_DISCORD_IPA>" \
  -f release=true \
  -f is_testflight=false
```
The workflow will compile the tweak with Theos on a macOS runner, inject it with `cyan`, and publish the new release automatically.

### Local Compilation (macOS with Theos):
1. Ensure [Theos](https://theos.dev) is installed.
2. Clone this repository:
   ```bash
   git clone https://github.com/Lumice/BunnyTweak.git && cd BunnyTweak
   ```
3. Compile the rootless tweak package:
   ```bash
   make package
   ```
   The compiled `.deb` will be in the `packages/` directory.

---

## 📜 Credits & License

* Upgraded and maintained by **[Lumi](https://github.com/Lumice)**.
* Originally forked from **[BunnyTweak](https://github.com/bunny-mod/BunnyTweak)** by Adrian Castro, Pylix, and FieryFlames.
* Originally based on **[VendettaTweak](https://github.com/vendetta-mod/VendettaTweak)** by the Vendetta mod team.
* JavaScript bundle powered by the **[Revenge](https://github.com/revenge-mod/revenge-bundle)** project.
* Licensed under the **Open Software License 3.0 (OSL 3.0)**. See [LICENSE](LICENSE) for details.
