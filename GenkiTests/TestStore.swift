import SwiftData
@testable import Genki

/// SwiftData needs a live container before a `@Model` can be created, so
/// every test that builds a model makes its own throwaway in-memory store.
/// Tests never touch the real on-device store.
enum TestStore {
    static func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: HealthRecord.self, RecordAttachment.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
}
