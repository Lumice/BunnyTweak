# LumiCord

> Up-to-date client modification for **Discord iOS (v344.1+)** with React Native New Architecture (Fabric & Bridgeless) support.

[![Target Discord](https://img.shields.io/badge/Discord%20iOS-v344.1%2B-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://github.com/Lumice/BunnyTweak/releases/latest)
[![Latest Release](https://img.shields.io/github/v/release/Lumice/BunnyTweak?color=7289da&label=Download&style=for-the-badge)](https://github.com/Lumice/BunnyTweak/releases/latest)
[![License](https://img.shields.io/badge/License-OSL%203.0-blue?style=for-the-badge)](LICENSE)

---

## 🚀 Key Features

* **Discord 344.1+ Compatibility**: Fully upgraded to hook into React Native's New Architecture (Fabric renderer and Bridgeless runtime).
* **Duplicate App Ready**: Safe for dual-installation alongside the official Discord app via Signulous, Sideloadly, AltStore, or TrollStore with zero sandbox or bundle ID collisions.
* **Modern In-App Engine**: Powered by the actively maintained [Revenge bundle](https://github.com/revenge-mod/revenge-bundle), supporting Discord's redesigned mobile UI and navigation.
* **Recovery Menu**: Shake your device to open recovery options, clear caches, or switch bundle endpoints.
* **Sideloading Fixes**: Resolves file/image pickers, sandboxed AppGroups, and passkey errors automatically.

---

## 📥 Download & Installation

Download the latest pre-patched IPA from **[Releases](https://github.com/Lumice/BunnyTweak/releases/latest)**:

👉 **[Download `LumiCord.ipa`](https://github.com/Lumice/BunnyTweak/releases/latest)**

### Signulous (Dual / Duplicate App)
1. Download **`LumiCord.ipa`**.
2. Go to **Signulous Dashboard > Upload App** and select `LumiCord.ipa`.
3. Enable the **Duplicate App** toggle so it installs alongside your existing Discord.
4. Click **Sign App** and install.

### Sideloadly / AltStore / SideStore / TrollStore
1. Download **`LumiCord.ipa`**.
2. Import or drag into your installer.
3. Sign and install to your device.

---

## 🛒 Plugin Marketplace

LumiCord lets you install a full **Plugin Marketplace** directly inside Discord Settings:

1. Open Discord and go to **Settings** (gear icon on your profile).
2. Scroll to the client mod section (**Revenge** / **LumiCord**) and tap **Plugins**.
3. Tap the **`+`** (Plus) button in the top-right corner.
4. Paste the marketplace URL:
   ```text
   https://revenge.nexpid.xyz/plugin-browser/
   ```
5. Tap **Install**. A **Plugin Browser** tab will now appear in your Settings, allowing you to browse and install plugins with one tap!

---

## 🛠️ Building New Versions

When Discord releases an update, you can generate a new patched IPA directly from GitHub Actions without needing a Mac:

```bash
gh workflow run deploy.yml --repo Lumice/BunnyTweak \
  -f ipa_url="<DIRECT_URL_TO_DECRYPTED_DISCORD_IPA>" \
  -f release=true \
  -f is_testflight=false
```

---

## 📜 Credits & License

* Upgraded and maintained by **[Lumi](https://github.com/Lumice)**.
* Originally forked from **[BunnyTweak](https://github.com/bunny-mod/BunnyTweak)** by Adrian Castro, Pylix, and FieryFlames.
* Built on the **[Revenge](https://github.com/revenge-mod/revenge-bundle)** bundle ecosystem.
* Licensed under the **Open Software License 3.0 (OSL 3.0)**. See [LICENSE](LICENSE) for details.
