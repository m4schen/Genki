import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HealthRecord.occurredAt, order: .reverse)
    private var records: [HealthRecord]

    @State private var searchText = ""
    @State private var isShowingNewRecord = false
    @State private var demoSeedError: String?

    private var filteredRecords: [HealthRecord] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return records }

        return records.filter { record in
            [
                record.hospitalName,
                record.department,
                record.doctorName,
                record.categoryTitle,
                record.visitReason,
                record.diagnosisOrConclusion,
                record.examinationResults,
                record.medications,
                record.doctorAdvice,
                record.notes,
                record.rawOCRText,
            ]
            .contains { $0.localizedStandardContains(query) }
        }
    }

    private var monthSections: [RecordMonthSection] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: filteredRecords) { record in
            calendar.dateInterval(of: .month, for: record.occurredAt)?.start
                ?? calendar.startOfDay(for: record.occurredAt)
        }

        return groups
            .map { RecordMonthSection(month: $0.key, records: $0.value) }
            .sorted { $0.month > $1.month }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredRecords.isEmpty {
                    ContentUnavailableView {
                        Label(
                            searchText.trimmed.isEmpty
                                ? "还没有健康记录"
                                : "没有搜索结果",
                            systemImage: searchText.trimmed.isEmpty
                                ? "heart.text.clipboard"
                                : "magnifyingglass"
                        )
                    } description: {
                        Text(
                            searchText.trimmed.isEmpty
                                ? "把不同医院的就诊、体检和检查集中在这里。"
                                : "可以搜索医院、诊断、检查结果、药名或 OCR 原文。"
                        )
                    } actions: {
                        if searchText.trimmed.isEmpty {
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
                                    deleteRecords(offsets, from: section.records)
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
                isPresented: Binding(
                    get: { demoSeedError != nil },
                    set: { if !$0 { demoSeedError = nil } }
                )
            ) {
                Button("好", role: .cancel) {}
            } message: {
                Text(demoSeedError ?? "")
            }
        }
    }

    private func deleteRecords(_ offsets: IndexSet, from section: [HealthRecord]) {
        withAnimation {
            for index in offsets {
                modelContext.delete(section[index])
            }
        }
    }
}

private struct RecordMonthSection: Identifiable {
    let month: Date
    let records: [HealthRecord]

    var id: Date { month }
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
