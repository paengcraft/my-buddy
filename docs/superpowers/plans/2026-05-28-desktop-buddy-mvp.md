# Desktop Buddy MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Tauri + Svelte macOS desktop buddy prototype with a transparent character overlay, click reactions, short speech-bubble chat, and same-Wi-Fi event sync.

**Architecture:** Tauri owns the desktop shell and Rust backend. Svelte renders the character, animations, message composer, and connection state. Rust owns typed buddy events, UDP LAN broadcast transport for the MVP, and a transport boundary that can later be replaced by mDNS/direct pairing or an internet relay.

**Tech Stack:** Tauri 2, Svelte 5, TypeScript, Vite, Rust, Serde, Vitest, Cargo tests.

---

## File Structure

- `package.json`: npm scripts and frontend dependencies.
- `src/main.ts`: Svelte app entry.
- `src/App.svelte`: main buddy stage composition.
- `src/lib/components/BuddyCharacter.svelte`: character image and animation state.
- `src/lib/components/SpeechBubble.svelte`: temporary bubble display.
- `src/lib/components/MessageComposer.svelte`: compact message input.
- `src/lib/stores/buddyEvents.ts`: frontend event store and Tauri event bridge.
- `src/lib/stores/connection.ts`: connection status store.
- `src/lib/assets/buddy-placeholder.svg`: local-only placeholder asset until the user supplies a file.
- `src-tauri/src/models.rs`: shared Rust event and peer types.
- `src-tauri/src/state.rs`: app identity, peer state, event validation, and transport handles.
- `src-tauri/src/network.rs`: UDP LAN listener, broadcast sender, inbound event router, and peer presence tracking.
- `src-tauri/src/commands.rs`: Tauri commands invoked by Svelte.
- `src-tauri/src/platform.rs`: macOS window overlay setup.
- `src-tauri/src/lib.rs`: Tauri app setup and plugin wiring.
- `src-tauri/tauri.conf.json`: transparent window config.

## Task 1: Scaffold Tauri Svelte App

**Files:**
- Create: `package.json`
- Create: `src-tauri/Cargo.toml`
- Create: `src-tauri/tauri.conf.json`
- Create: `src/main.ts`
- Create: `src/App.svelte`

- [ ] **Step 1: Scaffold app**

Run:

```bash
npm create tauri-app@latest -- . --template svelte-ts --manager npm --identifier com.buddynoti.app --tauri-version 2 --force --yes
```

Expected: project files are created in the current directory without removing `docs/`.

- [ ] **Step 2: Install dependencies**

Run:

```bash
npm install
```

Expected: `node_modules/` and `package-lock.json` are created.

- [ ] **Step 3: Verify scaffold**

Run:

```bash
npm run build
cargo test --manifest-path src-tauri/Cargo.toml
```

Expected: frontend build passes and Rust tests run.

- [ ] **Step 4: Commit**

```bash
git add package.json package-lock.json index.html src src-tauri
git commit -m "feature : Tauri Svelte 앱 초기화"
```

## Task 2: Add Typed Rust Buddy Core and LAN Transport

**Files:**
- Create: `src-tauri/src/models.rs`
- Create: `src-tauri/src/state.rs`
- Create: `src-tauri/src/network.rs`
- Create: `src-tauri/src/commands.rs`
- Modify: `src-tauri/src/lib.rs`

- [ ] **Step 1: Write Rust model tests**

Add tests for chat message validation, wire event serialization, and self-message filtering.

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::{BuddyEvent, ReactionKind, WireEvent};

    #[test]
    fn accepts_short_chat_message() {
        assert_eq!(validate_chat_text("hello").unwrap(), "hello");
    }

    #[test]
    fn rejects_blank_chat_message() {
        assert!(validate_chat_text("   ").is_err());
    }

    #[test]
    fn rejects_long_chat_message() {
        let text = "a".repeat(MAX_CHAT_TEXT_LEN + 1);
        assert!(validate_chat_text(&text).is_err());
    }

    #[test]
    fn serializes_reaction_wire_event() {
        let event = WireEvent::from_local("device-1", BuddyEvent::Reaction { reaction: ReactionKind::Tap });
        let json = serde_json::to_string(&event).unwrap();
        assert!(json.contains("\"type\":\"reaction\""));
        assert!(json.contains("\"device_id\":\"device-1\""));
    }

    #[test]
    fn filters_self_wire_event() {
        let event = WireEvent::from_local("device-1", BuddyEvent::Reaction { reaction: ReactionKind::Tap });
        assert!(is_self_event("device-1", &event));
        assert!(!is_self_event("device-2", &event));
    }
}
```

- [ ] **Step 2: Run Rust test to verify failure**

Run:

```bash
cargo test --manifest-path src-tauri/Cargo.toml
```

Expected: fail because `validate_chat_text`, `WireEvent`, and `is_self_event` are not defined.

- [ ] **Step 3: Implement models and commands**

Create typed `BuddyEvent`, `ReactionKind`, `PeerInfo`, `WireEvent`, and commands: `get_local_identity`, `send_reaction`, `send_chat_message`, `list_peers`. Add UDP broadcast listener on port `49277` that ignores events from the local device id, stores peer presence, emits inbound reactions/messages to the Svelte frontend, and keeps local-only behavior available when no peer is online.

- [ ] **Step 4: Run Rust tests**

Run:

```bash
cargo test --manifest-path src-tauri/Cargo.toml
```

Expected: all Rust tests pass.

- [ ] **Step 5: Commit**

```bash
git add src-tauri/src src-tauri/Cargo.toml
git commit -m "feature : LAN 버디 이벤트 코어 추가"
```

## Task 3: Build Svelte Buddy UI

**Files:**
- Create: `src/lib/components/BuddyCharacter.svelte`
- Create: `src/lib/components/SpeechBubble.svelte`
- Create: `src/lib/components/MessageComposer.svelte`
- Create: `src/lib/stores/buddyEvents.ts`
- Create: `src/lib/stores/connection.ts`
- Create: `src/lib/assets/buddy-placeholder.svg`
- Modify: `src/App.svelte`
- Modify: `src/app.css`

- [ ] **Step 1: Add frontend store tests**

Create tests for local reaction and speech bubble state.

- [ ] **Step 2: Run frontend tests to verify failure**

Run:

```bash
npm test -- --run
```

Expected: fail before store implementation.

- [ ] **Step 3: Implement UI components and stores**

Implement a transparent buddy stage with a floating character, idle animation, tap reaction animation, compact composer, and speech bubble timeout.

- [ ] **Step 4: Run frontend tests and build**

Run:

```bash
npm test -- --run
npm run build
```

Expected: tests and build pass.

- [ ] **Step 5: Commit**

```bash
git add src package.json package-lock.json
git commit -m "feature : 캐릭터 UI와 말풍선 추가"
```

## Task 4: Configure Desktop Overlay Window

**Files:**
- Modify: `src-tauri/tauri.conf.json`
- Create: `src-tauri/src/platform.rs`
- Modify: `src-tauri/src/lib.rs`

- [ ] **Step 1: Configure transparent window**

Set the main Tauri window to transparent, undecorated, always on top, and initially sized for the buddy UI.

- [ ] **Step 2: Add platform setup**

Create `configure_main_window` that applies overlay-related behavior and returns `Result<(), tauri::Error>`.

- [ ] **Step 3: Run build checks**

Run:

```bash
npm run build
cargo test --manifest-path src-tauri/Cargo.toml
```

Expected: frontend and Rust checks pass.

- [ ] **Step 4: Commit**

```bash
git add src-tauri
git commit -m "feature : macOS 오버레이 창 설정"
```

## Task 5: Manual Verification

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add run instructions**

Document:

```bash
npm install
npm run tauri dev
```

- [ ] **Step 2: Start dev app**

Run:

```bash
npm run tauri dev
```

Expected: a small transparent buddy window opens on macOS.

- [ ] **Step 3: Verify behavior**

Click the character and send a short message. Expected: reaction animation plays, bubble appears, and no peer connection is required for local use.

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs : 실행 방법 추가"
```

## Self-Review

- Spec coverage: Tauri/Svelte shell, click reaction, short speech bubble, Rust event core, same-Wi-Fi UDP sync, and transparent overlay are covered.
- Placeholder scan: no unresolved implementation markers remain in this plan.
- Type consistency: frontend `BuddyEvent` names mirror Rust `BuddyEvent` variants and keep the future LAN transport boundary explicit.
