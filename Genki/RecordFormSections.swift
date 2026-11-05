import SwiftUI

// The add-record form's text sections. Each one is a small view that edits
// the shared `RecordDraft` through `field(_:)`, so every edit is recorded as
// the patient's own (non-negotiable 6).

extension Binding where Value == RecordDraft {
    /// A binding to one field's value. Writes go through `setByUser`, so OCR
    /// knows the field is the patient's and leaves it alone.
    func field<FieldValue>(
        _ keyPath: WritableKeyPath<RecordDraft, DraftField<FieldValue>>
    ) -> Binding<FieldValue> {
        Binding<FieldValue>(
            get: { wrappedValue[keyPath: keyPath].value },
            set: { wrappedValue[keyPath: keyPath].setByUser($0) }
        )
    }
}

// MARK: - Basics

struct RecordBasicsSection: View {
    @Binding var draft: RecordDraft
    var focusedField: FocusState<RecordFormField?>.Binding

    var body: some View {
        Section {
            Picker("记录类型", selection: $draft.field(\.category)) {
                ForEach(HealthRecordCategory.allCases) { value in
                    Text(value.title).tag(value)
                }
            }
            .pickerStyle(.segmented)

            DatePicker("日期", selection: $draft.field(\.occurredAt), displayedComponents: .date)

            TextField("医院或体检机构", text: $draft.field(\.hospitalName))
                .textContentType(.organizationName)
                .submitLabel(.next)
                .focused(focusedField, equals: .hospital)
                .onSubmit { focusedField.wrappedValue = .department }

            TextField("科室（可选）", text: $draft.field(\.department))
                .submitLabel(.next)
                .focused(focusedField, equals: .department)
                .onSubmit { focusedField.wrappedValue = .conclusion }
        } header: {
            Text("基本信息")
        }
    }
}

// MARK: - Conclusion

struct RecordConclusionSection: View {
    @Binding var draft: RecordDraft
    var focusedField: FocusState<RecordFormField?>.Binding

    var body: some View {
        Section {
            TextField(
                "例如：未见明显异常、轻度近视、建议复查",
                text: $draft.field(\.diagnosisOrConclusion),
                axis: .vertical
            )
            .lineLimit(3...6)
            .focused(focusedField, equals: .conclusion)
        } header: {
            Text("诊断或结论")
        } footer: {
            Text("体检和检查没有疾病诊断时，直接记录报告结论。")
        }
    }
}

// MARK: - More information

struct RecordMoreSection: View {
    @Binding var draft: RecordDraft
    @Binding var isExpanded: Bool
    var focusedField: FocusState<RecordFormField?>.Binding

    var body: some View {
        Section {
            DisclosureGroup("更多信息", isExpanded: $isExpanded) {
                TextField("就诊原因或主要症状", text: $draft.field(\.visitReason), axis: .vertical)
                    .lineLimit(2...5)
                    .focused(focusedField, equals: .reason)

                TextField("检查或检验结果", text: $draft.field(\.examinationResults), axis: .vertical)
                    .lineLimit(2...6)
                    .focused(focusedField, equals: .results)

                TextField("医生建议或后续安排", text: $draft.field(\.doctorAdvice), axis: .vertical)
                    .lineLimit(2...5)
                    .focused(focusedField, equals: .advice)

                TextField("处方或用药", text: $draft.field(\.medications), axis: .vertical)
                    .lineLimit(2...5)
                    .focused(focusedField, equals: .medications)

                TextField("医生姓名", text: $draft.field(\.doctorName))
                    .textContentType(.name)
                    .focused(focusedField, equals: .doctor)

                TextField("门诊号、住院号或报告编号", text: $draft.field(\.medicalRecordNumber))
                    .focused(focusedField, equals: .recordNumber)

                Toggle("记录复查日期", isOn: hasFollowUpDate)
                if let followUpDate = draft.followUpDate {
                    DatePicker(
                        "复查日期",
                        selection: Binding(
                            get: { followUpDate },
                            set: { draft.followUpDate = $0 }
                        ),
                        displayedComponents: .date
                    )
                }

                TextField("个人备注", text: $draft.notes, axis: .vertical)
                    .lineLimit(2...5)
                    .focused(focusedField, equals: .notes)
            }
        }
    }

    /// "Has a follow-up date" is derived from the optional date, so the
    /// toggle and the date can't disagree.
    private var hasFollowUpDate: Binding<Bool> {
        Binding(
            get: { draft.followUpDate != nil },
            set: { draft.followUpDate = $0 ? (draft.followUpDate ?? .now) : nil }
        )
    }
}

// MARK: - OCR original

struct RecordOCRSection: View {
    @Binding var draft: RecordDraft
    @Binding var isExpanded: Bool
    var focusedField: FocusState<RecordFormField?>.Binding

    var body: some View {
        Section {
            DisclosureGroup("OCR 原文", isExpanded: $isExpanded) {
                TextEditor(text: $draft.rawOCRText)
                    .frame(minHeight: 150)
                    .focused(focusedField, equals: .ocr)
            }
        } footer: {
            Text("识别结果可能有误，请对照原始资料核对。")
        }
    }
}
