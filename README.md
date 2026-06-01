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
- Settings UI contains peer status, relay room controls, size presets/slider, display name, reset, and quick reactions.
- UDP LAN broadcast on port `49277` for nearby reaction/chat sync.
- Cloudflare Worker relay for different-network reaction/chat sync.

## Requirements

- macOS with Xcode or Xcode command line tools.
- Swift 5.10 or compatible.
- Node.js 20 or compatible for relay Worker tests and billing guard checks.
- Same Wi-Fi network for local peer discovery, or internet access for Cloudflare relay pairing.

## Build And Run

```bash
cd native
swift test
./scripts/build_app.sh
open -n "build/My Buddy.app"
```

The build script creates:

- `native/build/My Buddy.app`
- `native/build/My Buddy_0.1.0_aarch64.dmg`

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

To run the automated smoke checks:

```bash
./scripts/qa_smoke.sh
```

Manual QA checklist:

```text
docs/qa/manual-smoke-test.md
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

Relay billing guardrails:

- The Worker uses Cloudflare Workers and one Durable Object binding only.
- It does not use AI, D1, R2, KV, Queues, Pages, Containers, Email, Images, Stream, or paid domains.
- Messages are not stored. The relay only forwards small live reaction/chat events between active sockets in the same room.
- Run `cd relay && npm run check:billing` before deployment to fail the build if dry-run output shows disallowed resources.

## Character Assets

Generated native resources live in:

```text
native/Sources/MyBuddyApp/Resources/
```

If the app is ever shared or distributed, use original or properly licensed artwork.
