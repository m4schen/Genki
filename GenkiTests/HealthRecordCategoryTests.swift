import SwiftData
import Testing
@testable import Genki

struct HealthRecordCategoryTests {
    @Test(
        "Stored and legacy category strings map to the right category",
        arguments: [
            ("visit", HealthRecordCategory.visit),
            ("checkup", .checkup),
            ("test", .test),
            ("other", .other),
            ("门诊", .visit),
            ("急诊", .visit),
            ("住院", .visit),
            ("就诊", .visit),
            ("体检", .checkup),
            ("检查", .test),
            ("检查 / 检验", .test),
            ("检查报告", .test),
            ("检验报告", .test),
            ("something unknown", .other),
            ("", .other),
        ]
    )
    func categoryValue(stored: String, expected: HealthRecordCategory) throws {
        let container = try TestStore.makeContainer()
        let record = HealthRecord(category: stored)
        container.mainContext.insert(record)

        #expect(record.categoryValue == expected)
    }
}
