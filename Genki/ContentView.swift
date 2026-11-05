import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HealthRecord.occurredAt, order: .reverse)
    private var records: [HealthRecord]

    @State private var searchText = ""
    @State private var isShowingNewRecord = false
    @State private var demoSeedError: String?
    @State private var pendingDeletion: [HealthRecord]?
    @State private var deletionError: String?

    private var filteredRecords: [HealthRecord] {
        RecordTimeline.filter(records, matching: searchText)
    }

    private var monthSections: [RecordMonthSection] {
        RecordTimeline.monthSections(of: filteredRecords)
    }

    private var isSearching: Bool {
        !searchText.trimmed.isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredRecords.isEmpty {
                    ContentUnavailableView {
                        Label(
                            isSearching ? "没有搜索结果" : "还没有健康记录",
                            systemImage: isSearching ? "magnifyingglass" : "heart.text.clipboard"
                        )
                    } description: {
                        Text(
                            isSearching
                                ? "可以搜索医院、诊断、检查结果、药名或 OCR 原文。"
                                : "把不同医院的就诊、体检和检查集中在这里。"
                        )
                    } actions: {
                        if !isSearching {
                            Button("添加记录") {
                                isShowingNewRecord = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                } else {
                    List {
                        ForEach(monthSections) { section in
                            Section {
                                ForEach(section.records) { record in
                                    NavigationLink {
                                        HealthRecordDetailView(record: record)
                                    } label: {
                                        HealthRecordRow(record: record)
                                    }
                                }
                                .onDelete { offsets in
                                    pendingDeletion = offsets.map { section.records[$0] }
                                }
                            } header: {
                                Text(
                                    section.month,
                                    format: .dateTime.year().month(.wide)
                                )
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("健康记录")
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "搜索医院、诊断或检查结果"
            )
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingNewRecord = true
                    } label: {
                        Label("添加记录", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingNewRecord) {
                NewHealthRecordView()
            }
            .task {
                do {
                    try DemoDataSeeder.seedIfNeeded(in: modelContext)
                } catch {
                    demoSeedError = error.localizedDescription
                }
            }
            .alert(
                "演示数据载入失败",
                isPresented: Binding(isPresenting: $demoSeedError)
            ) {
                Button("好", role: .cancel) {}
            } message: {
                Text(demoSeedError ?? "")
            }
            .confirmationDialog(
                "删除这条记录？",
                isPresented: Binding(isPresenting: $pendingDeletion),
                titleVisibility: .visible,
                presenting: pendingDeletion
            ) { records in
                Button("删除", role: .destructive) {
                    delete(records)
                }
                Button("取消", role: .cancel) {}
            } message: { _ in
                Text("记录和其中的资料会从本机删除，无法恢复。")
            }
            .alert(
                "无法删除记录",
                isPresented: Binding(isPresenting: $deletionError)
            ) {
                Button("好", role: .cancel) {}
            } message: {
                Text(deletionError ?? "")
            }
        }
    }

    /// Runs only after the patient confirms (non-negotiable 3). It saves
    /// explicitly. If the save fails, the deletion is rolled back so the
    /// records reappear instead of being half-deleted.
    private func delete(_ records: [HealthRecord]) {
        withAnimation {
            records.forEach(modelContext.delete)
        }

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            deletionError = error.localizedDescription
        }
    }
}

private struct HealthRecordRow: View {
    let record: HealthRecord

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: record.categoryValue.symbolName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(record.categoryValue.tint)
                .frame(width: 38, height: 38)
                .background(record.categoryValue.tint.opacity(0.12))
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Text(
                        record.hospitalName.isEmpty
                            ? String(localized: "未填写医院 / 机构")
                            : record.hospitalName
                    )
                    .font(.headline)
                    .lineLimit(1)

                    if record.isDemo {
                        Text("演示")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }

                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(summaryIsEmpty ? .tertiary : .secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(record.categoryTitle)

                    if !record.department.isEmpty {
                        Text(record.department)
                    }

                    if !record.attachments.isEmpty {
                        Label(
                            "\(record.attachments.count)",
                            systemImage: "paperclip"
                        )
                    }
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
            }

            Spacer(minLength: 4)

            Text(record.occurredAt, format: .dateTime.day())
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 5)
        .accessibilityElement(children: .combine)
    }

    private var summary: String {
        if !record.diagnosisOrConclusion.isEmpty {
            return record.diagnosisOrConclusion
        }
        if !record.visitReason.isEmpty {
            return record.visitReason
        }
        return String(localized: "尚未填写诊断或结论")
    }

    private var summaryIsEmpty: Bool {
        record.diagnosisOrConclusion.isEmpty && record.visitReason.isEmpty
    }
}

#Preview {
    ContentView()
        .modelContainer(
            for: [HealthRecord.self, RecordAttachment.self],
            inMemory: true
        )
}
