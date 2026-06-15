import AppKit
import Combine
import Foundation
import MyBuddyCore

final class BuddyAppState: ObservableObject {
    @Published private(set) var characterSize: CGFloat

    @Published var isChatOpen = false {
        didSet { requestStageResize() }
    }

    @Published var isSettingsOpen = false {
        didSet { requestStageResize() }
    }

    @Published var currentImage: NSImage
    @Published var speechText: String?
    @Published var peers: [BuddyPeer] = []
    @Published var networkError: String?
    @Published var relayPairingCode = ""
    @Published var relayStatus = "Relay not configured"
    @Published var relayHealthStatus = "Health not tested"
    @Published var chatDeliveryStatus: String?
    @Published var diagnosticsCopyStatus: String?
    @Published var dockedCorner: BuddyDockedCorner? {
        didSet { requestStageResize() }
    }
    @Published private(set) var todoSnapshot = BuddyTodoSnapshot.empty
    @Published var todoStatus: String?

    let displayName: String
    var onStageSizeChange: ((CGSize) -> Void)?

    private static let characterSizeKey = "characterSize"
    private static let deviceIdKey = "deviceId"
    private static let relayPairingCodeKey = "relayPairingCode"
    private static let todoSnapshotKeyPrefix = "todoSnapshot."
    private static let relayBaseURLString = "https://buddy-relay.ruccess0-0.workers.dev"
    private let deviceId: String
    private let animationFramesById: [String: [NSImage]]
    private let idleImage: NSImage
    private let networkService: NetworkService
    private let relayEndpoint: BuddyRelayEndpoint?
    private let cloudRelayService: CloudRelayService?
    private var randomNumberGenerator = SystemRandomNumberGenerator()
    private var animationTimer: Timer?
    private var speechTimer: Timer?
    private var chatStatusTimer: Timer?
    private var diagnosticsStatusTimer: Timer?
    private var todoStatusTimer: Timer?
    private var peerPruneTimer: Timer?
    private var activeTodoPeerId: String?

    init() {
        idleImage = BuddyAssets.idleImage()
        animationFramesById = BuddyAssets.animationFramesById()
        currentImage = idleImage
        displayName = Host.current().localizedName ?? "Buddy"

        let storedDeviceId = UserDefaults.standard.string(forKey: Self.deviceIdKey)
        let deviceId = storedDeviceId ?? UUID().uuidString
        if storedDeviceId == nil {
            UserDefaults.standard.set(deviceId, forKey: Self.deviceIdKey)
        }
        self.deviceId = deviceId

        let storedSize = UserDefaults.standard.double(forKey: Self.characterSizeKey)
        characterSize = BuddyGeometry.clampedCharacterSize(
            storedSize > 0 ? storedSize : BuddyGeometry.defaultCharacterSize
        )
        networkService = NetworkService(deviceId: deviceId, displayName: displayName)
        relayPairingCode = UserDefaults.standard.string(forKey: Self.relayPairingCodeKey) ?? ""
        if let relayBaseURL = URL(string: Self.relayBaseURLString), !Self.relayBaseURLString.isEmpty {
            let endpoint = BuddyRelayEndpoint(baseURL: relayBaseURL)
            relayEndpoint = endpoint
            cloudRelayService = CloudRelayService(
                endpoint: endpoint,
                deviceId: deviceId,
                displayName: displayName
            )
            relayStatus = "Relay disconnected"
        } else {
            relayEndpoint = nil
            cloudRelayService = nil
        }
        todoSnapshot = loadTodoSnapshot(for: todoStoragePeerId)
        connectNetworkEvents()
    }

    var stageSize: CGSize {
        BuddyGeometry.stageSize(
            characterSize: characterSize,
            chatOpen: isChatOpen,
            settingsOpen: isSettingsOpen,
            todoBoardOpen: isTodoBoardOpen
        )
    }

    var characterAnchorOffset: CGPoint {
        BuddyGeometry.characterAnchorOffset(
            characterSize: characterSize,
            chatOpen: isChatOpen,
            settingsOpen: isSettingsOpen,
            todoBoardOpen: isTodoBoardOpen
        )
    }

    var isTodoBoardOpen: Bool {
        dockedCorner != nil && !isSettingsOpen && !isChatOpen
    }

    var todoItems: [BuddyTodoItem] {
        todoSnapshot.items
    }

    var todoCountLabel: String {
        let remainingCount = todoSnapshot.items.filter { !$0.isDone }.count
        return "\(remainingCount) left"
    }

    var connectionLabel: String {
        if peers.isEmpty {
            return "Wi-Fi peer not found"
        }

        if peers.count == 1, let peer = peers.first {
            return "Connected nearby: \(peer.displayName)"
        }

        return "\(peers.count) nearby buddies"
    }

    var settingsConnectionLabel: String {
        if peers.count == 1 {
            return "상대 연결됨"
        }

        if peers.count > 1 {
            return "\(peers.count)명 연결됨"
        }

        if networkError != nil {
            return "연결 실패"
        }

        if relayStatus == "Relay connected" {
            return "상대 기다리는 중"
        }

        if relayStatus == "Relay connecting" {
            return "연결 중"
        }

        if relayStatus.hasPrefix("Relay reconnecting") {
            return "재연결 중"
        }

        return "친구 연결 안 됨"
    }

    func start() {
        networkService.start()
        if !relayPairingCode.isEmpty {
            connectRelay()
        }
        peerPruneTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.prunePeers()
        }
    }

    func stop() {
        animationTimer?.invalidate()
        speechTimer?.invalidate()
        chatStatusTimer?.invalidate()
        diagnosticsStatusTimer?.invalidate()
        todoStatusTimer?.invalidate()
        peerPruneTimer?.invalidate()
        networkService.stop()
        cloudRelayService?.disconnect()
    }

    func handleCharacterPrimaryClick(action: BuddyCharacterClickAction) {
        isSettingsOpen = false

        switch action {
        case .react:
            let animation = BuddyAnimationPlan.randomReactionAnimation(
                using: &randomNumberGenerator
            )
            sendReaction(animationId: animation.id)
        case .openChat:
            isChatOpen = true
        }
    }

    func toggleSettings() {
        isSettingsOpen.toggle()
        if isSettingsOpen {
            isChatOpen = false
            dockedCorner = nil
        }
    }

    func updateDocking(windowFrame: CGRect, visibleFrame: CGRect?) {
        guard let visibleFrame else {
            dockedCorner = nil
            return
        }

        dockedCorner = BuddyCornerDockingPolicy.dockedCorner(
            windowFrame: windowFrame,
            visibleFrame: visibleFrame
        )
        if dockedCorner != nil {
            isChatOpen = false
            isSettingsOpen = false
        }
    }

    @discardableResult
    func addTodo(_ text: String) -> Bool {
        guard let preparedText = BuddyTodoInputPolicy.preparedText(text) else {
            setTemporaryTodoStatus("Keep TODOs under \(BuddyTodoInputPolicy.maximumTextLength) characters")
            return false
        }

        let now = Date().timeIntervalSince1970
        let item = BuddyTodoItem(
            id: UUID().uuidString,
            text: preparedText,
            isDone: false,
            createdAt: now,
            createdByDeviceId: deviceId,
            updatedAt: now,
            updatedByDeviceId: deviceId
        )
        todoSnapshot.items.append(item)
        todoSnapshot.items.sort { $0.createdAt < $1.createdAt }
        persistTodoSnapshot()
        sendTodoSnapshot()
        setTemporaryTodoStatus("TODO added")
        return true
    }

    func toggleTodo(id: String) {
        guard let index = todoSnapshot.items.firstIndex(where: { $0.id == id }) else {
            return
        }

        todoSnapshot.items[index].isDone.toggle()
        todoSnapshot.items[index].updatedAt = Date().timeIntervalSince1970
        todoSnapshot.items[index].updatedByDeviceId = deviceId
        persistTodoSnapshot()
        sendTodoSnapshot()
    }

    func deleteTodo(id: String) {
        guard todoSnapshot.items.contains(where: { $0.id == id }) else {
            return
        }

        todoSnapshot.items.removeAll { $0.id == id }
        let deletion = BuddyTodoDeletionRecord(
            id: id,
            deletedAt: Date().timeIntervalSince1970,
            deletedByDeviceId: deviceId
        )
        todoSnapshot.deletions.removeAll { $0.id == id }
        todoSnapshot.deletions.append(deletion)
        persistTodoSnapshot()
        sendTodoSnapshot()
        setTemporaryTodoStatus("TODO deleted")
    }

    func todoAuthorLabel(for item: BuddyTodoItem) -> String {
        item.createdByDeviceId == deviceId ? "me" : "buddy"
    }

    func adjustCharacterSize(stepCount: Int) {
        setCharacterSize(BuddyCharacterSizing.adjustedSize(
            from: characterSize,
            stepCount: stepCount
        ))
    }

    func setCharacterSizePreset(id: String) {
        guard let preset = BuddyCharacterSizing.preset(id: id) else {
            return
        }

        setCharacterSize(preset.size)
    }

    func resetSize() {
        setCharacterSize(BuddyGeometry.defaultCharacterSize)
    }

    func setCharacterSize(_ rawSize: CGFloat) {
        let clampedSize = BuddyGeometry.clampedCharacterSize(rawSize)
        guard characterSize != clampedSize else {
            return
        }

        characterSize = clampedSize
        UserDefaults.standard.set(Double(clampedSize), forKey: Self.characterSizeKey)
        requestStageResize()
    }

    func createRelayRoom() {
        var generator = SystemRandomNumberGenerator()
        relayPairingCode = BuddyRelayPairingCode.randomCode(using: &generator)
        copyRelayPairingCodeToPasteboard()
        connectRelay()
    }

    func copyRelayPairingCodeToPasteboard() {
        let code = relayPairingCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard BuddyRelayPairingCode.isValid(code) else {
            networkError = "Relay code must be \(BuddyRelayPairingCode.length) uppercase characters"
            return
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        networkError = nil
    }

    func sendReaction(animationId: String) {
        playReaction(animationId: animationId)
        networkService.sendReaction(animationId: animationId)
        cloudRelayService?.sendReaction(animationId: animationId)
    }

    @discardableResult
    func sendChat(_ text: String) -> Bool {
        guard let trimmedText = BuddyChatMessagePolicy.preparedText(text) else {
            setTemporaryChatStatus("Keep messages under \(BuddyChatMessagePolicy.maximumTextLength) characters")
            return false
        }

        let presentation = BuddyChatSendPolicy.localSentMessagePresentation
        if presentation.showsLocalSpeechBubble {
            showSpeech(trimmedText)
        }
        if !presentation.keepsComposerOpen {
            isChatOpen = false
        }
        networkService.sendChat(text: trimmedText)
        cloudRelayService?.sendChat(text: trimmedText)
        setTemporaryChatStatus("Sent")
        return true
    }

    func connectRelay() {
        guard let cloudRelayService else {
            relayStatus = "Relay not configured"
            return
        }

        let code = relayPairingCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard BuddyRelayPairingCode.isValid(code) else {
            networkError = "Relay code must be \(BuddyRelayPairingCode.length) uppercase characters"
            return
        }

        relayPairingCode = code
        UserDefaults.standard.set(code, forKey: Self.relayPairingCodeKey)
        networkError = nil
        cloudRelayService.connect(pairingCode: code)
    }

    func disconnectRelay() {
        cloudRelayService?.disconnect()
    }

    func testRelayHealth() {
        guard let relayEndpoint,
              let healthURL = try? relayEndpoint.healthURL()
        else {
            relayHealthStatus = "Health URL unavailable"
            return
        }

        relayHealthStatus = "Testing relay..."
        URLSession.shared.dataTask(with: healthURL) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error {
                    self?.relayHealthStatus = "Health failed: \(error.localizedDescription)"
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.relayHealthStatus = "Health failed: no HTTP response"
                    return
                }

                guard httpResponse.statusCode == 200,
                      let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      json["ok"] as? Bool == true
                else {
                    self?.relayHealthStatus = "Health failed: HTTP \(httpResponse.statusCode)"
                    return
                }

                self?.relayHealthStatus = "Health OK"
            }
        }.resume()
    }

    func copyDiagnosticsToPasteboard() {
        let relayCode = BuddyRelayPairingCode.isValid(relayPairingCode)
            ? relayPairingCode
            : "not set"
        let report = BuddyDiagnosticsReport(items: [
            BuddyDiagnosticsItem(label: "App", value: "My Buddy"),
            BuddyDiagnosticsItem(label: "Bundle", value: Bundle.main.bundleIdentifier ?? "unknown"),
            BuddyDiagnosticsItem(label: "Character size", value: "\(Int(characterSize))px"),
            BuddyDiagnosticsItem(label: "LAN peers", value: "\(peers.count)"),
            BuddyDiagnosticsItem(label: "Relay", value: relayStatus),
            BuddyDiagnosticsItem(label: "Relay health", value: relayHealthStatus),
            BuddyDiagnosticsItem(label: "Relay code", value: relayCode),
            BuddyDiagnosticsItem(label: "Last error", value: networkError ?? "none"),
            BuddyDiagnosticsItem(label: "Worker", value: Self.relayBaseURLString)
        ])

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(report.text, forType: .string)
        setTemporaryDiagnosticsStatus("Diagnostics copied")
    }

    private func connectNetworkEvents() {
        networkService.onEvent = { [weak self] event in
            self?.applyNetworkEvent(event)
        }

        networkService.onError = { [weak self] message in
            self?.networkError = message
        }

        cloudRelayService?.onEvent = { [weak self] event in
            self?.applyNetworkEvent(event)
        }

        cloudRelayService?.onStatusChange = { [weak self] status in
            self?.relayStatus = status
            if status == "Relay connected" {
                self?.networkError = nil
            }
        }

        cloudRelayService?.onError = { [weak self] message in
            self?.networkError = message
        }
    }

    private func applyNetworkEvent(_ event: BuddyNetworkEvent) {
        switch event {
        case .reaction(let animationId):
            playReaction(animationId: animationId)
        case .chat(let text):
            showSpeech(text)
        case .peer(let peer):
            upsertPeer(peer)
        case .todoSnapshot(let snapshot):
            mergeTodoSnapshot(snapshot)
        }
    }

    private func playReaction(animationId: String?) {
        if let animation = BuddyAnimationPlan.reactionAnimation(id: animationId) {
            playReaction(animation)
            return
        }

        let animation = BuddyAnimationPlan.randomReactionAnimation(
            using: &randomNumberGenerator
        )
        playReaction(animation)
    }

    private func playReaction(_ animation: BuddyReactionAnimation) {
        animationTimer?.invalidate()
        let frames = animationFramesById[animation.id] ?? []
        guard !frames.isEmpty else {
            currentImage = idleImage
            return
        }

        var index = 0
        currentImage = frames[index]
        animationTimer = Timer.scheduledTimer(
            withTimeInterval: animation.frameDuration,
            repeats: true
        ) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }

            index += 1
            if index >= frames.count {
                timer.invalidate()
                self.currentImage = self.idleImage
                self.animationTimer = nil
                return
            }

            self.currentImage = frames[index]
        }
    }

    private func showSpeech(_ text: String) {
        speechTimer?.invalidate()
        speechText = text
        speechTimer = Timer.scheduledTimer(withTimeInterval: 3.2, repeats: false) { [weak self] _ in
            self?.speechText = nil
        }
    }

    private func setTemporaryChatStatus(_ text: String) {
        chatStatusTimer?.invalidate()
        chatDeliveryStatus = text
        chatStatusTimer = Timer.scheduledTimer(withTimeInterval: 1.6, repeats: false) { [weak self] _ in
            self?.chatDeliveryStatus = nil
        }
    }

    private func setTemporaryDiagnosticsStatus(_ text: String) {
        diagnosticsStatusTimer?.invalidate()
        diagnosticsCopyStatus = text
        diagnosticsStatusTimer = Timer.scheduledTimer(withTimeInterval: 1.8, repeats: false) { [weak self] _ in
            self?.diagnosticsCopyStatus = nil
        }
    }

    private func setTemporaryTodoStatus(_ text: String) {
        todoStatusTimer?.invalidate()
        todoStatus = text
        todoStatusTimer = Timer.scheduledTimer(withTimeInterval: 1.6, repeats: false) { [weak self] _ in
            self?.todoStatus = nil
        }
    }

    private func upsertPeer(_ peer: BuddyPeer) {
        peers.removeAll { $0.id == peer.id }
        peers.append(peer)
        peers.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        networkError = nil
        activateTodoPeerIfNeeded(peer.id)
    }

    private func prunePeers() {
        let cutoff = Date().addingTimeInterval(-15)
        peers.removeAll { $0.lastSeen < cutoff }
    }

    private func requestStageResize() {
        DispatchQueue.main.async {
            self.onStageSizeChange?(self.stageSize)
        }
    }

    private var todoStoragePeerId: String {
        activeTodoPeerId ?? "local"
    }

    private func todoStorageKey(for peerId: String) -> String {
        "\(Self.todoSnapshotKeyPrefix)\(peerId)"
    }

    private func loadTodoSnapshot(for peerId: String) -> BuddyTodoSnapshot {
        guard let data = UserDefaults.standard.data(forKey: todoStorageKey(for: peerId)),
              let snapshot = try? JSONDecoder().decode(BuddyTodoSnapshot.self, from: data)
        else {
            return .empty
        }

        return snapshot
    }

    private func persistTodoSnapshot() {
        guard let data = try? JSONEncoder().encode(todoSnapshot) else {
            return
        }

        UserDefaults.standard.set(data, forKey: todoStorageKey(for: todoStoragePeerId))
    }

    private func activateTodoPeerIfNeeded(_ peerId: String) {
        guard activeTodoPeerId == nil else {
            return
        }

        activeTodoPeerId = peerId
        let storedSnapshot = loadTodoSnapshot(for: peerId)
        todoSnapshot = BuddyTodoSyncPolicy.merged(
            local: todoSnapshot,
            remote: storedSnapshot
        )
        persistTodoSnapshot()
        sendTodoSnapshot()
    }

    private func mergeTodoSnapshot(_ snapshot: BuddyTodoSnapshot) {
        let mergedSnapshot = BuddyTodoSyncPolicy.merged(
            local: todoSnapshot,
            remote: snapshot
        )
        if mergedSnapshot == todoSnapshot {
            if snapshot != todoSnapshot {
                sendTodoSnapshot()
            }
            return
        }

        todoSnapshot = mergedSnapshot
        persistTodoSnapshot()
        sendTodoSnapshot()
        setTemporaryTodoStatus("TODO synced")
    }

    private func sendTodoSnapshot() {
        networkService.sendTodoSnapshot(todoSnapshot)
        cloudRelayService?.sendTodoSnapshot(todoSnapshot)
    }
}
