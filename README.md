# Buddy Noti

Buddy Noti is a local-first macOS desktop buddy prototype. It shows a small transparent overlay character, plays a reaction when clicked, and broadcasts click/chat events to nearby app instances on the same Wi-Fi network.

## Current Scope

- Tauri 2 desktop shell.
- Svelte 5 + TypeScript frontend.
- Rust event core and UDP LAN broadcast on port `49277`.
- Transparent, borderless, always-on-top macOS window.
- Local placeholder character asset at `src/lib/assets/buddy-placeholder.svg`.
- Short ephemeral speech-bubble messages.

This prototype is not prepared for public distribution yet. The transparent macOS window uses Tauri's `macos-private-api` feature, which is acceptable for this local prototype but not suitable for App Store distribution.

## Requirements

- macOS with Xcode command line tools.
- Node.js 22 or compatible.
- Rust toolchain.

## Install

```bash
npm install
```

## Run

```bash
npm run tauri dev
```

The app opens as a small transparent buddy window. Click the character to trigger a reaction. Type a short message and send it to show a temporary speech bubble locally and broadcast it to nearby peers.

## Same Wi-Fi Test

1. Connect two Macs to the same Wi-Fi network.
2. Run `npm run tauri dev` on both machines.
3. Allow local network access if macOS asks.
4. Wait until the status changes from `Wi-Fi peer not found`.
5. Click the character or send a message on one machine.
6. The other machine should play the reaction or show the speech bubble.

Some routers, VPNs, and enterprise Wi-Fi networks block broadcast traffic. If peers are not discovered on the same Wi-Fi, test on a simpler home network first.

## Character Asset

Replace `src/lib/assets/buddy-placeholder.svg` with a local image asset when the final private prototype art is ready. If the app is ever shared or distributed, use original or properly licensed artwork.

## Verification

```bash
npm run check
npm test -- --run
npm run build
cargo test --manifest-path src-tauri/Cargo.toml
```
