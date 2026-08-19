import SwiftUI
import UIKit

struct HealthRecordDetailView: View {
    let record: HealthRecord

    @State private var selectedAttachment: RecordAttachment?
    @State private var isOCRExpanded = false

    private var sortedAttachments: [RecordAttachment] {
        record.attachments.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var hasRecordDetails: Bool {
        [
            record.visitReason,
            record.examinationResults,
            record.doctorAdvice,
            record.medications,
            record.notes,
        ].contains { !$0.isEmpty }
    }

    private var hasInstitutionDetails: Bool {
        !record.department.isEmpty
            || !record.doctorName.isEmpty
            || !record.medicalRecordNumber.isEmpty
            || record.followUpDate != nil
    }

    var body: some View {
        List {
            Section {
                RecordSummaryHeader(record: record)
                    .listRowInsets(
                        EdgeInsets(top: 18, leading: 20, bottom: 18, trailing: 20)
                    )
            }

            if !sortedAttachments.isEmpty {
                Section {
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 12) {
                            ForEach(sortedAttachments) { attachment in
                                Button {
                                    selectedAttachment = attachment
                                } label: {
                                    AttachmentThumbnail(attachment: attachment)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .scrollIndicators(.hidden)
                } header: {
                    Text("资料与影像")
                }
            }

            if hasRecordDetails {
                Section("记录详情") {
                    DetailBlock(title: "原因 / 主要症状", value: record.visitReason)
                    DetailBlock(
                        title: "检查 / 检验结果",
                        value: record.examinationResults
                    )
                    DetailBlock(
                        title: "医生建议 / 后续安排",
                        value: record.doctorAdvice
                    )
                    DetailBlock(title: "处方 / 用药", value: record.medications)
                    DetailBlock(title: "个人备注", value: record.notes)
                }
            }

            if hasInstitutionDetails {
                Section("更多信息") {
                    DetailRow(title: "科室", value: record.department)
                    DetailRow(title: "医生", value: record.doctorName)
                    DetailRow(title: "院方记录号", value: record.medicalRecordNumber)
                    if let followUpDate = record.followUpDate {
                        LabeledContent("复查日期") {
                            Text(
                                followUpDate,
                                format: .dateTime.year().month().day()
                            )
                        }
                    }
                }
            }

            if !record.rawOCRText.isEmpty {
                Section {
                    DisclosureGroup("OCR 原文", isExpanded: $isOCRExpanded) {
                        Text(record.rawOCRText)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(record.categoryTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedAttachment) { attachment in
            AttachmentViewer(attachment: attachment)
        }
    }
}

private struct RecordSummaryHeader: View {
    let record: HealthRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: record.categoryValue.symbolName)
                    .font(.title3)
                    .foregroundStyle(record.categoryValue.tint)
                    .frame(width: 42, height: 42)
                    .background(record.categoryValue.tint.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 7) {
                        Text(record.categoryTitle)
                            .font(.headline)
                        if record.isDemo {
                            Text("演示")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.orange.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }

                    Text(record.occurredAt, format: .dateTime.year().month().day())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Text(
                record.hospitalName.isEmpty
                    ? String(localized: "未填写医院 / 机构")
                    : record.hospitalName
            )
            .font(.title3.weight(.semibold))

            if !record.diagnosisOrConclusion.isEmpty {
                Text(record.diagnosisOrConclusion)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct AttachmentThumbnail: View {
    let attachment: RecordAttachment

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Group {
                if let image = UIImage(data: attachment.data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: attachment.kindValue.symbolName)
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 150, height: 116)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(
                attachment.displayName.isEmpty
                    ? attachment.kindTitle
                    : attachment.displayName
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .frame(width: 150, alignment: .leading)
        }
    }
}

private struct AttachmentViewer: View {
    @Environment(\.dismiss) private var dismiss
    let attachment: RecordAttachment

    var body: some View {
        NavigationStack {
            Group {
                if let image = UIImage(data: attachment.data) {
                    ScrollView([.horizontal, .vertical]) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .containerRelativeFrame([.horizontal, .vertical])
                    }
                    .background(.black)
                } else {
                    ContentUnavailableView(
                        "无法预览",
                        systemImage: "doc.questionmark",
                        description: Text("该资料类型暂不支持预览。")
                    )
                }
            }
            .navigationTitle(
                attachment.displayName.isEmpty
                    ? attachment.kindTitle
                    : attachment.displayName
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        if !value.isEmpty {
            LabeledContent(title, value: value)
        }
    }
}

private struct DetailBlock: View {
    let title: String
    let value: String

    var body: some View {
        if !value.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(value)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 3)
        }
    }
}
