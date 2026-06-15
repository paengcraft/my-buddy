import Foundation

public struct BuddyTodoItem: Codable, Equatable, Identifiable {
    public let id: String
    public var text: String
    public var isDone: Bool
    public let createdAt: TimeInterval
    public let createdByDeviceId: String
    public var updatedAt: TimeInterval
    public var updatedByDeviceId: String

    public init(
        id: String,
        text: String,
        isDone: Bool,
        createdAt: TimeInterval,
        createdByDeviceId: String,
        updatedAt: TimeInterval,
        updatedByDeviceId: String
    ) {
        self.id = id
        self.text = text
        self.isDone = isDone
        self.createdAt = createdAt
        self.createdByDeviceId = createdByDeviceId
        self.updatedAt = updatedAt
        self.updatedByDeviceId = updatedByDeviceId
    }
}

public struct BuddyTodoDeletionRecord: Codable, Equatable, Identifiable {
    public let id: String
    public let deletedAt: TimeInterval
    public let deletedByDeviceId: String

    public init(id: String, deletedAt: TimeInterval, deletedByDeviceId: String) {
        self.id = id
        self.deletedAt = deletedAt
        self.deletedByDeviceId = deletedByDeviceId
    }
}

public struct BuddyTodoSnapshot: Codable, Equatable {
    public var items: [BuddyTodoItem]
    public var deletions: [BuddyTodoDeletionRecord]

    public init(items: [BuddyTodoItem], deletions: [BuddyTodoDeletionRecord]) {
        self.items = items
        self.deletions = deletions
    }

    public static let empty = BuddyTodoSnapshot(items: [], deletions: [])
}

public enum BuddyTodoInputPolicy {
    public static let maximumTextLength = 120

    public static func preparedText(_ text: String) -> String? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty,
              trimmedText.count <= maximumTextLength
        else {
            return nil
        }

        return trimmedText
    }
}

public enum BuddyTodoSyncPolicy {
    public static func merged(
        local: BuddyTodoSnapshot,
        remote: BuddyTodoSnapshot
    ) -> BuddyTodoSnapshot {
        var itemsById = Dictionary(uniqueKeysWithValues: local.items.map { ($0.id, $0) })
        var deletionsById = Dictionary(uniqueKeysWithValues: local.deletions.map { ($0.id, $0) })

        for deletion in remote.deletions {
            if let existing = deletionsById[deletion.id] {
                if deletion.deletedAt > existing.deletedAt {
                    deletionsById[deletion.id] = deletion
                }
            } else {
                deletionsById[deletion.id] = deletion
            }
        }

        for remoteItem in remote.items {
            if let localItem = itemsById[remoteItem.id] {
                if shouldReplace(localItem, with: remoteItem) {
                    itemsById[remoteItem.id] = remoteItem
                }
            } else {
                itemsById[remoteItem.id] = remoteItem
            }
        }

        for (id, deletion) in deletionsById {
            guard let item = itemsById[id] else { continue }

            if item.updatedAt > deletion.deletedAt {
                deletionsById.removeValue(forKey: id)
            } else {
                itemsById.removeValue(forKey: id)
            }
        }

        return BuddyTodoSnapshot(
            items: itemsById.values.sorted {
                if $0.createdAt == $1.createdAt {
                    return $0.id < $1.id
                }

                return $0.createdAt < $1.createdAt
            },
            deletions: deletionsById.values.sorted {
                if $0.deletedAt == $1.deletedAt {
                    return $0.id < $1.id
                }

                return $0.deletedAt < $1.deletedAt
            }
        )
    }

    private static func shouldReplace(_ local: BuddyTodoItem, with remote: BuddyTodoItem) -> Bool {
        if remote.updatedAt == local.updatedAt {
            return remote.updatedByDeviceId > local.updatedByDeviceId
        }

        return remote.updatedAt > local.updatedAt
    }
}
