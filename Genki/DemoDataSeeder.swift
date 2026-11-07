import Foundation
import SwiftData
import UIKit

@MainActor
enum DemoDataSeeder {
    /// Inserts local sample records for development without touching a non-empty store.
    /// It runs at most once per `defaults`, so seeding is idempotent.
    ///
    /// - Returns: `true` when records were inserted, otherwise `false`.
    @discardableResult
    static func seedIfNeeded(
        in modelContext: ModelContext,
        defaults: UserDefaults = .standard
    ) throws -> Bool {
#if DEBUG
        let defaultsKey = "didSeedHealthRecordDemoData"
        guard !defaults.bool(forKey: defaultsKey) else {
            return false
        }

        var descriptor = FetchDescriptor<HealthRecord>()
        descriptor.fetchLimit = 1

        guard try modelContext.fetch(descriptor).isEmpty else {
            defaults.set(true, forKey: defaultsKey)
            return false
        }

        let records = makeRecords()
        records.forEach(modelContext.insert)

        addImageAsset(
            named: "DemoChestXray",
            to: records[0],
            in: modelContext
        )
        addImageAsset(
            named: "DemoFundus",
            to: records[1],
            in: modelContext
        )

        try modelContext.save()
        defaults.set(true, forKey: defaultsKey)
        return true
#else
        return false
#endif
    }

#if DEBUG
    private static func makeRecords() -> [HealthRecord] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        return [
            makeCheckupRecord(occurredAt: calendar.date(byAdding: .day, value: -18, to: today) ?? today),
            makeEyeTestRecord(
                occurredAt: calendar.date(byAdding: .day, value: -46, to: today) ?? today,
                followUpDate: calendar.date(byAdding: .month, value: 12, to: today)
            ),
            makeVisitRecord(occurredAt: calendar.date(byAdding: .day, value: -72, to: today) ?? today),
        ]
    }

    /// Annual checkup with a chest X-ray (the image is attached in `seedIfNeeded`).
    private static func makeCheckupRecord(occurredAt: Date) -> HealthRecord {
        HealthRecord(
            sourceLanguageCode: "zh-Hans",
            isDemo: true,
            occurredAt: occurredAt,
            hospitalName: "上海市第一人民医院",
            department: "健康管理中心",
            doctorName: "王医生",
            category: HealthRecordCategory.checkup.rawValue,
            medicalRecordNumber: "DEMO-2026-001",
            visitReason: "年度健康体检",
            diagnosisOrConclusion: "体检总体未见明显异常，建议保持规律作息并按年度复查。",
            examinationResults: """
            胸部 X 线：双肺纹理清晰，未见明显活动性病变。
            血常规、肝肾功能：主要指标在参考范围内。
            """,
            doctorAdvice: "均衡饮食、规律运动，每年复查一次。",
            notes: "演示记录：可搜索“第一人民医院”“体检”“胸片”或“胸部”。",
            rawOCRText: """
            上海市第一人民医院 健康体检报告
            检查项目：胸片、血常规、肝肾功能
            结论：胸部 X 线未见明显异常
            """
        )
    }

    /// Eye test with a fundus photo and a follow-up date.
    private static func makeEyeTestRecord(occurredAt: Date, followUpDate: Date?) -> HealthRecord {
        HealthRecord(
            sourceLanguageCode: "zh-Hans",
            isDemo: true,
            occurredAt: occurredAt,
            hospitalName: "复旦大学附属眼耳鼻喉科医院",
            department: "眼科",
            doctorName: "陈医生",
            category: HealthRecordCategory.test.rawValue,
            medicalRecordNumber: "DEMO-EYE-002",
            visitReason: "近期看远处容易疲劳，进行视力和眼底检查。",
            diagnosisOrConclusion: "双眼轻度近视，眼底未见明显异常。",
            examinationResults: """
            视力检查：右眼 0.8，左眼 0.8。
            眼底照相：视盘边界清，黄斑区未见明显异常。
            """,
            doctorAdvice: "注意用眼休息；若出现视物变形或黑影，应及时复诊。",
            followUpDate: followUpDate,
            notes: "演示记录：可搜索“眼科”“眼底”“近视”或“复旦”。",
            rawOCRText: """
            复旦大学附属眼耳鼻喉科医院 眼科检查报告
            项目：视力、眼压、眼底照相
            印象：双眼轻度近视，眼底未见明显异常
            """
        )
    }

    /// Outpatient visit with a prescription.
    private static func makeVisitRecord(occurredAt: Date) -> HealthRecord {
        HealthRecord(
            sourceLanguageCode: "zh-Hans",
            isDemo: true,
            occurredAt: occurredAt,
            hospitalName: "上海交通大学医学院附属瑞金医院",
            department: "普通内科",
            doctorName: "李医生",
            category: HealthRecordCategory.visit.rawValue,
            medicalRecordNumber: "DEMO-OPD-003",
            visitReason: "咽痛、鼻塞两天，无明显发热。",
            diagnosisOrConclusion: "急性上呼吸道感染。",
            examinationResults: "咽部轻度充血；肺部听诊未见明显异常。",
            medications: "对乙酰氨基酚片（必要时服用）。",
            doctorAdvice: "多饮水并充分休息；若持续高热或症状加重，及时复诊。",
            notes: "演示记录：可搜索“瑞金医院”“呼吸道感染”“咽痛”或药名。",
            rawOCRText: """
            瑞金医院 门诊病历
            主诉：咽痛、鼻塞两天
            诊断：急性上呼吸道感染
            """
        )
    }

    private static func addImageAsset(
        named assetName: String,
        to record: HealthRecord,
        in modelContext: ModelContext
    ) {
        guard
            let image = UIImage(named: assetName),
            let imageData = image.jpegData(compressionQuality: 0.9)
        else {
            return
        }

        let attachment = RecordAttachment(
            sortOrder: record.attachments.count,
            kind: AttachmentKind.medicalImage.rawValue,
            contentType: "public.jpeg",
            displayName: assetName == "DemoFundus" ? "眼底照相（演示）" : "胸部 X 线（演示）",
            source: AttachmentSource.demo.rawValue,
            data: imageData,
            record: record
        )
        modelContext.insert(attachment)
    }
#endif
}
