import Foundation
import SwiftData
import Testing
@testable import Genki

/// The list screen's rules (UC3). Fictional data only.
struct RecordTimelineTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .gmt
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
    }

    // MARK: Search

    @Test("Search finds text that only appears in the OCR original")
    func searchesOCRText() throws {
        let container = try TestStore.makeContainer()
        let eye = HealthRecord(hospitalName: "示例眼科医院", rawOCRText: "眼底照相：未见异常")
        let clinic = HealthRecord(hospitalName: "示例门诊部")
        [eye, clinic].forEach(container.mainContext.insert)

        let found = RecordTimeline.filter([eye, clinic], matching: "眼底")

        #expect(found.map(\.recordID) == [eye.recordID])
    }

    @Test("The query is trimmed, and matching ignores case")
    func trimsQueryAndIgnoresCase() throws {
        let container = try TestStore.makeContainer()
        let scan = HealthRecord(examinationResults: "胸部 CT 未见异常")
        container.mainContext.insert(scan)

        #expect(RecordTimeline.filter([scan], matching: "  ct  ").count == 1)
    }

    @Test("An empty or blank query returns every record, in order", arguments: ["", "   "])
    func blankQueryReturnsEverything(query: String) throws {
        let container = try TestStore.makeContainer()
        let records = [HealthRecord(hospitalName: "甲"), HealthRecord(hospitalName: "乙")]
        records.forEach(container.mainContext.insert)

        let found = RecordTimeline.filter(records, matching: query)

        #expect(found.map(\.recordID) == records.map(\.recordID))
    }

    @Test("The category name is searchable")
    func searchesCategoryTitle() throws {
        let container = try TestStore.makeContainer()
        let checkup = HealthRecord(category: HealthRecordCategory.checkup.rawValue)
        container.mainContext.insert(checkup)

        #expect(RecordTimeline.filter([checkup], matching: "体检").count == 1)
    }

    // MARK: Month sections

    @Test("Records are grouped by month, newest month first, keeping their order")
    func groupsByMonth() throws {
        let container = try TestStore.makeContainer()
        let lateMarch = HealthRecord(occurredAt: date(2026, 3, 28))
        let earlyMarch = HealthRecord(occurredAt: date(2026, 3, 2))
        let january = HealthRecord(occurredAt: date(2026, 1, 15))
        [lateMarch, earlyMarch, january].forEach(container.mainContext.insert)

        let sections = RecordTimeline.monthSections(
            of: [lateMarch, earlyMarch, january],
            calendar: calendar
        )

        #expect(sections.map(\.month) == [date(2026, 3, 1), date(2026, 1, 1)])
        #expect(sections.first?.records.map(\.recordID) == [lateMarch.recordID, earlyMarch.recordID])
    }
}
