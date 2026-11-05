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
    @FocusState private var focusedField: RecordFormField?

    var body: some View {
        NavigationStack {
            Form {
                RecordBasicsSection(draft: $draft, focusedField: $focusedField)
                RecordConclusionSection(draft: $draft, focusedField: $focusedField)
                attachmentsSection
                RecordMoreSection(
                    draft: $draft,
                    isExpanded: $isMoreExpanded,
                    focusedField: $focusedField
                )
                RecordOCRSection(
                    draft: $draft,
                    isExpanded: $isOCRExpanded,
                    focusedField: $focusedField
                )
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
                    },
                    onFailure: { error in
                        isShowingScanner = false
                        errorMessage = error.localizedDescription
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
                isPresented: Binding(isPresenting: $errorMessage)
            ) {
                Button("好", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "请重试。")
            }
            .alert(
                "无法保存记录",
                isPresented: Binding(isPresenting: $saveErrorMessage)
            ) {
                Button("好", role: .cancel) {}
            } message: {
                Text(saveErrorMessage ?? "请重试。")
            }
        }
    }

    // MARK: Sections

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

    // MARK: Keyboard focus

    private var focusOrder: [RecordFormField] {
        RecordFormField.focusOrder(isMoreExpanded: isMoreExpanded, isOCRExpanded: isOCRExpanded)
    }

    private var previousField: RecordFormField? {
        focusedField?.adjacent(by: -1, in: focusOrder)
    }

    private var nextField: RecordFormField? {
        focusedField?.adjacent(by: 1, in: focusOrder)
    }

    private func moveFocus(by offset: Int) {
        focusedField = focusedField?.adjacent(by: offset, in: focusOrder)
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
