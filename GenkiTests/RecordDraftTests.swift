import Foundation
import SwiftData
import Testing
@testable import Genki

/// The add-record form's rules (UC1, ARCHITECTURE.md §4). Fictional data only.
struct RecordDraftTests {
    private let pickedDate = Date(timeIntervalSince1970: 1_767_225_600)
    private let reportDate = Date(timeIntervalSince1970: 1_772_668_800)

    // MARK: Field origin (T-038)

    @Test("A date the patient picked survives OCR")
    func pickedDateSurvivesOCR() {
        var draft = RecordDraft()
        draft.occurredAt.setByUser(pickedDate)

        draft.apply(ExtractedHealthFields(occurredAt: reportDate))

        #expect(draft.occurredAt.value == pickedDate)
        #expect(draft.occurredAt.origin == .userOwned)
    }

    @Test("OCR fills the untouched default date and marks it as a suggestion")
    func defaultDateIsFilled() {
        var draft = RecordDraft()

        draft.apply(ExtractedHealthFields(occurredAt: reportDate))

        #expect(draft.occurredAt.value == reportDate)
        #expect(draft.occurredAt.origin == .suggestedByOCR)
    }

    @Test("A category the patient chose survives OCR, even when it's 'visit'")
    func chosenCategorySurvivesOCR() {
        var draft = RecordDraft()
        draft.category.setByUser(.visit)

        draft.apply(ExtractedHealthFields(category: .checkup))

        #expect(draft.category.value == .visit)
    }

    @Test("OCR replaces the untouched default category")
    func defaultCategoryIsReplaced() {
        var draft = RecordDraft()

        draft.apply(ExtractedHealthFields(category: .checkup))

        #expect(draft.category.value == .checkup)
        #expect(draft.category.origin == .suggestedByOCR)
    }

    @Test("OCR fills empty text fields but never what the patient typed")
    func textFieldsRespectThePatient() {
        var draft = RecordDraft()
        draft.hospitalName.setByUser("我自己填写的医院")

        draft.apply(ExtractedHealthFields(hospitalName: "示例医院", department: "眼科"))

        #expect(draft.hospitalName.value == "我自己填写的医院")
        #expect(draft.department.value == "眼科")
        #expect(draft.department.origin == .suggestedByOCR)
    }

    @Test("A second scan doesn't overwrite the first scan's suggestion")
    func firstSuggestionWins() {
        var draft = RecordDraft()

        draft.apply(ExtractedHealthFields(department: "眼科"))
        draft.apply(ExtractedHealthFields(department: "内科"))

        #expect(draft.department.value == "眼科")
    }

    @Test("Clearing a field hands it back to OCR")
    func clearingReturnsFieldToDefault() {
        var draft = RecordDraft()
        draft.department.setByUser("眼科")
        draft.department.setByUser("   ")

        #expect(draft.department.origin == .defaultValue)

        draft.apply(ExtractedHealthFields(department: "内科"))

        #expect(draft.department.value == "内科")
    }

    // MARK: Recognized text and attachments

    @Test("Recognized text from several scans is kept and applied")
    func appliesRecognizedText() {
        var draft = RecordDraft()

        draft.applyRecognizedText("科室：眼科")
        draft.applyRecognizedText("诊断：双眼轻度近视")
        draft.applyRecognizedText("")

        #expect(draft.rawOCRText == "科室：眼科\n\n诊断：双眼轻度近视")
        #expect(draft.department.value == "眼科")
        #expect(draft.diagnosisOrConclusion.value == "双眼轻度近视")
    }

    @Test("Attachments are numbered in the order they were added")
    func numbersAttachments() {
        var draft = RecordDraft()

        draft.addScannedPage(Data([1]))
        draft.addScannedPage(Data([2]))
        draft.addImportedImage(Data([3]), contentType: "public.png")

        #expect(draft.attachments.map(\.displayName) == ["扫描页 1", "扫描页 2", "影像 3"])
        #expect(draft.attachments.map(\.kind) == [.document, .document, .medicalImage])
        #expect(draft.attachments.map(\.source) == [.scanner, .scanner, .photoLibrary])
    }

    @Test("Removing an attachment removes only that one")
    func removesAttachment() throws {
        var draft = RecordDraft()
        draft.addScannedPage(Data([1]))
        draft.addScannedPage(Data([2]))
        let first = try #require(draft.attachments.first)

        draft.removeAttachment(id: first.id)

        #expect(draft.attachments.map(\.data) == [Data([2])])
    }

    // MARK: Saving (T-009)

    @Test("Saving stores one trimmed record with its attachments in order")
    func savesRecord() throws {
        let container = try TestStore.makeContainer()
        let context = container.mainContext
        var draft = RecordDraft()
        draft.hospitalName.setByUser("  示例医院  ")
        draft.category.setByUser(.test)
        draft.notes = " 个人备注 "
        draft.addScannedPage(Data([1]))
        draft.addImportedImage(Data([2]), contentType: "public.png")

        try draft.save(in: context)

        let records = try context.fetch(FetchDescriptor<HealthRecord>())
        let record = try #require(records.first)
        let attachments = record.attachments.sorted { $0.sortOrder < $1.sortOrder }
        #expect(records.count == 1)
        #expect(record.hospitalName == "示例医院")
        #expect(record.notes == "个人备注")
        #expect(record.category == HealthRecordCategory.test.rawValue)
        #expect(record.followUpDate == nil)
        #expect(attachments.map(\.imageData) == [Data([1]), Data([2])])
        #expect(attachments.map(\.source) == ["scanner", "photoLibrary"])
        #expect(attachments.map(\.contentType) == ["public.jpeg", "public.png"])
    }

    @Test("A follow-up date is saved only when one is set")
    func savesFollowUpDate() throws {
        let container = try TestStore.makeContainer()
        let context = container.mainContext
        var draft = RecordDraft()
        draft.followUpDate = reportDate

        try draft.save(in: context)

        let record = try #require(try context.fetch(FetchDescriptor<HealthRecord>()).first)
        #expect(record.followUpDate == reportDate)
    }
}
