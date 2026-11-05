import Foundation
import SwiftData
import UniformTypeIdentifiers

// MARK: - Field origin

/// Where a form value came from (ARCHITECTURE.md §4). OCR may write only to a
/// field that still holds its default value, so it can never overwrite what
/// the patient chose (non-negotiable 6).
nonisolated enum FieldOrigin: Equatable, Sendable {
    case defaultValue
    case suggestedByOCR
    case userOwned
}

/// A value a draft field can hold.
nonisolated protocol DraftValue: Equatable, Sendable {
    /// A blank value counts as "not filled in", so OCR may fill it again.
    var isBlank: Bool { get }
}

extension String: DraftValue {
    nonisolated var isBlank: Bool { trimmed.isEmpty }
}

extension Date: DraftValue {
    nonisolated var isBlank: Bool { false }
}

extension HealthRecordCategory: DraftValue {
    nonisolated var isBlank: Bool { false }
}

/// One form value plus where it came from. The value can change only through
/// `setByUser(_:)` or `suggest(_:)`, so its origin is always accurate.
nonisolated struct DraftField<Value: DraftValue>: Equatable, Sendable {
    private(set) var value: Value
    private(set) var origin: FieldOrigin = .defaultValue

    init(_ defaultValue: Value) {
        value = defaultValue
    }

    /// The patient typed or picked a value. Clearing a field hands it back to OCR.
    mutating func setByUser(_ newValue: Value) {
        value = newValue
        origin = newValue.isBlank ? .defaultValue : .userOwned
    }

    /// OCR proposes a value. It's ignored unless the field still holds its default.
    mutating func suggest(_ suggestion: Value?) {
        guard origin == .defaultValue, let suggestion else { return }

        value = suggestion
        origin = .suggestedByOCR
    }
}

// MARK: - Attachment draft

/// An attachment that isn't saved yet. Its bytes stay in memory until the
/// record is saved.
struct AttachmentDraft: Identifiable {
    let id = UUID()
    let data: Data
    let kind: AttachmentKind
    let contentType: String
    let displayName: String
    let source: AttachmentSource
}

// MARK: - Record draft

/// The add-record form's unsaved state, and every rule about it. Nothing
/// touches the store until `save(in:)`, so Cancel just drops the draft.
struct RecordDraft {
    var occurredAt: DraftField<Date>
    var category = DraftField(HealthRecordCategory.visit)
    var hospitalName = DraftField("")
    var department = DraftField("")
    var doctorName = DraftField("")
    var medicalRecordNumber = DraftField("")
    var visitReason = DraftField("")
    var diagnosisOrConclusion = DraftField("")
    var examinationResults = DraftField("")
    var medications = DraftField("")
    var doctorAdvice = DraftField("")
    var followUpDate: Date?
    var notes = ""
    var rawOCRText = ""
    private(set) var attachments: [AttachmentDraft] = []

    init(now: Date = .now) {
        occurredAt = DraftField(now)
    }

    // MARK: OCR

    /// Keeps the text from every scan, then lets OCR fill only the fields
    /// the patient hasn't touched.
    mutating func applyRecognizedText(_ text: String) {
        guard !text.isEmpty else { return }

        rawOCRText = rawOCRText.isEmpty ? text : rawOCRText + "\n\n" + text
        apply(HealthFieldExtractor.extract(from: text))
    }

    mutating func apply(_ fields: ExtractedHealthFields) {
        occurredAt.suggest(fields.occurredAt)
        category.suggest(fields.category)
        hospitalName.suggest(fields.hospitalName)
        department.suggest(fields.department)
        doctorName.suggest(fields.doctorName)
        medicalRecordNumber.suggest(fields.medicalRecordNumber)
        visitReason.suggest(fields.visitReason)
        diagnosisOrConclusion.suggest(fields.diagnosisOrConclusion)
        examinationResults.suggest(fields.examinationResults)
        medications.suggest(fields.medications)
        doctorAdvice.suggest(fields.doctorAdvice)
    }

    // MARK: Attachments

    mutating func addScannedPage(_ data: Data) {
        attachments.append(
            AttachmentDraft(
                data: data,
                kind: .document,
                contentType: UTType.jpeg.identifier,
                displayName: String(localized: "扫描页 \(attachments.count + 1)"),
                source: .scanner
            )
        )
    }

    mutating func addImportedImage(_ data: Data, contentType: String) {
        attachments.append(
            AttachmentDraft(
                data: data,
                kind: .medicalImage,
                contentType: contentType,
                displayName: String(localized: "影像 \(attachments.count + 1)"),
                source: .photoLibrary
            )
        )
    }

    mutating func removeAttachment(id: AttachmentDraft.ID) {
        attachments.removeAll { $0.id == id }
    }

    // MARK: Saving

    /// The record this draft describes, with text trimmed. It's not inserted
    /// into any store.
    func makeRecord() -> HealthRecord {
        HealthRecord(
            occurredAt: occurredAt.value,
            hospitalName: hospitalName.value.trimmed,
            department: department.value.trimmed,
            doctorName: doctorName.value.trimmed,
            category: category.value.rawValue,
            medicalRecordNumber: medicalRecordNumber.value.trimmed,
            visitReason: visitReason.value.trimmed,
            diagnosisOrConclusion: diagnosisOrConclusion.value.trimmed,
            examinationResults: examinationResults.value.trimmed,
            medications: medications.value.trimmed,
            doctorAdvice: doctorAdvice.value.trimmed,
            followUpDate: followUpDate,
            notes: notes.trimmed,
            rawOCRText: rawOCRText.trimmed
        )
    }

    /// Inserts the record and its attachments, then saves explicitly, so a
    /// failed write reaches the patient instead of being lost (T-009).
    ///
    /// On failure only this draft's inserts are removed. Other unsaved
    /// changes in the context stay as they were, and a retry can't create
    /// a duplicate.
    func save(in context: ModelContext) throws {
        let record = makeRecord()
        let savedAttachments = attachments.enumerated().map { index, draft in
            RecordAttachment(
                sortOrder: index,
                kind: draft.kind.rawValue,
                contentType: draft.contentType,
                displayName: draft.displayName,
                source: draft.source.rawValue,
                data: draft.data,
                record: record
            )
        }

        context.insert(record)
        savedAttachments.forEach(context.insert)

        do {
            try context.save()
        } catch {
            savedAttachments.forEach(context.delete)
            context.delete(record)
            throw error
        }
    }
}
