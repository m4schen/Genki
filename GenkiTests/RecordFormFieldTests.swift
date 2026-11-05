import Testing
@testable import Genki

struct RecordFormFieldTests {
    @Test("Collapsed sections are skipped by the keyboard's up/down buttons")
    func focusOrderSkipsCollapsedSections() {
        #expect(
            RecordFormField.focusOrder(isMoreExpanded: false, isOCRExpanded: false)
                == [.hospital, .department, .conclusion]
        )
        #expect(
            RecordFormField.focusOrder(isMoreExpanded: false, isOCRExpanded: true)
                == [.hospital, .department, .conclusion, .ocr]
        )
        #expect(
            RecordFormField.focusOrder(isMoreExpanded: true, isOCRExpanded: false).count == 10
        )
    }

    @Test("Up and down move one field, and stop at either end")
    func adjacentFields() {
        let order = RecordFormField.focusOrder(isMoreExpanded: false, isOCRExpanded: false)

        #expect(RecordFormField.department.adjacent(by: 1, in: order) == .conclusion)
        #expect(RecordFormField.department.adjacent(by: -1, in: order) == .hospital)
        #expect(RecordFormField.hospital.adjacent(by: -1, in: order) == nil)
        #expect(RecordFormField.conclusion.adjacent(by: 1, in: order) == nil)
        #expect(RecordFormField.notes.adjacent(by: 1, in: order) == nil)
    }
}
