import Foundation

// Store-independent, versioned transfer types. They become the backup
// format (D-018, D-022), so changing an identifier's raw value or a coded
// property name is a format change. Bump `currentSchemaVersion`, and keep
// a reader for every older version.

// MARK: - Stable, extensible identifiers

/// Identifiers are strings instead of closed enums so future record fields can
/// be added without changing the transfer format.
nonisolated struct HealthRecordFieldIdentifier: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }

    static let institutionName = Self("institution.name")
    static let departmentName = Self("institution.department")
    static let clinicianName = Self("clinician.name")
    static let visitReason = Self("record.visit-reason")
    static let diagnosisConclusion = Self("record.diagnosis-conclusion")
    static let examinationResults = Self("record.examination-results")
    static let medications = Self("record.medications")
    static let clinicianAdvice = Self("record.clinician-advice")
    static let personalNotes = Self("record.personal-notes")
    static let rawOCRText = Self("source.ocr-text")

    // Structured export fields. A reader may use only a subset.
    static let medicationName = Self("medication.name")
    static let medicationDose = Self("medication.dose")
    static let medicationInstructions = Self("medication.instructions")
    static let observationValue = Self("observation.value")
    static let observationUnit = Self("observation.unit")
}

nonisolated struct HealthTextSourceIdentifier: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }

    static let manual = Self("manual")
    static let ocr = Self("ocr")
    static let imported = Self("imported")
    static let translated = Self("translated")
}

nonisolated struct HealthMediaKindIdentifier: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }

    static let scannedDocument = Self("document.scanned")
    static let labReport = Self("document.lab-report")
    static let prescription = Self("document.prescription")
    static let radiologyImage = Self("image.radiology")
    static let ophthalmicImage = Self("image.ophthalmic")
    static let clinicalPhoto = Self("image.clinical")
    static let other = Self("other")
}

// MARK: - Language-aware transfer values

/// Human-readable text plus its BCP-47 language tag, for example `zh-Hans` or
/// `en-US`. Keep separate entries when a translated value is added later.
nonisolated struct LocalizedHealthText: Codable, Equatable, Sendable {
    let text: String
    let languageTag: String?
    let source: HealthTextSourceIdentifier

    init(
        text: String,
        languageTag: String? = nil,
        source: HealthTextSourceIdentifier = .manual
    ) {
        self.text = text
        self.languageTag = languageTag
        self.source = source
    }
}

nonisolated struct HealthRecordFieldValue: Codable, Equatable, Sendable {
    let identifier: HealthRecordFieldIdentifier
    let values: [LocalizedHealthText]

    /// Namespaced keys allow an importer to retain extra metadata without
    /// turning user-facing labels into permanent schema identifiers.
    let extensionMetadata: [String: String]

    init(
        identifier: HealthRecordFieldIdentifier,
        values: [LocalizedHealthText],
        extensionMetadata: [String: String] = [:]
    ) {
        self.identifier = identifier
        self.values = values
        self.extensionMetadata = extensionMetadata
    }
}

/// Optional coding for data that has a standard vocabulary such as LOINC,
/// SNOMED CT, or RxNorm. Plain text remains available when no code is known.
nonisolated struct HealthCoding: Codable, Equatable, Sendable {
    let system: String
    let code: String
    let displayNames: [LocalizedHealthText]

    init(
        system: String,
        code: String,
        displayNames: [LocalizedHealthText] = []
    ) {
        self.system = system
        self.code = code
        self.displayNames = displayNames
    }
}

// MARK: - Media transfer

nonisolated struct HealthPixelSize: Codable, Equatable, Sendable {
    let width: Int
    let height: Int
}

/// Metadata is usable by the UI and search index without loading private image
/// bytes. Radiology and ophthalmic images are first-class kinds, while custom
/// media kinds and namespaced metadata keep this format open to future formats.
nonisolated struct HealthMediaAttachmentMetadata: Codable, Equatable, Sendable, Identifiable {
    let id: String
    let kind: HealthMediaKindIdentifier
    let contentType: String
    let fileName: String?
    let byteCount: Int
    let pixelSize: HealthPixelSize?
    let capturedAt: Date?
    let sourceLanguageTag: String?
    let captions: [LocalizedHealthText]
    let contentHash: String?
    let contentHashAlgorithm: String?
    let extensionMetadata: [String: String]

    init(
        id: String,
        kind: HealthMediaKindIdentifier,
        contentType: String,
        fileName: String? = nil,
        byteCount: Int,
        pixelSize: HealthPixelSize? = nil,
        capturedAt: Date? = nil,
        sourceLanguageTag: String? = nil,
        captions: [LocalizedHealthText] = [],
        contentHash: String? = nil,
        contentHashAlgorithm: String? = nil,
        extensionMetadata: [String: String] = [:]
    ) {
        self.id = id
        self.kind = kind
        self.contentType = contentType
        self.fileName = fileName
        self.byteCount = byteCount
        self.pixelSize = pixelSize
        self.capturedAt = capturedAt
        self.sourceLanguageTag = sourceLanguageTag
        self.captions = captions
        self.contentHash = contentHash
        self.contentHashAlgorithm = contentHashAlgorithm
        self.extensionMetadata = extensionMetadata
    }
}

/// The only transfer type that carries attachment bytes. Everything else
/// stays readable without loading private image data.
nonisolated struct HealthMediaAsset: Codable, Equatable, Sendable {
    let metadata: HealthMediaAttachmentMetadata
    let data: Data
}

// MARK: - Store-independent record transfer

/// A versioned snapshot detached from SwiftData. It is safe to pass across an
/// actor boundary, and it keeps storage migrations out of the backup format.
nonisolated struct HealthRecordTransferRecord: Codable, Equatable, Sendable, Identifiable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let id: String
    let revisionIdentifier: String?
    let createdAt: Date
    let updatedAt: Date
    let occurredAt: Date
    let categoryIdentifier: String
    let fields: [HealthRecordFieldValue]
    let codings: [HealthCoding]
    let extensionMetadata: [String: String]

    init(
        schemaVersion: Int = Self.currentSchemaVersion,
        id: String,
        revisionIdentifier: String? = nil,
        createdAt: Date,
        updatedAt: Date,
        occurredAt: Date,
        categoryIdentifier: String,
        fields: [HealthRecordFieldValue],
        codings: [HealthCoding] = [],
        extensionMetadata: [String: String] = [:]
    ) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.revisionIdentifier = revisionIdentifier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.occurredAt = occurredAt
        self.categoryIdentifier = categoryIdentifier
        self.fields = fields
        self.codings = codings
        self.extensionMetadata = extensionMetadata
    }
}

nonisolated struct HealthRecordTransferPackage: Codable, Equatable, Sendable {
    let record: HealthRecordTransferRecord
    let assets: [HealthMediaAsset]

    init(record: HealthRecordTransferRecord, assets: [HealthMediaAsset] = []) {
        self.record = record
        self.assets = assets
    }
}
