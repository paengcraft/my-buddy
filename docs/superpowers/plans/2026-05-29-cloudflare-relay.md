# Cloudflare Relay Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add internet relay support so two My Buddy apps can exchange reactions and chat messages outside the same Wi-Fi network while keeping same-Wi-Fi UDP as a fallback.

**Architecture:** A Cloudflare Worker routes WebSocket upgrade requests to one Durable Object per pairing room. The Durable Object keeps only active sockets in memory, uses WebSocket Hibernation, broadcasts small ephemeral events to other sockets in the same room, and does not use D1, R2, KV, Queues, AI, Pages, Containers, Email, or paid domains. The macOS app keeps the existing UDP `NetworkService` and adds a relay client that emits the same `BuddyNetworkEvent` values into `BuddyAppState`.

**Tech Stack:** Cloudflare Workers, Durable Objects with SQLite storage backend, WebSocket Hibernation API, Wrangler, Swift 5.10, SwiftUI/AppKit, XCTest.

---

## Billing Guardrails

- Use only Workers and Durable Objects.
- Do not use AI, Workers AI, AI Search, D1, R2, KV, Queues, Pipelines, Pages, Containers, Email, Browser Rendering, Stream, Images, domain registration, paid routes, or SSL certificate ordering.
- Use Durable Objects with the SQLite storage backend because Cloudflare documents that the Workers Free plan supports only SQLite-backed Durable Objects for new namespaces.
- Use the Durable Object WebSocket Hibernation API because Cloudflare documents it as the recommended approach for WebSocket server apps to reduce duration charge.
- Do not store chat history or reactions. Keep active sockets and pairing state only.
- Keep per-room limits small: maximum 2 active app sockets per room for MVP, maximum message size 2048 bytes, maximum 20 client messages per 10 seconds per socket.
- Deployment command must be limited to `npx wrangler deploy --config relay/wrangler.toml`.
- Before deploying, run `npx wrangler deploy --config relay/wrangler.toml --dry-run` and inspect that only the `buddy-relay` Worker and `PAIRING_ROOM` Durable Object binding are included.

Official references used for this plan:
- Cloudflare Durable Objects WebSocket Hibernation example: https://developers.cloudflare.com/durable-objects/examples/websocket-hibernation-server/
- Cloudflare Durable Objects migrations: https://developers.cloudflare.com/durable-objects/reference/durable-objects-migrations/
- Cloudflare Wrangler configuration: https://developers.cloudflare.com/workers/wrangler/configuration/

## File Structure

- Create `relay/package.json`: scripts for local relay tests, local dev, dry-run deploy, and deploy.
- Create `relay/wrangler.toml`: Worker name, compatibility date, Durable Object binding, and migration.
- Create `relay/src/index.ts`: Worker entrypoint plus `PairingRoom` Durable Object.
- Create `relay/test/relay.test.ts`: local relay protocol tests using pure protocol helpers where possible.
- Create `relay/tsconfig.json`: TypeScript compiler configuration for the Worker.
- Create `native/Sources/MyBuddyCore/BuddyRelayMessage.swift`: shared relay message model and validation policy.
- Create `native/Tests/MyBuddyCoreTests/BuddyRelayMessageTests.swift`: Swift relay message validation tests.
- Create `native/Sources/MyBuddyApp/CloudRelayService.swift`: URLSession WebSocket relay client.
- Modify `native/Sources/MyBuddyApp/BuddyAppState.swift`: start/stop relay client and fan relay events into the existing state.
- Modify `native/Sources/MyBuddyApp/BuddyViews.swift`: add compact pairing/status controls in the settings panel.
- Modify `native/Package.swift`: no third-party Swift dependencies; ensure new files are picked up automatically.
- Modify `README.md`: add Cloudflare relay setup and free-plan guardrails.

## Relay Protocol

Room creation and joining use a user-visible six-character pairing code. Codes use uppercase base32 characters excluding ambiguous letters: `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`.

Client-to-server messages:

```json
{ "type": "hello", "device_id": "uuid", "display_name": "MacBook" }
```

```json
{ "type": "reaction", "message_id": "uuid", "device_id": "uuid", "display_name": "MacBook", "reaction_id": "quick-pop", "sent_at": 1770000000 }
```

```json
{ "type": "chat_message", "message_id": "uuid", "device_id": "uuid", "display_name": "MacBook", "text": "hello", "sent_at": 1770000000 }
```

Server-to-client messages:

```json
{ "type": "peer", "device_id": "uuid", "display_name": "MacBook" }
```

```json
{ "type": "reaction", "message_id": "uuid", "device_id": "uuid", "display_name": "MacBook", "reaction_id": "quick-pop", "sent_at": 1770000000 }
```

```json
{ "type": "chat_message", "message_id": "uuid", "device_id": "uuid", "display_name": "MacBook", "text": "hello", "sent_at": 1770000000 }
```

Close/error messages use short machine-readable reasons:

```json
{ "type": "error", "code": "room_full" }
```

## Task 1: Add Relay Worker Scaffold

**Files:**
- Create: `relay/package.json`
- Create: `relay/tsconfig.json`
- Create: `relay/wrangler.toml`
- Create: `relay/src/index.ts`

- [ ] **Step 1: Create Worker package scripts**

Create `relay/package.json`:

```json
{
  "name": "buddy-relay",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "check": "tsc --noEmit",
    "dev": "wrangler dev --config wrangler.toml",
    "deploy:dry-run": "wrangler deploy --config wrangler.toml --dry-run",
    "deploy": "wrangler deploy --config wrangler.toml"
  },
  "devDependencies": {
    "@cloudflare/workers-types": "^4.20260529.0",
    "typescript": "^5.6.2",
    "wrangler": "^4.95.0"
  }
}
```

- [ ] **Step 2: Create TypeScript config**

Create `relay/tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "lib": ["ES2022"],
    "types": ["@cloudflare/workers-types"],
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "skipLibCheck": true
  },
  "include": ["src/**/*.ts"]
}
```

- [ ] **Step 3: Create free-plan Worker config**

Create `relay/wrangler.toml`:

```toml
name = "buddy-relay"
main = "src/index.ts"
compatibility_date = "2026-05-29"

[[durable_objects.bindings]]
name = "PAIRING_ROOM"
class_name = "PairingRoom"

[[migrations]]
tag = "v1"
new_sqlite_classes = ["PairingRoom"]
```

- [ ] **Step 4: Create minimal Worker entrypoint**

Create `relay/src/index.ts`:

```ts
import { DurableObject } from "cloudflare:workers";

export interface Env {
  PAIRING_ROOM: DurableObjectNamespace<PairingRoom>;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (url.pathname === "/health") {
      return Response.json({ ok: true });
    }

    const match = url.pathname.match(/^\/room\/([A-Z2-9]{6})$/);
    if (!match) {
      return new Response("Not found", { status: 404 });
    }

    if (request.headers.get("Upgrade") !== "websocket") {
      return new Response("Expected WebSocket", { status: 426 });
    }

    const roomCode = match[1];
    const id = env.PAIRING_ROOM.idFromName(roomCode);
    const room = env.PAIRING_ROOM.get(id);
    return room.fetch(request);
  },
};

export class PairingRoom extends DurableObject<Env> {
  async fetch(request: Request): Promise<Response> {
    const pair = new WebSocketPair();
    const [client, server] = Object.values(pair);
    this.ctx.acceptWebSocket(server);
    server.send(JSON.stringify({ type: "ready" }));
    return new Response(null, { status: 101, webSocket: client });
  }

  async webSocketMessage(socket: WebSocket, message: string | ArrayBuffer): Promise<void> {
    socket.send(typeof message === "string" ? message : "");
  }
}
```

- [ ] **Step 5: Verify TypeScript compile**

Run:

```bash
cd relay
npm install
npm run check
```

Expected: `tsc --noEmit` exits `0`.

- [ ] **Step 6: Verify Cloudflare dry run only**

Run:

```bash
cd relay
npm run deploy:dry-run
```

Expected: Wrangler reports a dry run for Worker `buddy-relay` and does not create AI, D1, R2, KV, Queues, Pages, Containers, Email, Images, Stream, or custom domain resources.

## Task 2: Implement Relay Room Protocol

**Files:**
- Modify: `relay/src/index.ts`

- [ ] **Step 1: Replace echo room with room state and validation**

Replace `PairingRoom` in `relay/src/index.ts` with:

```ts
type ClientMeta = {
  deviceId: string;
  displayName: string;
  messageTimestamps: number[];
};

type RelayMessage =
  | { type: "hello"; device_id: string; display_name: string }
  | {
      type: "reaction";
      message_id: string;
      device_id: string;
      display_name: string;
      reaction_id: string;
      sent_at: number;
    }
  | {
      type: "chat_message";
      message_id: string;
      device_id: string;
      display_name: string;
      text: string;
      sent_at: number;
    };

const maximumSocketsPerRoom = 2;
const maximumMessageBytes = 2048;
const maximumMessagesPerWindow = 20;
const rateWindowMs = 10_000;

function parseRelayMessage(message: string | ArrayBuffer): RelayMessage | null {
  if (typeof message !== "string") {
    return null;
  }
  if (new TextEncoder().encode(message).byteLength > maximumMessageBytes) {
    return null;
  }

  const value: unknown = JSON.parse(message);
  if (!value || typeof value !== "object") {
    return null;
  }

  const record = value as Record<string, unknown>;
  if (record.type === "hello") {
    if (typeof record.device_id !== "string" || typeof record.display_name !== "string") {
      return null;
    }
    return {
      type: "hello",
      device_id: record.device_id,
      display_name: record.display_name,
    };
  }

  if (record.type === "reaction") {
    if (
      typeof record.message_id !== "string" ||
      typeof record.device_id !== "string" ||
      typeof record.display_name !== "string" ||
      typeof record.reaction_id !== "string" ||
      typeof record.sent_at !== "number"
    ) {
      return null;
    }
    return {
      type: "reaction",
      message_id: record.message_id,
      device_id: record.device_id,
      display_name: record.display_name,
      reaction_id: record.reaction_id,
      sent_at: record.sent_at,
    };
  }

  if (record.type === "chat_message") {
    if (
      typeof record.message_id !== "string" ||
      typeof record.device_id !== "string" ||
      typeof record.display_name !== "string" ||
      typeof record.text !== "string" ||
      typeof record.sent_at !== "number" ||
      record.text.trim().length === 0 ||
      record.text.length > 280
    ) {
      return null;
    }
    return {
      type: "chat_message",
      message_id: record.message_id,
      device_id: record.device_id,
      display_name: record.display_name,
      text: record.text,
      sent_at: record.sent_at,
    };
  }

  return null;
}

export class PairingRoom extends DurableObject<Env> {
  private readonly clients = new Map<WebSocket, ClientMeta>();

  async fetch(request: Request): Promise<Response> {
    if (this.ctx.getWebSockets().length >= maximumSocketsPerRoom) {
      return Response.json({ type: "error", code: "room_full" }, { status: 409 });
    }

    const pair = new WebSocketPair();
    const [client, server] = Object.values(pair);
    this.ctx.acceptWebSocket(server);
    this.clients.set(server, {
      deviceId: "",
      displayName: "Nearby Buddy",
      messageTimestamps: [],
    });
    server.send(JSON.stringify({ type: "ready" }));
    return new Response(null, { status: 101, webSocket: client });
  }

  async webSocketMessage(socket: WebSocket, message: string | ArrayBuffer): Promise<void> {
    const client = this.clients.get(socket);
    if (!client || !this.allowMessage(client)) {
      socket.send(JSON.stringify({ type: "error", code: "rate_limited" }));
      return;
    }

    const parsed = parseRelayMessage(message);
    if (!parsed) {
      socket.send(JSON.stringify({ type: "error", code: "invalid_message" }));
      return;
    }

    client.deviceId = parsed.device_id;
    client.displayName = parsed.display_name;

    if (parsed.type === "hello") {
      this.broadcast(socket, {
        type: "peer",
        device_id: parsed.device_id,
        display_name: parsed.display_name,
      });
      return;
    }

    this.broadcast(socket, parsed);
  }

  async webSocketClose(socket: WebSocket): Promise<void> {
    this.clients.delete(socket);
  }

  async webSocketError(socket: WebSocket): Promise<void> {
    this.clients.delete(socket);
  }

  private allowMessage(client: ClientMeta): boolean {
    const now = Date.now();
    client.messageTimestamps = client.messageTimestamps.filter(
      (timestamp) => now - timestamp < rateWindowMs,
    );
    if (client.messageTimestamps.length >= maximumMessagesPerWindow) {
      return false;
    }
    client.messageTimestamps.push(now);
    return true;
  }

  private broadcast(sender: WebSocket, payload: unknown): void {
    const data = JSON.stringify(payload);
    for (const socket of this.ctx.getWebSockets()) {
      if (socket !== sender) {
        socket.send(data);
      }
    }
  }
}
```

- [ ] **Step 2: Run compile check**

Run:

```bash
cd relay
npm run check
```

Expected: `tsc --noEmit` exits `0`.

## Task 3: Add Swift Relay Message Model

**Files:**
- Create: `native/Sources/MyBuddyCore/BuddyRelayMessage.swift`
- Create: `native/Tests/MyBuddyCoreTests/BuddyRelayMessageTests.swift`

- [ ] **Step 1: Write failing Swift tests**

Create `native/Tests/MyBuddyCoreTests/BuddyRelayMessageTests.swift`:

```swift
import XCTest
@testable import MyBuddyCore

final class BuddyRelayMessageTests: XCTestCase {
    func testAcceptsValidPairingCode() {
        XCTAssertTrue(BuddyRelayPairingCode.isValid("ABCD23"))
    }

    func testRejectsInvalidPairingCode() {
        XCTAssertFalse(BuddyRelayPairingCode.isValid("ABC123"))
        XCTAssertFalse(BuddyRelayPairingCode.isValid("abcd23"))
        XCTAssertFalse(BuddyRelayPairingCode.isValid("ABCDEFG"))
    }

    func testBuildsRoomURL() throws {
        let url = try BuddyRelayEndpoint(
            baseURL: URL(string: "https://buddy-relay.example.workers.dev")!
        ).roomURL(pairingCode: "ABCD23")

        XCTAssertEqual(url.absoluteString, "wss://buddy-relay.example.workers.dev/room/ABCD23")
    }
}
```

- [ ] **Step 2: Run failing test**

Run:

```bash
cd native
swift test --filter BuddyRelayMessageTests
```

Expected: FAIL because `BuddyRelayPairingCode` and `BuddyRelayEndpoint` do not exist.

- [ ] **Step 3: Add relay model**

Create `native/Sources/MyBuddyCore/BuddyRelayMessage.swift`:

```swift
import Foundation

public enum BuddyRelayPairingCode {
    private static let pattern = /^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{6}$/

    public static func isValid(_ value: String) -> Bool {
        value.wholeMatch(of: pattern) != nil
    }
}

public struct BuddyRelayEndpoint {
    public let baseURL: URL

    public init(baseURL: URL) {
        self.baseURL = baseURL
    }

    public func roomURL(pairingCode: String) throws -> URL {
        guard BuddyRelayPairingCode.isValid(pairingCode) else {
            throw BuddyRelayEndpointError.invalidPairingCode
        }

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.scheme = "wss"
        components?.path = "/room/\(pairingCode)"

        guard let url = components?.url else {
            throw BuddyRelayEndpointError.invalidBaseURL
        }

        return url
    }
}

public enum BuddyRelayEndpointError: Error, Equatable {
    case invalidPairingCode
    case invalidBaseURL
}
```

- [ ] **Step 4: Run Swift tests**

Run:

```bash
cd native
swift test --filter BuddyRelayMessageTests
swift test
```

Expected: all tests pass.

## Task 4: Add Cloud Relay Service To App

**Files:**
- Create: `native/Sources/MyBuddyApp/CloudRelayService.swift`
- Modify: `native/Sources/MyBuddyApp/BuddyAppState.swift`

- [ ] **Step 1: Create relay client skeleton**

Create `native/Sources/MyBuddyApp/CloudRelayService.swift`:

```swift
import Foundation
import MyBuddyCore

final class CloudRelayService {
    private let endpoint: BuddyRelayEndpoint
    private let deviceId: String
    private let displayName: String
    private let session: URLSession
    private var webSocketTask: URLSessionWebSocketTask?
    private var pairingCode: String?

    var onEvent: ((BuddyNetworkEvent) -> Void)?
    var onStatusChange: ((String) -> Void)?
    var onError: ((String) -> Void)?

    init(endpoint: BuddyRelayEndpoint, deviceId: String, displayName: String) {
        self.endpoint = endpoint
        self.deviceId = deviceId
        self.displayName = displayName
        self.session = URLSession(configuration: .default)
    }

    func connect(pairingCode: String) {
        disconnect()
        self.pairingCode = pairingCode

        do {
            let url = try endpoint.roomURL(pairingCode: pairingCode)
            let task = session.webSocketTask(with: url)
            webSocketTask = task
            task.resume()
            onStatusChange?("Relay connecting")
            sendHello()
            receiveNext()
        } catch {
            onError?("Relay pairing code is invalid")
        }
    }

    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        onStatusChange?("Relay disconnected")
    }

    func sendReaction(animationId: String) {
        send([
            "type": "reaction",
            "message_id": UUID().uuidString,
            "device_id": deviceId,
            "display_name": displayName,
            "reaction_id": animationId,
            "sent_at": Date().timeIntervalSince1970,
        ])
    }

    func sendChat(text: String) {
        send([
            "type": "chat_message",
            "message_id": UUID().uuidString,
            "device_id": deviceId,
            "display_name": displayName,
            "text": text,
            "sent_at": Date().timeIntervalSince1970,
        ])
    }

    private func sendHello() {
        send([
            "type": "hello",
            "device_id": deviceId,
            "display_name": displayName,
        ])
    }

    private func send(_ payload: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let text = String(data: data, encoding: .utf8)
        else {
            return
        }

        webSocketTask?.send(.string(text)) { [weak self] error in
            if let error {
                DispatchQueue.main.async {
                    self?.onError?("Relay send failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private func receiveNext() {
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(.string(let text)):
                self.handle(text)
                self.receiveNext()
            case .success:
                self.receiveNext()
            case .failure(let error):
                DispatchQueue.main.async {
                    self.onError?("Relay disconnected: \(error.localizedDescription)")
                    self.onStatusChange?("Relay disconnected")
                }
            }
        }
    }

    private func handle(_ text: String) {
        guard let data = text.data(using: .utf8),
              let value = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = value["type"] as? String
        else {
            return
        }

        DispatchQueue.main.async {
            switch type {
            case "peer":
                if let deviceId = value["device_id"] as? String,
                   let displayName = value["display_name"] as? String {
                    self.onEvent?(.peer(BuddyPeer(
                        id: deviceId,
                        displayName: displayName,
                        address: "Cloud relay",
                        lastSeen: Date()
                    )))
                }
            case "reaction":
                self.onEvent?(.reaction(animationId: value["reaction_id"] as? String))
            case "chat_message":
                if let message = value["text"] as? String, !message.isEmpty {
                    self.onEvent?(.chat(text: message))
                }
            case "ready":
                self.onStatusChange?("Relay connected")
            case "error":
                self.onError?("Relay error: \(value["code"] as? String ?? "unknown")")
            default:
                break
            }
        }
    }
}
```

- [ ] **Step 2: Wire relay into app state**

Modify `native/Sources/MyBuddyApp/BuddyAppState.swift`:

```swift
private static let relayPairingCodeKey = "relayPairingCode"
private let cloudRelayService: CloudRelayService?
@Published var relayPairingCode = ""
@Published var relayStatus = "Relay disconnected"
```

In `init`, after `networkService = ...`, create:

```swift
let relayURL = URL(string: "https://buddy-relay.<replace-with-workers-subdomain>.workers.dev")!
cloudRelayService = CloudRelayService(
    endpoint: BuddyRelayEndpoint(baseURL: relayURL),
    deviceId: deviceId,
    displayName: displayName
)
relayPairingCode = UserDefaults.standard.string(forKey: Self.relayPairingCodeKey) ?? ""
```

Add:

```swift
func connectRelay() {
    let code = relayPairingCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    guard BuddyRelayPairingCode.isValid(code) else {
        networkError = "Relay code must be 6 uppercase characters"
        return
    }
    relayPairingCode = code
    UserDefaults.standard.set(code, forKey: Self.relayPairingCodeKey)
    cloudRelayService?.connect(pairingCode: code)
}

func disconnectRelay() {
    cloudRelayService?.disconnect()
}
```

In `start`, after `networkService.start()`:

```swift
connectRelay()
```

In `stop`, after `networkService.stop()`:

```swift
cloudRelayService?.disconnect()
```

In `sendChat`, after `networkService.sendChat(text: trimmedText)`:

```swift
cloudRelayService?.sendChat(text: trimmedText)
```

In `.react` click handling, after `networkService.sendReaction(animationId: animation.id)`:

```swift
cloudRelayService?.sendReaction(animationId: animation.id)
```

In `connectNetworkEvents`, also connect relay callbacks:

```swift
cloudRelayService?.onEvent = { [weak self] event in
    self?.applyNetworkEvent(event)
}
cloudRelayService?.onStatusChange = { [weak self] status in
    self?.relayStatus = status
}
cloudRelayService?.onError = { [weak self] message in
    self?.networkError = message
}
```

Extract the existing `switch event` body into:

```swift
private func applyNetworkEvent(_ event: BuddyNetworkEvent) {
    switch event {
    case .reaction(let animationId):
        playReaction(animationId: animationId)
    case .chat(let text):
        showSpeech(text)
    case .peer(let peer):
        upsertPeer(peer)
    }
}
```

- [ ] **Step 3: Build native app**

Run:

```bash
cd native
swift test
./scripts/build_app.sh
```

Expected: tests pass and `native/build/My Buddy.app` is created.

## Task 5: Add Pairing UI

**Files:**
- Modify: `native/Sources/MyBuddyApp/BuddyViews.swift`

- [ ] **Step 1: Add relay controls to settings panel**

In `SettingsPanel`, after the `Buddy` row, add:

```swift
HStack {
    Text("Relay")
    Spacer()
    Text(state.relayStatus)
        .fontWeight(.bold)
        .lineLimit(1)
}

HStack(spacing: 6) {
    TextField("Code", text: $state.relayPairingCode)
        .textFieldStyle(.roundedBorder)
        .frame(width: 92)
    Button("Connect") {
        state.connectRelay()
    }
    .buttonStyle(.bordered)
    .controlSize(.small)
}
```

- [ ] **Step 2: Run native build**

Run:

```bash
cd native
swift test
./scripts/build_app.sh
```

Expected: tests pass and the settings panel builds with relay status and pairing controls.

## Task 6: Deploy Relay Only After Dry-Run Review

**Files:**
- No source changes unless dry-run exposes a config issue.

- [ ] **Step 1: Confirm logged-in Cloudflare account**

Run:

```bash
npx wrangler whoami
```

Expected account:

```text
Ruccess0.0@gmail.com's Account
38ed5426695420744fb3f024c70a38e4
```

- [ ] **Step 2: Run dry-run deploy**

Run:

```bash
cd relay
npm run deploy:dry-run
```

Expected: dry-run output mentions Worker `buddy-relay`, Durable Object binding `PAIRING_ROOM`, migration `v1`, and no paid product resources.

- [ ] **Step 3: Ask for explicit deploy approval**

Do not deploy yet. Show dry-run output summary to the user and ask:

```text
Dry-run only shows the buddy-relay Worker and PAIRING_ROOM Durable Object. No AI, D1, R2, Queues, Pages, Containers, Email, domain, Images, or Stream resources are present. 배포 진행해도 될까요?
```

- [ ] **Step 4: Deploy after approval**

Only after approval, run:

```bash
cd relay
npm run deploy
```

Expected: Wrangler prints a `workers.dev` URL for `buddy-relay`.

## Task 7: Replace Placeholder Relay URL

**Files:**
- Modify: `native/Sources/MyBuddyApp/BuddyAppState.swift`

- [ ] **Step 1: Put deployed Worker URL into app**

Replace:

```swift
let relayURL = URL(string: "https://buddy-relay.<replace-with-workers-subdomain>.workers.dev")!
```

with the deployed URL:

```swift
let relayURL = URL(string: "https://buddy-relay.<actual-subdomain>.workers.dev")!
```

- [ ] **Step 2: Build app**

Run:

```bash
cd native
swift test
./scripts/build_app.sh
```

Expected: tests pass and DMG/app bundle are rebuilt.

## Task 8: Manual End-To-End Test

**Files:**
- No source changes unless a verified bug is found.

- [ ] **Step 1: Same Mac smoke test**

Run:

```bash
open -n "native/build/My Buddy.app"
```

Expected: app opens, settings panel shows relay controls.

- [ ] **Step 2: Two-device internet test**

On two different Macs:

```text
1. Install/open the same DMG.
2. Enter the same six-character pairing code.
3. Click Connect on both devices.
4. Send a chat message from Mac A.
5. Verify Mac B shows a speech bubble.
6. Single-click Mac A character.
7. Verify Mac B plays the reaction.
8. Repeat from Mac B to Mac A.
```

Expected: chat and reaction work even when the Macs are not on the same Wi-Fi, as long as both have internet access.

## Self-Review

- Spec coverage: The plan covers free-plan guardrails, Worker relay, Durable Object room routing, Swift relay URL validation, app relay client, pairing UI, dry-run before deploy, explicit deploy approval, and end-to-end testing.
- Placeholder scan: The only placeholder is the deployed Worker URL in Task 4 and Task 7, which cannot be known until approved deployment. The plan explicitly includes the replacement task.
- Type consistency: Relay event names match existing native event names: `reaction`, `chat_message`, and `peer`. Swift state continues using `BuddyNetworkEvent`.
- Scope: This is one feature slice: internet relay support. Login, friend lists, offline delivery, message history, push notifications, and custom domains are excluded.
