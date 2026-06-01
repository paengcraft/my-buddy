import AppKit
import MyBuddyCore
import SwiftUI

struct BuddyRootView: View {
    @ObservedObject var state: BuddyAppState

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 10) {
                if state.isSettingsOpen {
                    SettingsPanel(state: state)
                }

                Spacer(minLength: 0)

                ZStack(alignment: .top) {
                    if let speechText = state.speechText {
                        SpeechBubble(text: speechText)
                            .offset(y: -44)
                            .transition(.scale.combined(with: .opacity))
                    }

                    Image(nsImage: state.currentImage)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: state.characterSize, height: state.characterSize)
                        .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 12)
                        .overlay {
                            CharacterInteractionOverlay(state: state)
                                .frame(width: state.characterSize, height: state.characterSize)
                        }
                }
                .frame(width: state.characterSize, height: state.characterSize)

                if state.isChatOpen {
                    ChatComposer(state: state)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .frame(width: state.stageSize.width, height: state.stageSize.height)
        .background(Color.clear)
        .animation(.easeOut(duration: 0.16), value: state.isChatOpen)
        .animation(.easeOut(duration: 0.16), value: state.isSettingsOpen)
    }
}

private struct SettingsPanel: View {
    @ObservedObject var state: BuddyAppState

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Circle()
                    .fill(state.peers.isEmpty ? Color.orange : Color.green)
                    .frame(width: 8, height: 8)
                Text(state.settingsConnectionLabel)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Spacer()
            }

            settingsSection(title: "친구 연결", trailing: state.relayHealthStatus) {
                HStack(spacing: 6) {
                    Button("호스트 시작") {
                        state.createRelayRoom()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button("연결 끊기") {
                        state.disconnectRelay()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Spacer()
                }

                HStack(spacing: 6) {
                    Text("초대 코드")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(state.relayPairingCode.isEmpty ? "없음" : state.relayPairingCode)
                        .fontWeight(.bold)
                        .monospaced()
                        .lineLimit(1)
                    Button("복사") {
                        state.copyRelayPairingCodeToPasteboard()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(!BuddyRelayPairingCode.isValid(state.relayPairingCode))
                }

                Text("다시 호스트 시작을 누르면 새 코드가 만들어집니다.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            settingsSection(title: "상대 코드로 참여") {
                HStack(spacing: 6) {
                    TextField("코드 붙여넣기", text: $state.relayPairingCode)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 118)
                        .onChange(of: state.relayPairingCode) { value in
                            state.relayPairingCode = value.uppercased()
                        }

                    Button("참여") {
                        state.connectRelay()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(!BuddyRelayPairingCode.isValid(state.relayPairingCode))

                    Spacer()
                }
            }

            settingsSection(title: "크기", trailing: "\(Int(state.characterSize))px") {
                Picker("Size preset", selection: sizePresetSelection) {
                    ForEach(BuddyCharacterSizing.presets) { preset in
                        Text(preset.label).tag(preset.id)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)

                HStack(spacing: 8) {
                    Button {
                        state.adjustCharacterSize(stepCount: -1)
                    } label: {
                        Image(systemName: "minus")
                            .frame(width: 12, height: 12)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Decrease size")

                    Slider(
                        value: sizeSliderValue,
                        in: Double(BuddyGeometry.minimumCharacterSize)...Double(BuddyGeometry.maximumCharacterSize),
                        step: 1
                    )

                    Button {
                        state.adjustCharacterSize(stepCount: 1)
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 12, height: 12)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Increase size")

                    Button {
                        state.resetSize()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .frame(width: 14, height: 14)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Reset size")
                }
            }

            settingsSection(title: "리액션") {
                HStack(spacing: 6) {
                    ForEach(BuddyReactionChoice.quickChoices) { choice in
                        Button {
                            state.sendReaction(animationId: choice.animationId)
                        } label: {
                            Image(systemName: choice.systemImageName)
                                .frame(width: 13, height: 13)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help(choice.label)
                    }
                    Spacer()
                }
            }

            settingsSection(title: "도구") {
                HStack(spacing: 6) {
                    Button("릴레이 테스트") {
                        state.testRelayHealth()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button {
                        state.copyDiagnosticsToPasteboard()
                    } label: {
                        Image(systemName: "doc.text")
                            .frame(width: 13, height: 13)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Copy diagnostics")

                    Button("Quit") {
                        NSApp.terminate(nil)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Quit My Buddy")

                    Spacer()
                }

                Text(state.diagnosticsCopyStatus ?? state.relayHealthStatus)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let networkError = state.networkError {
                Text(networkError)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

        }
        .font(.system(size: 12))
        .foregroundStyle(Color(nsColor: .labelColor))
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 10)
    }

    private func settingsSection<Content: View>(
        title: String,
        trailing: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .fontWeight(.bold)
                Spacer()
                if let trailing {
                    Text(trailing)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            content()
        }
        .padding(.top, 9)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private var sizeSliderValue: Binding<Double> {
        Binding(
            get: { Double(state.characterSize) },
            set: { state.setCharacterSize(CGFloat($0)) }
        )
    }

    private var sizePresetSelection: Binding<String> {
        Binding(
            get: {
                BuddyCharacterSizing.presetId(
                    exactlyMatchingSize: state.characterSize
                ) ?? ""
            },
            set: { state.setCharacterSizePreset(id: $0) }
        )
    }
}

private struct SpeechBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Color(nsColor: .labelColor))
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(nsColor: .textBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color(nsColor: .labelColor), lineWidth: 2)
                    )
            )
            .shadow(color: .black.opacity(0.14), radius: 14, x: 0, y: 9)
            .frame(maxWidth: 230)
    }
}

private struct ChatComposer: View {
    @ObservedObject var state: BuddyAppState
    @FocusState private var isFocused: Bool
    @State private var text = ""

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 7) {
                TextField("Say something", text: $text)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onSubmit(send)
                    .onChange(of: text) { value in
                        if value.count > BuddyChatMessagePolicy.maximumTextLength {
                            text = String(value.prefix(BuddyChatMessagePolicy.maximumTextLength))
                        }
                    }

                Button("Send", action: send)
                    .buttonStyle(.borderedProminent)
                    .disabled(BuddyChatMessagePolicy.preparedText(text) == nil)

                Button {
                    state.isChatOpen = false
                } label: {
                    Image(systemName: "xmark")
                        .frame(width: 12, height: 12)
                }
                .buttonStyle(.bordered)
            }

            HStack {
                Text(state.chatDeliveryStatus ?? " ")
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                Text("\(text.count)/\(BuddyChatMessagePolicy.maximumTextLength)")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .font(.system(size: 10, weight: .medium))
        }
        .font(.system(size: 14, weight: .semibold))
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.42), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 7)
        .onAppear {
            isFocused = true
        }
    }

    private func send() {
        if state.sendChat(text) {
            text = ""
        }
    }
}

private struct CharacterInteractionOverlay: NSViewRepresentable {
    let state: BuddyAppState

    func makeNSView(context: Context) -> CharacterInteractionNSView {
        CharacterInteractionNSView(state: state)
    }

    func updateNSView(_ nsView: CharacterInteractionNSView, context: Context) {
        nsView.state = state
    }
}

final class CharacterInteractionNSView: NSView {
    var state: BuddyAppState

    init(state: BuddyAppState) {
        self.state = state
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        guard let window else {
            return
        }

        window.makeKey()
        let startMouseLocation = NSEvent.mouseLocation
        let startWindowOrigin = window.frame.origin
        var didMoveWindow = false

        while true {
            guard let nextEvent = window.nextEvent(
                matching: [.leftMouseDragged, .leftMouseUp]
            ) else {
                break
            }

            if nextEvent.type == .leftMouseUp {
                break
            }

            let currentMouseLocation = NSEvent.mouseLocation
            let offsetX = currentMouseLocation.x - startMouseLocation.x
            let offsetY = currentMouseLocation.y - startMouseLocation.y
            if abs(offsetX) + abs(offsetY) <= 3 {
                continue
            }

            didMoveWindow = true
            window.setFrameOrigin(
                NSPoint(
                    x: startWindowOrigin.x + offsetX,
                    y: startWindowOrigin.y + offsetY
                )
            )
        }

        guard !didMoveWindow, !state.isSettingsOpen else {
            return
        }

        state.handleCharacterPrimaryClick(
            action: BuddyCharacterClickPolicy.action(forClickCount: event.clickCount)
        )
    }

    override func rightMouseDown(with event: NSEvent) {
        window?.makeKey()
        state.toggleSettings()
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: state.isSettingsOpen ? .openHand : .pointingHand)
    }
}
