# Corner Todo Board Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a local-first shared TODO board that appears when My Buddy is docked into a screen corner.

**Architecture:** Add pure MyBuddyCore policies for TODO merge and corner docking. Extend native app state, persistence, UI, UDP, and relay client handling to exchange `todo_snapshot` messages. Extend the Cloudflare relay validator to forward snapshots without storing them.

**Tech Stack:** Swift 5.10, SwiftUI/AppKit, XCTest, TypeScript, Vitest, Cloudflare Workers Durable Objects.

---

## File Structure

- Create `native/Sources/MyBuddyCore/BuddyTodo.swift`: TODO models, input policy, and snapshot merge rules.
- Create `native/Sources/MyBuddyCore/BuddyCornerDockingPolicy.swift`: screen-corner detection.
- Create `native/Tests/MyBuddyCoreTests/BuddyTodoTests.swift`: TODO merge and input tests.
- Create `native/Tests/MyBuddyCoreTests/BuddyCornerDockingPolicyTests.swift`: docking threshold tests.
- Modify `native/Sources/MyBuddyApp/BuddyAppState.swift`: TODO state, local persistence, sync send/receive.
- Modify `native/Sources/MyBuddyApp/BuddyViews.swift`: corner TODO board UI and drag-end docking hook.
- Modify `native/Sources/MyBuddyApp/NetworkService.swift`: UDP `todo_snapshot` encode/decode.
- Modify `native/Sources/MyBuddyApp/CloudRelayService.swift`: relay `todo_snapshot` send/receive.
- Modify `relay/src/protocol.ts`: validate `todo_snapshot`.
- Modify relay tests: cover valid and invalid snapshots.
- Update `README.md` and `docs/qa/manual-smoke-test.md`: document corner TODO workflow.

## Tasks

### Task 1: Core TODO Sync Policy

- [ ] Write failing Swift tests for trimmed TODO input, latest-update merge, delete-wins merge, and update-after-delete restoration.
- [ ] Implement `BuddyTodoItem`, `BuddyTodoDeletionRecord`, `BuddyTodoSnapshot`, `BuddyTodoInputPolicy`, and `BuddyTodoSyncPolicy`.
- [ ] Run `cd native && swift test --filter BuddyTodoTests`.

### Task 2: Corner Docking Policy

- [ ] Write failing Swift tests for top-left, bottom-right, and non-docked positions.
- [ ] Implement `BuddyDockedCorner` and `BuddyCornerDockingPolicy`.
- [ ] Run `cd native && swift test --filter BuddyCornerDockingPolicyTests`.

### Task 3: Native App State And UI

- [ ] Add TODO state, add/toggle/delete handlers, and UserDefaults persistence keyed by active peer id.
- [ ] Add a compact corner TODO board to `BuddyRootView`.
- [ ] Call docking policy after character drag ends and resize the panel when the board opens or closes.
- [ ] Add source tests for visible delete affordance and author labels if needed.
- [ ] Run `cd native && swift test`.

### Task 4: LAN And Relay Sync

- [ ] Extend UDP wire messages with `todo_snapshot`.
- [ ] Extend CloudRelayService with `sendTodoSnapshot` and receive handling.
- [ ] Extend relay protocol validation with snapshot shape and size limits.
- [ ] Run `cd relay && npm test && npm run check`.

### Task 5: Documentation And Verification

- [ ] Update README and manual smoke test with shared TODO steps.
- [ ] Run `./scripts/qa_smoke.sh`.
- [ ] Rebuild and restart My Buddy using the repository restart rule.
