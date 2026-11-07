import Foundation

extension String {
    /// The string without leading or trailing whitespace and newlines.
    nonisolated var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
