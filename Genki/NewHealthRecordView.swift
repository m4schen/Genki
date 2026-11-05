import PhotosUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import VisionKit

/// The add-record form (UC1, UC2). It owns only UI state. Every rule about
/// the record lives in `RecordDraft`, where it's unit-tested.
struct NewHealthRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var draft = RecordDraft()

    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isShowingScanner = false
    @State private var isRecognizing = false
    @State private var isMoreExpanded = false
    @State private var isOCRExpanded = false
    @State private var errorMessage: String?
    @State private var saveErrorMessage: String?
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
                isPresented: isPresenting($errorMessage)
            ) {
                Button("好", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "请重试。")
            }
            .alert(
                "无法保存记录",
                isPresented: isPresenting($saveErrorMessage)
            ) {
                Button("好", role: .cancel) {}
            } message: {
                Text(saveErrorMessage ?? "请重试。")
            }
        }
    }

    // MARK: Sections

    private var basicsSection: some View {
        Section {
            Picker("记录类型", selection: binding(\.category)) {
                ForEach(HealthRecordCategory.allCases) { value in
                    Text(value.title).tag(value)
                }
            }
            .pickerStyle(.segmented)

            DatePicker("日期", selection: binding(\.occurredAt), displayedComponents: .date)

            TextField("医院或体检机构", text: binding(\.hospitalName))
                .textContentType(.organizationName)
                .submitLabel(.next)
                .focused($focusedField, equals: .hospital)
                .onSubmit { focusedField = .department }

            TextField("科室（可选）", text: binding(\.department))
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
                text: binding(\.diagnosisOrConclusion),
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
            if !draft.attachments.isEmpty {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 12) {
                        ForEach(draft.attachments) { attachment in
                            AttachmentDraftThumbnail(
                                attachment: attachment,
                                onDelete: {
                                    draft.removeAttachment(id: attachment.id)
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
                if !draft.attachments.isEmpty {
                    Text("\(draft.attachments.count) 项")
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
                    text: binding(\.visitReason),
                    axis: .vertical
                )
                .lineLimit(2...5)
                .focused($focusedField, equals: .reason)

                TextField(
                    "检查或检验结果",
                    text: binding(\.examinationResults),
                    axis: .vertical
                )
                .lineLimit(2...6)
                .focused($focusedField, equals: .results)

                TextField(
                    "医生建议或后续安排",
                    text: binding(\.doctorAdvice),
                    axis: .vertical
                )
                .lineLimit(2...5)
                .focused($focusedField, equals: .advice)

                TextField(
                    "处方或用药",
                    text: binding(\.medications),
                    axis: .vertical
                )
                .lineLimit(2...5)
                .focused($focusedField, equals: .medications)

                TextField("医生姓名", text: binding(\.doctorName))
                    .textContentType(.name)
                    .focused($focusedField, equals: .doctor)

                TextField("门诊号、住院号或报告编号", text: binding(\.medicalRecordNumber))
                    .focused($focusedField, equals: .recordNumber)

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
                    .focused($focusedField, equals: .notes)
            }
        }
    }

    private var ocrSection: some View {
        Section {
            DisclosureGroup("OCR 原文", isExpanded: $isOCRExpanded) {
                TextEditor(text: $draft.rawOCRText)
                    .frame(minHeight: 150)
                    .focused($focusedField, equals: .ocr)
            }
        } footer: {
            Text("识别结果可能有误，请对照原始资料核对。")
        }
    }

    // MARK: Bindings

    /// Routes the patient's edits through `setByUser`, so the draft knows
    /// the field is theirs and OCR must leave it alone.
    private func binding<Value>(
        _ field: WritableKeyPath<RecordDraft, DraftField<Value>>
    ) -> Binding<Value> {
        Binding(
            get: { draft[keyPath: field].value },
            set: { draft[keyPath: field].setByUser($0) }
        )
    }

    /// "Has a follow-up date" is derived from the optional date, so the
    /// toggle and the date can't disagree.
    private var hasFollowUpDate: Binding<Bool> {
        Binding(
            get: { draft.followUpDate != nil },
            set: { draft.followUpDate = $0 ? (draft.followUpDate ?? .now) : nil }
        )
    }

    private func isPresenting(_ message: Binding<String?>) -> Binding<Bool> {
        Binding(
            get: { message.wrappedValue != nil },
            set: { if !$0 { message.wrappedValue = nil } }
        )
    }

    // MARK: Keyboard focus

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

    // MARK: Actions

    private func addScannedPages(_ pages: [Data]) {
        pages.forEach { draft.addScannedPage($0) }
        recognizeText(in: pages)
    }

    private func importPhotos(_ items: [PhotosPickerItem]) {
        isRecognizing = true
        errorMessage = nil

        Task {
            do {
                var images: [Data] = []
                for item in items {
                    guard let data = try await item.loadTransferable(type: Data.self) else {
                        continue
                    }
                    let contentType = item.supportedContentTypes.first?.identifier
                        ?? UTType.image.identifier
                    draft.addImportedImage(data, contentType: contentType)
                    images.append(data)
                }

                selectedPhotos = []
                recognizeText(in: images)
            } catch {
                isRecognizing = false
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Runs on-device OCR on newly added images and hands the text to the
    /// draft, which decides which fields it may fill.
    private func recognizeText(in images: [Data]) {
        guard !images.isEmpty else {
            isRecognizing = false
            return
        }

        isRecognizing = true
        Task {
            defer { isRecognizing = false }
            do {
                let text = try await OCRService.recognize(imageData: images)
                draft.applyRecognizedText(text)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func save() {
        do {
            try draft.save(in: modelContext)
            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
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
