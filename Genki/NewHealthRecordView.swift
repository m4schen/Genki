import PhotosUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import VisionKit

struct NewHealthRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var occurredAt = Date.now
    @State private var hospitalName = ""
    @State private var department = ""
    @State private var category = HealthRecordCategory.visit.rawValue
    @State private var diagnosisOrConclusion = ""

    @State private var visitReason = ""
    @State private var examinationResults = ""
    @State private var medications = ""
    @State private var doctorAdvice = ""
    @State private var doctorName = ""
    @State private var medicalRecordNumber = ""
    @State private var hasFollowUpDate = false
    @State private var followUpDate = Date.now
    @State private var notes = ""
    @State private var rawOCRText = ""

    @State private var attachments: [AttachmentDraft] = []
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isShowingScanner = false
    @State private var isRecognizing = false
    @State private var isMoreExpanded = false
    @State private var isOCRExpanded = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: InputField?

    var body: some View {
        NavigationStack {
            Form {
                basicsSection
                conclusionSection
                attachmentsSection
                moreSection
                ocrSection
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("添加记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                    .disabled(isRecognizing)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .disabled(isRecognizing)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Button {
                        moveFocus(by: -1)
                    } label: {
                        Image(systemName: "chevron.up")
                    }
                    .disabled(previousField == nil)

                    Button {
                        moveFocus(by: 1)
                    } label: {
                        Image(systemName: "chevron.down")
                    }
                    .disabled(nextField == nil)

                    Spacer()

                    Button("完成") {
                        focusedField = nil
                    }
                }
            }
            .interactiveDismissDisabled(isRecognizing)
            .sheet(isPresented: $isShowingScanner) {
                DocumentScannerView(
                    onComplete: { pages in
                        isShowingScanner = false
                        addScannedPages(pages)
                    },
                    onCancel: {
                        isShowingScanner = false
                    }
                )
                .ignoresSafeArea()
            }
            .onChange(of: selectedPhotos) { _, items in
                guard !items.isEmpty else { return }
                importPhotos(items)
            }
            .alert(
                "无法处理资料",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("好", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "请重试。")
            }
        }
    }

    private var basicsSection: some View {
        Section {
            Picker("记录类型", selection: $category) {
                ForEach(HealthRecordCategory.allCases) { value in
                    Text(value.title).tag(value.rawValue)
                }
            }
            .pickerStyle(.segmented)

            DatePicker("日期", selection: $occurredAt, displayedComponents: .date)

            TextField("医院或体检机构", text: $hospitalName)
                .textContentType(.organizationName)
                .submitLabel(.next)
                .focused($focusedField, equals: .hospital)
                .onSubmit { focusedField = .department }

            TextField("科室（可选）", text: $department)
                .submitLabel(.next)
                .focused($focusedField, equals: .department)
                .onSubmit { focusedField = .conclusion }
        } header: {
            Text("基本信息")
        }
    }

    private var conclusionSection: some View {
        Section {
            TextField(
                "例如：未见明显异常、轻度近视、建议复查",
                text: $diagnosisOrConclusion,
                axis: .vertical
            )
            .lineLimit(3...6)
            .focused($focusedField, equals: .conclusion)
        } header: {
            Text("诊断或结论")
        } footer: {
            Text("体检和检查没有疾病诊断时，直接记录报告结论。")
        }
    }

    private var attachmentsSection: some View {
        Section {
            if !attachments.isEmpty {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 12) {
                        ForEach(attachments) { attachment in
                            AttachmentDraftThumbnail(
                                attachment: attachment,
                                onDelete: {
                                    attachments.removeAll { $0.id == attachment.id }
                                }
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
            }

            if VNDocumentCameraViewController.isSupported {
                Button {
                    focusedField = nil
                    isShowingScanner = true
                } label: {
                    Label("扫描纸质记录", systemImage: "doc.viewfinder")
                }
            }

            PhotosPicker(
                selection: $selectedPhotos,
                maxSelectionCount: 20,
                matching: .images
            ) {
                Label("添加照片或医学影像", systemImage: "photo.on.rectangle.angled")
            }

            if isRecognizing {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("正在本机识别…")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            HStack {
                Text("资料与影像")
                Spacer()
                if !attachments.isEmpty {
                    Text("\(attachments.count) 项")
                }
            }
        } footer: {
            Text("病历照片、胸片和眼底图都会保留原图；OCR 仅用于辅助填写。")
        }
    }

    private var moreSection: some View {
        Section {
            DisclosureGroup("更多信息", isExpanded: $isMoreExpanded) {
                TextField(
                    "就诊原因或主要症状",
                    text: $visitReason,
                    axis: .vertical
                )
                .lineLimit(2...5)
                .focused($focusedField, equals: .reason)

                TextField(
                    "检查或检验结果",
                    text: $examinationResults,
                    axis: .vertical
                )
                .lineLimit(2...6)
                .focused($focusedField, equals: .results)

                TextField(
                    "医生建议或后续安排",
                    text: $doctorAdvice,
                    axis: .vertical
                )
                .lineLimit(2...5)
                .focused($focusedField, equals: .advice)

                TextField(
                    "处方或用药",
                    text: $medications,
                    axis: .vertical
                )
                .lineLimit(2...5)
                .focused($focusedField, equals: .medications)

                TextField("医生姓名", text: $doctorName)
                    .textContentType(.name)
                    .focused($focusedField, equals: .doctor)

                TextField("门诊号、住院号或报告编号", text: $medicalRecordNumber)
                    .focused($focusedField, equals: .recordNumber)

                Toggle("记录复查日期", isOn: $hasFollowUpDate)
                if hasFollowUpDate {
                    DatePicker(
                        "复查日期",
                        selection: $followUpDate,
                        displayedComponents: .date
                    )
                }

                TextField("个人备注", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
                    .focused($focusedField, equals: .notes)
            }
        }
    }

    private var ocrSection: some View {
        Section {
            DisclosureGroup("OCR 原文", isExpanded: $isOCRExpanded) {
                TextEditor(text: $rawOCRText)
                    .frame(minHeight: 150)
                    .focused($focusedField, equals: .ocr)
            }
        } footer: {
            Text("识别结果可能有误，请对照原始资料核对。")
        }
    }

    private var focusOrder: [InputField] {
        var fields: [InputField] = [.hospital, .department, .conclusion]
        if isMoreExpanded {
            fields += [
                .reason,
                .results,
                .advice,
                .medications,
                .doctor,
                .recordNumber,
                .notes,
            ]
        }
        if isOCRExpanded {
            fields.append(.ocr)
        }
        return fields
    }

    private var previousField: InputField? {
        adjacentField(offset: -1)
    }

    private var nextField: InputField? {
        adjacentField(offset: 1)
    }

    private func adjacentField(offset: Int) -> InputField? {
        guard
            let focusedField,
            let index = focusOrder.firstIndex(of: focusedField)
        else {
            return nil
        }

        let destination = index + offset
        guard focusOrder.indices.contains(destination) else { return nil }
        return focusOrder[destination]
    }

    private func moveFocus(by offset: Int) {
        focusedField = adjacentField(offset: offset)
    }

    private func addScannedPages(_ pages: [Data]) {
        let drafts = pages.enumerated().map { index, data in
            AttachmentDraft(
                data: data,
                kind: .document,
                contentType: UTType.jpeg.identifier,
                displayName: "扫描页 \(attachments.count + index + 1)",
                source: .scanner
            )
        }
        add(drafts, recognizeText: true)
    }

    private func importPhotos(_ items: [PhotosPickerItem]) {
        isRecognizing = true
        errorMessage = nil

        Task {
            do {
                var drafts: [AttachmentDraft] = []
                for (index, item) in items.enumerated() {
                    guard let data = try await item.loadTransferable(type: Data.self) else {
                        continue
                    }
                    drafts.append(
                        AttachmentDraft(
                            data: data,
                            kind: .medicalImage,
                            contentType: item.supportedContentTypes.first?.identifier
                                ?? UTType.image.identifier,
                            displayName: "影像 \(attachments.count + index + 1)",
                            source: .photoLibrary
                        )
                    )
                }

                selectedPhotos = []
                add(drafts, recognizeText: true)
            } catch {
                isRecognizing = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func add(_ drafts: [AttachmentDraft], recognizeText: Bool) {
        guard !drafts.isEmpty else {
            isRecognizing = false
            return
        }

        attachments.append(contentsOf: drafts)
        guard recognizeText else {
            isRecognizing = false
            return
        }

        isRecognizing = true
        Task {
            do {
                let text = try await OCRService.recognize(
                    imageData: drafts.map(\.data)
                )
                if !text.isEmpty {
                    rawOCRText = rawOCRText.isEmpty ? text : rawOCRText + "\n\n" + text
                    apply(HealthFieldExtractor.extract(from: text))
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isRecognizing = false
        }
    }

    private func apply(_ fields: ExtractedHealthFields) {
        if let date = fields.occurredAt {
            occurredAt = date
        }
        fillIfEmpty(&hospitalName, with: fields.hospitalName)
        fillIfEmpty(&department, with: fields.department)
        fillIfEmpty(&doctorName, with: fields.doctorName)
        fillIfEmpty(&medicalRecordNumber, with: fields.medicalRecordNumber)
        fillIfEmpty(&visitReason, with: fields.visitReason)
        fillIfEmpty(&diagnosisOrConclusion, with: fields.diagnosisOrConclusion)
        fillIfEmpty(&examinationResults, with: fields.examinationResults)
        fillIfEmpty(&medications, with: fields.medications)
        fillIfEmpty(&doctorAdvice, with: fields.doctorAdvice)
        if category == HealthRecordCategory.visit.rawValue, let suggested = fields.category {
            category = suggested.rawValue
        }
    }

    private func fillIfEmpty(_ target: inout String, with value: String?) {
        guard target.trimmed.isEmpty else { return }
        target = value ?? target
    }

    private func save() {
        let record = HealthRecord(
            occurredAt: occurredAt,
            hospitalName: hospitalName.trimmed,
            department: department.trimmed,
            doctorName: doctorName.trimmed,
            category: category,
            medicalRecordNumber: medicalRecordNumber.trimmed,
            visitReason: visitReason.trimmed,
            diagnosisOrConclusion: diagnosisOrConclusion.trimmed,
            examinationResults: examinationResults.trimmed,
            medications: medications.trimmed,
            doctorAdvice: doctorAdvice.trimmed,
            followUpDate: hasFollowUpDate ? followUpDate : nil,
            notes: notes.trimmed,
            rawOCRText: rawOCRText.trimmed
        )
        modelContext.insert(record)

        for (index, draft) in attachments.enumerated() {
            modelContext.insert(
                RecordAttachment(
                    sortOrder: index,
                    kind: draft.kind.rawValue,
                    contentType: draft.contentType,
                    displayName: draft.displayName,
                    source: draft.source.rawValue,
                    data: draft.data,
                    record: record
                )
            )
        }

        dismiss()
    }
}

private enum InputField: Hashable {
    case hospital
    case department
    case conclusion
    case reason
    case results
    case advice
    case medications
    case doctor
    case recordNumber
    case notes
    case ocr
}

private struct AttachmentDraft: Identifiable {
    let id = UUID()
    let data: Data
    let kind: AttachmentKind
    let contentType: String
    let displayName: String
    let source: AttachmentSource
}

private struct AttachmentDraftThumbnail: View {
    let attachment: AttachmentDraft
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let image = UIImage(data: attachment.data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "doc")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 88, height: 104)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.55))
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .padding(5)
            .accessibilityLabel("移除\(attachment.displayName)")
        }
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
