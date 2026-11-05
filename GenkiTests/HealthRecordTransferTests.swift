import Foundation
import SwiftData
import Testing
@testable import Genki

/// The transfer types are the future backup format (D-022), so their encoding
/// is a promise. Fictional data only.
struct HealthRecordTransferTests {
    @Test("A transfer package survives a JSON round trip unchanged")
    func roundTrips() throws {
        let package = HealthRecordTransferPackage(
            record: HealthRecordTransferRecord(
                id: "demo-record-1",
                createdAt: Date(timeIntervalSince1970: 1_767_225_600),
                updatedAt: Date(timeIntervalSince1970: 1_767_312_000),
                occurredAt: Date(timeIntervalSince1970: 1_767_139_200),
                categoryIdentifier: HealthRecordCategory.checkup.rawValue,
                fields: [
                    HealthRecordFieldValue(
                        identifier: .diagnosisConclusion,
                        values: [
                            LocalizedHealthText(text: "未见明显异常", languageTag: "zh-Hans", source: .ocr),
                        ]
                    ),
                ],
                codings: [HealthCoding(system: "http://loinc.org", code: "0000-0")]
            ),
            assets: [
                HealthMediaAsset(
                    metadata: HealthMediaAttachmentMetadata(
                        id: "demo-asset-1",
                        kind: .radiologyImage,
                        contentType: "public.jpeg",
                        byteCount: 3
                    ),
                    data: Data([1, 2, 3])
                ),
            ]
        )

        let encoded = try JSONEncoder().encode(package)
        let decoded = try JSONDecoder().decode(HealthRecordTransferPackage.self, from: encoded)

        #expect(decoded == package)
    }

    @Test("Identifiers are stored as their plain string, so new ones don't change the format")
    func identifiersEncodeAsStrings() throws {
        let encoded = try JSONEncoder().encode([HealthRecordFieldIdentifier.rawOCRText])

        #expect(String(bytes: encoded, encoding: .utf8) == #"["source.ocr-text"]"#)
    }

    @Test("The app's store opens with the full schema")
    func storeOpens() throws {
        let container = try GenkiStore.makeContainer(inMemory: true)
        let record = HealthRecord(hospitalName: "示例医院")
        container.mainContext.insert(record)
        try container.mainContext.save()

        let fetched = try container.mainContext.fetch(FetchDescriptor<HealthRecord>())
        #expect(fetched.map(\.hospitalName) == ["示例医院"])
    }
}
