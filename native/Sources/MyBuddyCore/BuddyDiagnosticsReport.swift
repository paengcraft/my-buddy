public struct BuddyDiagnosticsItem: Equatable {
    public let label: String
    public let value: String

    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }
}

public struct BuddyDiagnosticsReport: Equatable {
    public let items: [BuddyDiagnosticsItem]

    public init(items: [BuddyDiagnosticsItem]) {
        self.items = items
    }

    public var text: String {
        (["My Buddy Diagnostics"] + items.map { "\($0.label): \($0.value)" })
            .joined(separator: "\n")
    }
}
