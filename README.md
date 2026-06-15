# My Buddy

My Buddy is a native macOS desktop buddy prototype. It runs as a transparent always-on-top SwiftUI/AppKit overlay, uses packaged character frames, and broadcasts reactions plus chat messages to nearby instances on the same Wi-Fi network or through a Cloudflare Worker relay.

## Current Scope

- Native Swift Package based macOS app under `native/`.
- Cloudflare Worker relay under `relay/`.
- SwiftUI interface with AppKit `NSPanel` overlay behavior.
- Packaged character idle frame and click animation resources.
- Left click plays the character reaction.
- Double click opens chat.
- Right click toggles the edit/settings UI.
- Drag the character to move it around the desktop.
- Drag the character into a screen corner docking zone to open the shared TODO board.
- Settings UI contains peer status, relay room controls, size presets/slider, display name, reset, and quick reactions.
- Shared TODOs show who created each item, can be completed or deleted, and sync through LAN or the relay.
- UDP LAN broadcast on port `49277` for nearby reaction/chat sync.
- Cloudflare Worker relay for different-network reaction/chat sync.

## Requirements

- macOS with Xcode or Xcode command line tools.
- Swift 5.10 or compatible.
- Node.js 20 or compatible for relay Worker tests and billing guard checks.
- Same Wi-Fi network for local peer discovery, or internet access for Cloudflare relay pairing.

## Quick Start

Clone the repository and install relay dependencies:

```bash
git clone git@github.com:paengcraft/my-buddy.git
cd my-buddy
cd relay
npm install
cd ..
```

If SSH is not configured for the GitHub account, use HTTPS instead:

```bash
git clone https://github.com/paengcraft/my-buddy.git
cd my-buddy
cd relay
npm install
cd ..
```

Build and open the native macOS app:

```bash
cd native
swift test
./scripts/build_app.sh
open -n "build/My Buddy.app"
```

The build script creates:

- `native/build/My Buddy.app`
- `native/build/My Buddy_0.1.0_aarch64.dmg`

## Test And Package

Run the full smoke check from the repository root:

```bash
./scripts/qa_smoke.sh
```

This runs:

- Relay unit tests.
- Relay TypeScript checks.
- Relay billing guard dry-run.
- Native Swift tests.
- Native app and DMG builds.
- Local A/B test app builds.

To build two local test copies with separate bundle identifiers:

```bash
cd native
./scripts/build_test_pair.sh
open -n "build/My Buddy A.app"
open -n "build/My Buddy B.app"
```

Use the same relay code in both copies to test chat and reactions on one Mac.

To build and open both test copies in one command:

```bash
cd native
./scripts/run_test_pair.sh
```

To clear saved settings before opening both copies:

```bash
cd native
RESET_DEFAULTS=1 ./scripts/run_test_pair.sh
```

## Install Test Build On Another Mac

For local testing without Apple Developer ID notarization, copy the app to `/Applications` and remove the quarantine flag:

```bash
cp -R "native/build/My Buddy.app" "/Applications/My Buddy.app"
xattr -dr com.apple.quarantine "/Applications/My Buddy.app"
open "/Applications/My Buddy.app"
```

For warning-free distribution, sign with a Developer ID certificate and notarize the DMG before sharing it.

Manual QA checklist:

```text
docs/qa/manual-smoke-test.md
```

## Push Changes

Check the current branch and changed files:

```bash
git status --short --branch
```

Stage, commit, and push:

```bash
git add -A
git commit -m "docs : 실행 방법 정리"
git push
```

If the remote is not set yet:

```bash
git remote add origin git@github.com:paengcraft/my-buddy.git
git push -u origin feature/desktop-buddy-mvp
```

If SSH access is not available, use HTTPS:

```bash
git remote add origin https://github.com/paengcraft/my-buddy.git
git push -u origin feature/desktop-buddy-mvp
```

## Same Wi-Fi Test

1. Connect two Macs to the same Wi-Fi network.
2. Build and open `My Buddy.app` on both machines.
3. Allow local network access if macOS asks.
4. Right click the character and check peer status in settings.
5. Left click or send a chat message on one machine.
6. The other machine should play the reaction or show the speech bubble.

Some routers, VPNs, and enterprise Wi-Fi networks block UDP broadcast traffic. If peers are not discovered, test on a simpler home Wi-Fi network first.

## Internet Relay Test

The relay Worker is deployed at:

```text
https://buddy-relay.ruccess0-0.workers.dev
```

1. Build and open `My Buddy.app` on both Macs.
2. Right click the character to open settings.
3. On the first Mac, click `+` in the Relay row to create an eight-character relay code.
4. Click the copy button and enter the same code on the second Mac.
5. Click `Join` on both Macs.
6. Send a chat message, use a quick reaction, or single-click the character on one Mac.
7. The other Mac should show the speech bubble or play the same reaction.
8. Drag one buddy into a screen corner, add a TODO, and confirm it appears on the other Mac.
9. Toggle and delete the TODO from either Mac and confirm both sides converge.

Relay billing guardrails:

- The Worker uses Cloudflare Workers and one Durable Object binding only.
- It does not use AI, D1, R2, KV, Queues, Pages, Containers, Email, Images, Stream, or paid domains.
- Messages and TODOs are not stored. The relay only forwards small live reaction/chat/TODO snapshot events between active sockets in the same room.
- Run `cd relay && npm run check:billing` before deployment to fail the build if dry-run output shows disallowed resources.

## Character Assets

Generated native resources live in:

```text
native/Sources/MyBuddyApp/Resources/
```

If the app is ever shared or distributed, use original or properly licensed artwork.
