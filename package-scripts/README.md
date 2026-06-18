# Codex Offline Package for Windows x64

Version: Codex CLI 0.135.0
Desktop extracted payload: OpenAI.Codex 26.602.9276.0 x64

This folder is a local offline installer package for Codex CLI on Windows x64.

## Files

- `install-cli-offline.ps1` installs Codex CLI fully offline.
- `cli-native/codex.cmd` runs the bundled native Codex CLI without Node.js or npm.
- `npm/openai-codex-0.135.0.tgz` is the Codex CLI npm package.
- `npm/openai-codex-0.135.0-win32-x64.tgz` contains the Windows x64 native binary and helper executables.
- `installers/node-v24.0.0-x64.msi` is bundled so a machine without Node.js can still install offline.
- `installers/Codex Store Installer.exe` is the official Microsoft Store handoff installer for Codex Desktop.
- `desktop-expanded/` contains an extracted copy of the installed Codex Desktop package payload from this machine.
- `enable-store-direct-bypass.ps1` adds Microsoft Store domains to the current user's proxy bypass list.
- `install-desktop-expanded.ps1` tries to register the extracted desktop payload as an experimental fallback.
- `run-desktop-expanded.ps1` launches the extracted desktop executable directly as an experimental fallback.

## Install Codex CLI Offline

Open PowerShell in this folder and run:

```powershell
.\install-cli-offline.ps1
```

If the target machine already has Node.js 16 or newer and you do not want the script to install Node:

```powershell
.\install-cli-offline.ps1 -SkipNodeInstall
```

Verify:

```powershell
codex --version
```

If Node.js/npm is not available and you just need the native CLI from this package:

```powershell
.\cli-native\codex.cmd --version
```

## Desktop App Note

Codex Desktop for Windows is distributed through Microsoft Store. The current official Store metadata does not expose a standalone full offline `.msix` or `.msixbundle` download for this app to ordinary Store clients.

`winget download` can discover the Codex Store package, but Microsoft Store package download information requires Microsoft Entra ID authorization for offline package distribution. A normal Store install does not grant that offline download right.

This package therefore includes three desktop options:

1. Official Store route: `install-desktop-store.ps1`
2. Experimental extracted payload registration or portable shortcut fallback: `install-desktop-expanded.ps1`
3. Experimental direct executable launch: `run-desktop-expanded.ps1`

To try the desktop installer:

```powershell
.\install-desktop-store.ps1
```

If Microsoft Store or WinHTTP TLS is broken on the machine, desktop installation can fail even though the CLI offline installer works.

If a VPN or local proxy breaks Microsoft Store TLS, keep the VPN running and run:

```powershell
.\enable-store-direct-bypass.ps1
```

Then retry:

```powershell
winget install --id 9PLM9XGG6VKS --source msstore --accept-source-agreements --accept-package-agreements
```

To try the extracted payload fallback:

```powershell
.\install-desktop-expanded.ps1
```

If Windows rejects Appx registration, the script creates a Start Menu shortcut named `Codex Offline Expanded` and launches the extracted desktop executable directly. To disable that fallback and fail on registration errors:

```powershell
.\install-desktop-expanded.ps1 -NoPortableFallback
```

Direct launch may also be useful for inspection:

```powershell
.\run-desktop-expanded.ps1
```

## Verify Package Contents

```powershell
.\verify-package.ps1
```
