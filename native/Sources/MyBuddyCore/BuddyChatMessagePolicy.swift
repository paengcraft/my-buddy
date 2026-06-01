public enum BuddyChatMessagePolicy {
    public static let maximumTextLength = 280

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
