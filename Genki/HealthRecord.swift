import Foundation
import SwiftData

@Model
final class HealthRecord {
    var recordID: UUID = UUID()
    var schemaVersion: Int = 1
    var createdAt: Date
    var updatedAt: Date
    var sourceLanguageCode: String = "und"
    var isDemo: Bool = false

    var occurredAt: Date
    var hospitalName: String
    var department: String
    var doctorName: String
    var category: String
    var medicalRecordNumber: String

    var visitReason: String
    var diagnosisOrConclusion: String
    var examinationResults: String
    var medications: String
    var doctorAdvice: String
    var followUpDate: Date?
    var notes: String
    var rawOCRText: String

    @Relationship(deleteRule: .cascade, inverse: \RecordAttachment.record)
    var attachments: [RecordAttachment]

    init(
        recordID: UUID = UUID(),
        schemaVersion: Int = 1,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        sourceLanguageCode: String = Locale.current.language.languageCode?.identifier ?? "und",
        isDemo: Bool = false,
        occurredAt: Date = .now,
        hospitalName: String = "",
        department: String = "",
        doctorName: String = "",
        category: String = HealthRecordCategory.visit.rawValue,
        medicalRecordNumber: String = "",
        visitReason: String = "",
        diagnosisOrConclusion: String = "",
        examinationResults: String = "",
        medications: String = "",
        doctorAdvice: String = "",
        followUpDate: Date? = nil,
        notes: String = "",
        rawOCRText: String = "",
        attachments: [RecordAttachment] = []
    ) {
        self.recordID = recordID
        self.schemaVersion = schemaVersion
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sourceLanguageCode = sourceLanguageCode
        self.isDemo = isDemo
        self.occurredAt = occurredAt
        self.hospitalName = hospitalName
        self.department = department
        self.doctorName = doctorName
        self.category = category
        self.medicalRecordNumber = medicalRecordNumber
        self.visitReason = visitReason
        self.diagnosisOrConclusion = diagnosisOrConclusion
        self.examinationResults = examinationResults
        self.medications = medications
        self.doctorAdvice = doctorAdvice
        self.followUpDate = followUpDate
        self.notes = notes
        self.rawOCRText = rawOCRText
        self.attachments = attachments
    }
}

@Model
final class RecordAttachment {
    var attachmentID: UUID = UUID()
    var createdAt: Date
    var sortOrder: Int
    var kind: String = AttachmentKind.document.rawValue
    var contentType: String
    var displayName: String = ""
    var source: String = AttachmentSource.photoLibrary.rawValue
    var metadataJSON: String = ""

    @Attribute(.externalStorage)
    var imageData: Data

    var record: HealthRecord?

    init(
        attachmentID: UUID = UUID(),
        createdAt: Date = .now,
        sortOrder: Int,
        kind: String = AttachmentKind.document.rawValue,
        contentType: String = "public.jpeg",
        displayName: String = "",
        source: String = AttachmentSource.photoLibrary.rawValue,
        metadataJSON: String = "",
        data: Data,
        record: HealthRecord? = nil
    ) {
        self.attachmentID = attachmentID
        self.createdAt = createdAt
        self.sortOrder = sortOrder
        self.kind = kind
        self.contentType = contentType
        self.displayName = displayName
        self.source = source
        self.metadataJSON = metadataJSON
        self.imageData = data
        self.record = record
    }
}

nonisolated enum HealthRecordCategory: String, CaseIterable, Identifiable {
    case visit
    case checkup
    case test
    case other

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .visit: "就诊"
        case .checkup: "体检"
        case .test: "检查"
        case .other: "其他"
        }
    }
}

nonisolated enum AttachmentKind: String, CaseIterable, Identifiable {
    case document
    case medicalImage
    case photo
    case other

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .document: "文档"
        case .medicalImage: "医学影像"
        case .photo: "照片"
        case .other: "其他资料"
        }
    }
}

nonisolated enum AttachmentSource: String {
    case scanner
    case photoLibrary
    case fileImport
    case demo
}

extension HealthRecord {
    var categoryValue: HealthRecordCategory {
        if let value = HealthRecordCategory(rawValue: category) {
            return value
        }

        switch category {
        case "门诊", "急诊", "住院", "就诊":
            return .visit
        case "体检":
            return .checkup
        case "检查", "检查 / 检验", "检查报告", "检验报告":
            return .test
        default:
            return .other
        }
    }

    var categoryTitle: String {
        String(localized: categoryValue.title)
    }
}

extension RecordAttachment {
    var data: Data {
        imageData
    }

    var kindValue: AttachmentKind {
        AttachmentKind(rawValue: kind) ?? .other
    }

    var kindTitle: String {
        String(localized: kindValue.title)
    }
}
