import Foundation
import MyBuddyCore

final class CloudRelayService {
    private let endpoint: BuddyRelayEndpoint
    private let deviceId: String
    private let displayName: String
    private let session: URLSession
    private var webSocketTask: URLSessionWebSocketTask?
    private var heartbeatTimer: Timer?
    private var reconnectTimer: Timer?
    private var reconnectAttempt = 0
    private var lastPairingCode: String?
    private var isUserDisconnecting = false
    private var connectionGeneration = 0

    var onEvent: ((BuddyNetworkEvent) -> Void)?
    var onStatusChange: ((String) -> Void)?
    var onError: ((String) -> Void)?

    init(endpoint: BuddyRelayEndpoint, deviceId: String, displayName: String) {
        self.endpoint = endpoint
        self.deviceId = deviceId
        self.displayName = displayName
        session = URLSession(configuration: .default)
    }

    func connect(pairingCode: String) {
        cancelTimers()
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        connectionGeneration += 1
        lastPairingCode = pairingCode
        isUserDisconnecting = false

        do {
            let url = try endpoint.roomURL(pairingCode: pairingCode)
            let task = session.webSocketTask(with: url)
            webSocketTask = task
            task.resume()
            onStatusChange?("Relay connecting")
            startHeartbeat()
            receiveNext(connectionGeneration: connectionGeneration)
        } catch {
            onError?("Relay pairing code is invalid")
        }
    }

    func disconnect() {
        isUserDisconnecting = true
        cancelTimers()
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        connectionGeneration += 1
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

    private func sendPing() {
        send([
            "type": "ping",
            "device_id": deviceId,
            "display_name": displayName,
            "sent_at": Date().timeIntervalSince1970,
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

    private func receiveNext(connectionGeneration: Int) {
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }
            guard connectionGeneration == self.connectionGeneration else {
                return
            }

            switch result {
            case .success(.string(let text)):
                self.handle(text)
                self.receiveNext(connectionGeneration: connectionGeneration)
            case .success:
                self.receiveNext(connectionGeneration: connectionGeneration)
            case .failure(let error):
                DispatchQueue.main.async {
                    self.handleDisconnect(
                        errorDescription: error.localizedDescription,
                        connectionGeneration: connectionGeneration
                    )
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
            case "ready":
                self.reconnectAttempt = 0
                self.sendHello()
                self.onStatusChange?("Relay connected")
            case "pong":
                self.onStatusChange?("Relay connected")
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
            case "error":
                self.onError?("Relay error: \(value["code"] as? String ?? "unknown")")
            default:
                break
            }
        }
    }

    private func startHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }

    private func handleDisconnect(errorDescription: String, connectionGeneration: Int) {
        guard connectionGeneration == self.connectionGeneration else {
            return
        }

        cancelTimers()
        webSocketTask = nil
        guard !isUserDisconnecting,
              let lastPairingCode
        else {
            onStatusChange?("Relay disconnected")
            return
        }

        let delay = BuddyRelayReconnectPolicy.delay(forAttempt: reconnectAttempt)
        reconnectAttempt += 1
        onError?("Relay disconnected: \(errorDescription)")
        onStatusChange?("Relay reconnecting in \(Int(delay))s")
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.connect(pairingCode: lastPairingCode)
        }
    }

    private func cancelTimers() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
}
