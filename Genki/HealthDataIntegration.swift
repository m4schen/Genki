import Foundation

// MARK: - Integration root

/// Optional integrations used by the app.
///
/// The app should use `.localOnly` until a user explicitly enables an adapter.
/// This file intentionally imports neither CloudKit nor HealthKit, so merely
/// compiling it does not add an entitlement, request permission, or upload data.
struct HealthDataIntegration: Sendable {
    let personalCloud: any PersonalCloudRecordSyncing
    let systemHealth: any SystemHealthWriting

    init(
        personalCloud: any PersonalCloudRecordSyncing,
        systemHealth: any SystemHealthWriting
    ) {
        self.personalCloud = personalCloud
        self.systemHealth = systemHealth
    }

    /// Safe default for the current, device-only product.
    static let localOnly = HealthDataIntegration(
        personalCloud: LocalOnlyPersonalCloudRecordSync(),
        systemHealth: LocalOnlySystemHealthWriter()
    )
}

// MARK: - Stable, extensible identifiers

/// Identifiers are strings instead of closed enums so future record fields can
/// be added without changing the transfer format.
struct HealthRecordFieldIdentifier: RawRepresentable, Codable, Hashable, Sendable {
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

    // Structured export fields. An adapter may require only a subset.
    static let medicationName = Self("medication.name")
    static let medicationDose = Self("medication.dose")
    static let medicationInstructions = Self("medication.instructions")
    static let observationValue = Self("observation.value")
    static let observationUnit = Self("observation.unit")
}

struct HealthTextSourceIdentifier: RawRepresentable, Codable, Hashable, Sendable {
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

struct HealthMediaKindIdentifier: RawRepresentable, Codable, Hashable, Sendable {
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

/// A requested destination data type. These values describe intent only; they
/// do not claim that the installed OS or a future adapter supports writing it.
struct SystemHealthDataTypeIdentifier: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }

    /// A future medication adapter must verify the exact OS API and writable
    /// operation; a scanned prescription alone is not a writable medication.
    static let medication = Self("medication")
    static let diagnosticObservation = Self("diagnostic-observation")
    /// HealthKit clinical records are currently read-only. A HealthKit adapter
    /// must report this destination as unsupported for write operations.
    static let clinicalRecord = Self("clinical-record")
    static let immunization = Self("immunization")
}

// MARK: - Language-aware transfer values

/// Human-readable text plus its BCP-47 language tag, for example `zh-Hans` or
/// `en-US`. Keep separate entries when a translated value is added later.
struct LocalizedHealthText: Codable, Equatable, Sendable {
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

struct HealthRecordFieldValue: Codable, Equatable, Sendable {
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
struct HealthCoding: Codable, Equatable, Sendable {
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

struct HealthPixelSize: Codable, Equatable, Sendable {
    let width: Int
    let height: Int
}

/// Metadata is usable by the UI and search index without loading private image
/// bytes. Radiology and ophthalmic images are first-class kinds, while custom
/// media kinds and namespaced metadata keep this format open to future formats.
struct HealthMediaAttachmentMetadata: Codable, Equatable, Sendable, Identifiable {
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

/// The only integration DTO that carries attachment bytes. Callers should
/// check an integration's status before constructing these assets.
struct HealthMediaAsset: Codable, Equatable, Sendable {
    let metadata: HealthMediaAttachmentMetadata
    let data: Data
}

// MARK: - Store-independent record transfer

/// A versioned snapshot detached from SwiftData. It is safe to pass across an
/// actor boundary and keeps storage migrations out of external adapters.
struct HealthRecordTransferRecord: Codable, Equatable, Sendable, Identifiable {
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

struct HealthRecordTransferPackage: Codable, Equatable, Sendable {
    let record: HealthRecordTransferRecord
    let assets: [HealthMediaAsset]

    init(record: HealthRecordTransferRecord, assets: [HealthMediaAsset] = []) {
        self.record = record
        self.assets = assets
    }
}

struct HealthRecordDeletion: Codable, Equatable, Sendable {
    let recordIdentifier: String
    let deletedAt: Date
}

struct HealthRecordChangeSet: Codable, Equatable, Sendable {
    let upserts: [HealthRecordTransferPackage]
    let deletions: [HealthRecordDeletion]
    let previousServerChangeToken: String?
    let requestedAt: Date

    init(
        upserts: [HealthRecordTransferPackage] = [],
        deletions: [HealthRecordDeletion] = [],
        previousServerChangeToken: String? = nil,
        requestedAt: Date = .now
    ) {
        self.upserts = upserts
        self.deletions = deletions
        self.previousServerChangeToken = previousServerChangeToken
        self.requestedAt = requestedAt
    }
}

// MARK: - Shared integration status

enum HealthIntegrationState: String, Codable, Sendable {
    case disabled
    case unavailable
    case ready
}

/// `reasonCode` is deliberately not localized. Presentation code maps it to a
/// localized string, keeping adapters independent of the app's UI language.
struct HealthIntegrationStatus: Codable, Equatable, Sendable {
    let state: HealthIntegrationState
    let reasonCode: String?

    var canPerformOperation: Bool {
        state == .ready
    }

    static let localOnly = Self(
        state: .disabled,
        reasonCode: "integration.local-only"
    )
}

// MARK: - Personal iCloud boundary

/// Boundary for an optional, user-enabled sync adapter.
///
/// A conforming iCloud implementation must use the user's private database.
/// Shared or public databases require a separate product decision and must not
/// be silently substituted here.
protocol PersonalCloudRecordSyncing: Sendable {
    func status() async -> HealthIntegrationStatus
    func synchronize(_ changes: HealthRecordChangeSet) async throws
        -> PersonalCloudSyncResult
}

struct PersonalCloudSyncReceipt: Sendable {
    let synchronizedAt: Date
    let acceptedRecordIdentifiers: [String]
    let acceptedDeletionIdentifiers: [String]
    let remoteChanges: HealthRecordChangeSet
    let serverChangeToken: String?
}

enum PersonalCloudSyncResult: Sendable {
    case skipped(HealthIntegrationStatus)
    case synchronized(PersonalCloudSyncReceipt)
}

/// Current default. It performs no network access and does not inspect asset
/// bytes supplied by a caller.
struct LocalOnlyPersonalCloudRecordSync: PersonalCloudRecordSyncing {
    func status() async -> HealthIntegrationStatus {
        .localOnly
    }

    func synchronize(
        _ changes: HealthRecordChangeSet
    ) async throws -> PersonalCloudSyncResult {
        .skipped(.localOnly)
    }
}

// MARK: - System Health / Medications boundary

/// A structured, user-reviewed value proposed for a system health destination.
/// Actual support is reported per type by the installed adapter.
struct SystemHealthWriteCandidate: Codable, Equatable, Sendable, Identifiable {
    let id: String
    let dataType: SystemHealthDataTypeIdentifier
    let startDate: Date
    let endDate: Date?
    let fields: [HealthRecordFieldValue]
    let codings: [HealthCoding]
    let sourceAttachmentIdentifiers: [String]
    let extensionMetadata: [String: String]

    init(
        id: String,
        dataType: SystemHealthDataTypeIdentifier,
        startDate: Date,
        endDate: Date? = nil,
        fields: [HealthRecordFieldValue],
        codings: [HealthCoding] = [],
        sourceAttachmentIdentifiers: [String] = [],
        extensionMetadata: [String: String] = [:]
    ) {
        self.id = id
        self.dataType = dataType
        self.startDate = startDate
        self.endDate = endDate
        self.fields = fields
        self.codings = codings
        self.sourceAttachmentIdentifiers = sourceAttachmentIdentifiers
        self.extensionMetadata = extensionMetadata
    }
}

/// Proof that the app displayed the exact candidates and the user chose to
/// export them. This is separate from operating-system authorization.
struct UserHealthExportConfirmation: Codable, Equatable, Sendable {
    let sourceRecordIdentifier: String
    let candidateIdentifiers: [String]
    let confirmedAt: Date
    let disclosureVersion: String

    init(
        sourceRecordIdentifier: String,
        candidateIdentifiers: [String],
        confirmedAt: Date = .now,
        disclosureVersion: String
    ) {
        self.sourceRecordIdentifier = sourceRecordIdentifier
        self.candidateIdentifiers = candidateIdentifiers
        self.confirmedAt = confirmedAt
        self.disclosureVersion = disclosureVersion
    }
}

struct SystemHealthWriteRequest: Codable, Equatable, Sendable {
    let sourceRecord: HealthRecordTransferRecord
    let candidates: [SystemHealthWriteCandidate]
    let referencedAssets: [HealthMediaAsset]
    let confirmation: UserHealthExportConfirmation
    let idempotencyKey: String

    init(
        sourceRecord: HealthRecordTransferRecord,
        candidates: [SystemHealthWriteCandidate],
        referencedAssets: [HealthMediaAsset] = [],
        confirmation: UserHealthExportConfirmation,
        idempotencyKey: String
    ) {
        self.sourceRecord = sourceRecord
        self.candidates = candidates
        self.referencedAssets = referencedAssets
        self.confirmation = confirmation
        self.idempotencyKey = idempotencyKey
    }
}

enum SystemHealthAuthorizationResult: Sendable {
    case skipped(HealthIntegrationStatus)
    case resolved(
        authorized: Set<SystemHealthDataTypeIdentifier>,
        deniedOrUnsupported: Set<SystemHealthDataTypeIdentifier>
    )
}

struct SystemHealthWriteFailure: Codable, Equatable, Sendable {
    let candidateIdentifier: String
    let reasonCode: String
}

struct SystemHealthWriteReceipt: Codable, Equatable, Sendable {
    let completedAt: Date
    let writtenCandidateIdentifiers: [String]
    let failures: [SystemHealthWriteFailure]

    /// Maps a candidate identifier to an opaque identifier returned by the
    /// destination, when one is available.
    let externalIdentifiers: [String: String]
}

enum SystemHealthWriteResult: Sendable {
    case skipped(HealthIntegrationStatus)
    case completed(SystemHealthWriteReceipt)
}

/// Adapter boundary for Apple Health, Medications, or another system-owned
/// health store. Capability checks are mandatory because some requested types
/// may be read-only or unavailable on a given OS.
protocol SystemHealthWriting: Sendable {
    func status(
        for dataType: SystemHealthDataTypeIdentifier
    ) async -> HealthIntegrationStatus

    func requestAuthorization(
        for dataTypes: Set<SystemHealthDataTypeIdentifier>
    ) async throws -> SystemHealthAuthorizationResult

    func write(
        _ request: SystemHealthWriteRequest
    ) async throws -> SystemHealthWriteResult
}

/// Current default. It neither imports HealthKit nor requests health access.
struct LocalOnlySystemHealthWriter: SystemHealthWriting {
    func status(
        for dataType: SystemHealthDataTypeIdentifier
    ) async -> HealthIntegrationStatus {
        .localOnly
    }

    func requestAuthorization(
        for dataTypes: Set<SystemHealthDataTypeIdentifier>
    ) async throws -> SystemHealthAuthorizationResult {
        .skipped(.localOnly)
    }

    func write(
        _ request: SystemHealthWriteRequest
    ) async throws -> SystemHealthWriteResult {
        .skipped(.localOnly)
    }
}
