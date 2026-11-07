import Foundation
import SwiftData
import Testing
@testable import Genki

/// Demo seeding (DEBUG builds only). Each test uses its own defaults suite,
/// so it never reads or writes the app's real "already seeded" flag.
struct DemoDataSeederTests {
    private static func freshDefaults() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: "GenkiTests.\(UUID().uuidString)"))
    }

    @Test("An empty store gets three fictional records, two with demo images")
    func seedsEmptyStore() throws {
        let container = try TestStore.makeContainer() // must outlive its context
        let context = container.mainContext

        let didSeed = try DemoDataSeeder.seedIfNeeded(in: context, defaults: Self.freshDefaults())

        let records = try context.fetch(FetchDescriptor<HealthRecord>())
        #expect(didSeed)
        #expect(records.count == 3)
        #expect(records.allSatisfy { $0.isDemo })
        #expect(records.flatMap(\.attachments).map(\.source).sorted() == ["demo", "demo"])
    }

    @Test("Seeding twice adds nothing the second time")
    func seedingIsIdempotent() throws {
        let container = try TestStore.makeContainer() // must outlive its context
        let context = container.mainContext
        let defaults = try Self.freshDefaults()

        try DemoDataSeeder.seedIfNeeded(in: context, defaults: defaults)
        let secondRun = try DemoDataSeeder.seedIfNeeded(in: context, defaults: defaults)

        #expect(!secondRun)
        #expect(try context.fetchCount(FetchDescriptor<HealthRecord>()) == 3)
    }

    @Test("A store that already has records is never seeded")
    func leavesExistingStoreAlone() throws {
        let container = try TestStore.makeContainer() // must outlive its context
        let context = container.mainContext
        context.insert(HealthRecord(hospitalName: "示例医院"))

        let didSeed = try DemoDataSeeder.seedIfNeeded(in: context, defaults: Self.freshDefaults())

        #expect(!didSeed)
        #expect(try context.fetchCount(FetchDescriptor<HealthRecord>()) == 1)
    }
}
