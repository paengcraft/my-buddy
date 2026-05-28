# Desktop Buddy MVP Design

## Status

Draft for user review.

## Context

This repository starts empty. The first product target is a macOS desktop companion app. The app should show a small animated character above the desktop, let the user click it for a reaction, and sync that reaction to another computer on the same Wi-Fi network. The app should also let the user send a short chat message that appears as a temporary speech bubble above the other computer's character.

The user-provided character art can be used for a private local prototype. If the app is ever distributed, shared publicly, or marketed, the character asset should be reviewed or replaced with original/licensed artwork.

## Goals

- Build a macOS desktop app with a transparent, always-on-top character overlay.
- Use Tauri with Svelte and TypeScript for the UI.
- Use Rust for local networking and app-level event handling.
- Support one selected peer on the same Wi-Fi/LAN for the first version.
- Sync click reaction events between the two computers.
- Send short chat messages that appear as speech bubbles for a few seconds.
- Keep the networking boundary replaceable so internet relay support can be added later.

## Non-Goals

- No public distribution in the first version.
- No App Store packaging or notarization in the first version.
- No full chat history, accounts, push notifications, or cloud sync.
- No multi-peer room behavior in the first version.
- No Windows/Linux support in the first implementation, although the architecture should avoid unnecessary macOS-only coupling outside the platform layer.

## Product Behavior

The app launches as a lightweight desktop buddy. The main window is transparent and borderless, with the character visible above the desktop. The character has a small idle animation. Clicking the character triggers a local reaction animation immediately, then sends a reaction event to the selected peer. When a reaction event is received from the peer, the local character plays the same reaction animation.

The user can open a compact input affordance from the buddy UI and send a short message. On the peer computer, the message appears above the character as a speech bubble and disappears after a short duration. The first version keeps this as ephemeral communication rather than a persistent messenger.

## Architecture

The app uses Tauri as the desktop shell, Svelte as the frontend, and Rust as the app core.

- Tauri shell: transparent window, always-on-top behavior, window sizing, app lifecycle, and macOS-specific configuration.
- Svelte UI: character rendering, idle animation, click reaction animation, speech bubble rendering, and message input.
- Rust core: peer discovery, peer connection, event serialization, event routing, and future relay abstraction.
- Event bridge: typed commands and events between Svelte and Rust.
- Platform layer: macOS-specific window behavior isolated from product and networking code.

The UI should not know whether events came from LAN, loopback, or a future relay server. It should only publish user actions and subscribe to buddy events.

## Components

### Frontend

- `BuddyStage`: owns the visible character area and transparent overlay layout.
- `BuddyCharacter`: renders the character asset and animation states.
- `SpeechBubble`: displays incoming or local ephemeral messages.
- `MessageComposer`: compact text input for sending short messages.
- `connectionStore`: stores peer status and connection UI state.
- `buddyEventStore`: receives Rust events and maps them to UI state changes.

### Rust Core

- `AppIdentity`: creates and persists a local device id and display name.
- `PeerDiscovery`: advertises the local app and discovers LAN peers.
- `PeerRegistry`: tracks discovered peers and the selected peer.
- `Transport`: sends and receives buddy events.
- `LanTransport`: first transport implementation for same-Wi-Fi peers.
- `EventRouter`: validates inbound events and forwards them to the Tauri frontend.
- `PlatformWindow`: applies macOS overlay window settings.

### Shared Event Model

Events use small JSON-compatible payloads:

- `reaction`: `{ "type": "reaction", "reaction": "tap" }`
- `chat_message`: `{ "type": "chat_message", "text": "...", "sent_at": "..." }`
- `presence`: `{ "type": "presence", "device_id": "...", "display_name": "..." }`

The first version only needs `tap` as a reaction type. The model leaves room for future reactions without changing the transport contract.

## LAN Networking

The first version uses same-Wi-Fi discovery and direct peer communication.

- Discovery: mDNS/Bonjour service advertisement for local peer discovery.
- Pairing: user selects one discovered peer from a small connection UI.
- Transport: direct local connection using JSON messages over a Rust-managed socket.
- Fallback: if discovery fails, allow manual IP and port entry in a later small follow-up.

This is a practical first step because it avoids server cost and account design. The trade-off is that LAN discovery can be affected by router isolation, VPNs, firewall prompts, or enterprise Wi-Fi restrictions. Those failures should appear as connection status messages instead of silent failure.

## Future Internet Relay

The Rust core should define a `Transport` boundary so a future `RelayTransport` can be added without changing the Svelte UI. The future relay can handle identity, authentication, and NAT traversal at the server layer. The first version should not introduce accounts or server dependencies before the core interaction is proven locally.

## Error Handling

- If no peer is discovered, show a disconnected state and keep the local character usable.
- If a send fails, keep the local reaction but mark the peer as disconnected or retryable.
- If an inbound chat message is too long or invalid, drop it and log the reason.
- If the peer disconnects, clear active peer state and keep discovery running.
- If macOS window settings fail, fall back to a normal small window rather than crashing.

## Privacy and Safety

The MVP should only communicate on the local network. Messages are ephemeral and not written to disk. The app should store only local identity, selected peer information, and lightweight preferences. Because the first prototype runs only on trusted machines, encryption is not required for MVP, but the event transport should be isolated enough to add secure pairing later.

## Testing and Verification

- Unit test Rust event serialization and validation.
- Unit test Rust peer registry behavior.
- Test Svelte stores for event-to-state mapping.
- Run Tauri app locally and verify transparent overlay behavior on macOS.
- Run two local app instances or two machines on the same Wi-Fi to verify reaction and chat events.
- Verify that the app remains usable when no peer is connected.

## Open Assumptions

- The first implementation targets macOS only.
- The first version connects to one selected peer.
- The initial character asset is user-provided and local-only.
- Chat messages are short, ephemeral, and not saved.
- Internet relay support is planned as a later phase, not part of MVP.
