import Darwin
import Foundation
import MyBuddyCore

struct BuddyPeer: Identifiable, Equatable {
    let id: String
    let displayName: String
    let address: String
    let lastSeen: Date
}

enum BuddyNetworkEvent {
    case reaction(animationId: String?)
    case chat(text: String)
    case peer(BuddyPeer)
    case todoSnapshot(BuddyTodoSnapshot)
}

private struct BuddyWireMessage: Codable {
    let messageId: String?
    let type: String
    let deviceId: String
    let displayName: String?
    let reactionId: String?
    let text: String?
    let todoSnapshot: BuddyTodoSnapshot?
    let sentAt: String?

    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case type
        case deviceId = "device_id"
        case displayName = "display_name"
        case reactionId = "reaction_id"
        case text
        case todoSnapshot = "todo_snapshot"
        case sentAt = "sent_at"
    }
}

final class NetworkService {
    private let port: UInt16 = 49_277
    private let deviceId: String
    private let displayName: String
    private let controlQueue = DispatchQueue(label: "com.mybuddy.network.control", qos: .utility)
    private let receiveQueue = DispatchQueue(label: "com.mybuddy.network.receive", qos: .utility)
    private var socketDescriptor: Int32 = -1
    private var isRunning = false
    private var helloTimer: DispatchSourceTimer?
    private var peerAddressesByDeviceId: [String: String] = [:]
    private var seenMessageIds: [String: Date] = [:]
    private let seenMessageTTL: TimeInterval = 60

    var onEvent: ((BuddyNetworkEvent) -> Void)?
    var onError: ((String) -> Void)?

    init(deviceId: String, displayName: String) {
        self.deviceId = deviceId
        self.displayName = displayName
    }

    func start() {
        controlQueue.async {
            guard !self.isRunning else { return }
            self.isRunning = true
            self.openSocket()
            guard self.socketDescriptor >= 0 else {
                self.isRunning = false
                return
            }

            self.startHelloTimer()
            self.receiveQueue.async {
                self.receiveLoop()
            }
        }
    }

    func stop() {
        controlQueue.async {
            self.isRunning = false
            self.helloTimer?.cancel()
            self.helloTimer = nil

            if self.socketDescriptor >= 0 {
                close(self.socketDescriptor)
                self.socketDescriptor = -1
            }
        }
    }

    func sendReaction(animationId: String) {
        send(type: "reaction", reactionId: animationId, text: nil)
    }

    func sendChat(text: String) {
        send(type: "chat_message", reactionId: nil, text: text)
    }

    func sendTodoSnapshot(_ snapshot: BuddyTodoSnapshot) {
        send(type: "todo_snapshot", reactionId: nil, text: nil, todoSnapshot: snapshot)
    }

    private func openSocket() {
        let descriptor = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        guard descriptor >= 0 else {
            reportError("UDP socket creation failed")
            return
        }

        var enabled: Int32 = 1
        setsockopt(
            descriptor,
            SOL_SOCKET,
            SO_REUSEADDR,
            &enabled,
            socklen_t(MemoryLayout<Int32>.size)
        )
        setsockopt(
            descriptor,
            SOL_SOCKET,
            SO_BROADCAST,
            &enabled,
            socklen_t(MemoryLayout<Int32>.size)
        )

        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = port.bigEndian
        address.sin_addr = in_addr(s_addr: INADDR_ANY)

        let bindResult = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { rebound in
                bind(descriptor, rebound, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        guard bindResult == 0 else {
            reportError("UDP bind failed on port \(port)")
            close(descriptor)
            return
        }

        socketDescriptor = descriptor
    }

    private func startHelloTimer() {
        let timer = DispatchSource.makeTimerSource(queue: controlQueue)
        timer.schedule(deadline: .now(), repeating: .seconds(4))
        timer.setEventHandler { [weak self] in
            self?.send(type: "hello", reactionId: nil, text: nil)
        }
        timer.resume()
        helloTimer = timer
    }

    private func receiveLoop() {
        var buffer = [UInt8](repeating: 0, count: 4096)

        while isRunningSnapshot() {
            var sender = sockaddr_in()
            var senderLength = socklen_t(MemoryLayout<sockaddr_in>.size)
            let byteCount = withUnsafeMutablePointer(to: &sender) { senderPointer in
                senderPointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { rebound in
                    recvfrom(
                        socketDescriptor,
                        &buffer,
                        buffer.count,
                        0,
                        rebound,
                        &senderLength
                    )
                }
            }

            guard byteCount > 0 else {
                continue
            }

            let data = Data(buffer.prefix(Int(byteCount)))
            handleIncoming(data: data, sender: sender)
        }
    }

    private func isRunningSnapshot() -> Bool {
        controlQueue.sync {
            isRunning
        }
    }

    private func handleIncoming(data: Data, sender: sockaddr_in) {
        guard let message = try? JSONDecoder().decode(BuddyWireMessage.self, from: data),
              message.deviceId != deviceId
        else {
            return
        }
        guard markMessageIfNew(message.messageId) else { return }

        let address = senderAddress(sender)
        let peer = BuddyPeer(
            id: message.deviceId,
            displayName: message.displayName ?? "Nearby Buddy",
            address: address,
            lastSeen: Date()
        )
        rememberPeer(peer)

        DispatchQueue.main.async {
            self.onEvent?(.peer(peer))

            switch message.type {
            case "reaction":
                self.onEvent?(.reaction(animationId: message.reactionId))
            case "chat_message":
                if let text = message.text, !text.isEmpty {
                    self.onEvent?(.chat(text: text))
                }
            case "todo_snapshot":
                if let snapshot = message.todoSnapshot {
                    self.onEvent?(.todoSnapshot(snapshot))
                }
            default:
                break
            }
        }
    }

    private func send(
        type: String,
        reactionId: String?,
        text: String?,
        todoSnapshot: BuddyTodoSnapshot? = nil
    ) {
        controlQueue.async {
            guard self.socketDescriptor >= 0 else { return }

            let message = BuddyWireMessage(
                messageId: UUID().uuidString,
                type: type,
                deviceId: self.deviceId,
                displayName: self.displayName,
                reactionId: reactionId,
                text: text,
                todoSnapshot: todoSnapshot,
                sentAt: "\(Date().timeIntervalSince1970)"
            )

            guard let data = try? JSONEncoder().encode(message) else {
                return
            }

            let destinations = BuddyNetworkRouting.destinationAddresses(
                knownPeerAddresses: Array(self.peerAddressesByDeviceId.values)
            )

            for destination in destinations {
                self.send(data: data, to: destination)
            }
        }
    }

    private func send(data: Data, to addressString: String) {
        var destinationAddress = in_addr()
        guard inet_pton(AF_INET, addressString, &destinationAddress) == 1 else { return }

        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = port.bigEndian
        address.sin_addr = destinationAddress

        data.withUnsafeBytes { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            withUnsafePointer(to: &address) { pointer in
                pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { rebound in
                    _ = sendto(
                        socketDescriptor,
                        baseAddress,
                        data.count,
                        0,
                        rebound,
                        socklen_t(MemoryLayout<sockaddr_in>.size)
                    )
                }
            }
        }
    }

    private func rememberPeer(_ peer: BuddyPeer) {
        controlQueue.async {
            self.peerAddressesByDeviceId[peer.id] = peer.address
        }
    }

    private func markMessageIfNew(_ messageId: String?) -> Bool {
        guard let messageId else { return true }

        return controlQueue.sync {
            let now = Date()
            let expiredMessageIds = self.seenMessageIds.compactMap { id, seenAt in
                now.timeIntervalSince(seenAt) >= self.seenMessageTTL ? id : nil
            }

            for expiredMessageId in expiredMessageIds {
                self.seenMessageIds.removeValue(forKey: expiredMessageId)
            }

            guard self.seenMessageIds[messageId] == nil else { return false }
            self.seenMessageIds[messageId] = now
            return true
        }
    }

    private func reportError(_ message: String) {
        DispatchQueue.main.async {
            self.onError?(message)
        }
    }

    private func senderAddress(_ sender: sockaddr_in) -> String {
        var address = sender.sin_addr
        var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        inet_ntop(AF_INET, &address, &buffer, socklen_t(INET_ADDRSTRLEN))
        return String(cString: buffer)
    }
}
