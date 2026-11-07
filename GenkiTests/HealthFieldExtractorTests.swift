import Foundation
import Testing
@testable import Genki

/// All report text here is fictional (non-negotiable 4).
struct HealthFieldExtractorTests {
    // MARK: Text fields

    /// `@Test` arguments must be `Sendable`; key paths are not, so the
    /// field under test is named by this enum instead.
    enum Field: Sendable {
        case hospitalName, department, doctorName, medicalRecordNumber
        case visitReason, diagnosisOrConclusion, examinationResults
        case medications, doctorAdvice

        func value(in fields: ExtractedHealthFields) -> String? {
            switch self {
            case .hospitalName: fields.hospitalName
            case .department: fields.department
            case .doctorName: fields.doctorName
            case .medicalRecordNumber: fields.medicalRecordNumber
            case .visitReason: fields.visitReason
            case .diagnosisOrConclusion: fields.diagnosisOrConclusion
            case .examinationResults: fields.examinationResults
            case .medications: fields.medications
            case .doctorAdvice: fields.doctorAdvice
            }
        }
    }

    @Test(
        "Each labelled field is extracted, with ASCII or full-width colons",
        arguments: [
            ("示例市第一人民医院 门诊病历", Field.hospitalName, "示例市第一人民医院"),
            ("示例社区卫生院", .hospitalName, "示例社区卫生院"),
            ("示例健康体检中心 报告", .hospitalName, "示例健康体检中心"),
            ("科室：眼科", .department, "眼科"),
            ("就诊科室: 普通内科", .department, "普通内科"),
            ("医师：王示例", .doctorName, "王示例"),
            ("报告医师 李示例", .doctorName, "李示例"),
            ("门诊号：DEMO-001", .medicalRecordNumber, "DEMO-001"),
            ("住院号:ZY2026", .medicalRecordNumber, "ZY2026"),
            ("主诉：咽痛两天", .visitReason, "咽痛两天"),
            ("就诊原因: 年度复查", .visitReason, "年度复查"),
            ("诊断：急性上呼吸道感染", .diagnosisOrConclusion, "急性上呼吸道感染"),
            ("检查结论：未见明显异常", .diagnosisOrConclusion, "未见明显异常"),
            ("印象：双眼轻度近视", .diagnosisOrConclusion, "双眼轻度近视"),
            ("检查所见：双肺纹理清晰", .examinationResults, "双肺纹理清晰"),
            ("检验结果: 指标在参考范围内", .examinationResults, "指标在参考范围内"),
            ("处方：示例片 每日一次", .medications, "示例片 每日一次"),
            ("药品名称：示例胶囊", .medications, "示例胶囊"),
            ("医嘱：多饮水，注意休息", .doctorAdvice, "多饮水，注意休息"),
            ("处理意见: 一周后复诊", .doctorAdvice, "一周后复诊"),
        ]
    )
    func extractsLabelledField(text: String, field: Field, expected: String) {
        let fields = HealthFieldExtractor.extract(from: text)

        #expect(field.value(in: fields) == expected)
    }

    @Test("Surrounding whitespace is trimmed from a value")
    func trimsValues() {
        let fields = HealthFieldExtractor.extract(from: "主诉：   咽痛两天   ")

        #expect(fields.visitReason == "咽痛两天")
    }

    @Test("A value shorter than two characters yields nothing")
    func ignoresTooShortValues() {
        #expect(HealthFieldExtractor.extract(from: "诊断：无").diagnosisOrConclusion == nil)
    }

    /// Pinned on purpose. OCR often splits a label and its value onto two
    /// lines, so a label alone on its line takes the next line. The flip
    /// side, where the next line is another label, is tracked as T-042.
    @Test("A label alone on its line takes the value from the next line")
    func readsValueFromNextLine() {
        let fields = HealthFieldExtractor.extract(from: "诊断：\n急性上呼吸道感染")

        #expect(fields.diagnosisOrConclusion == "急性上呼吸道感染")
    }

    @Test("Several fields come out of one multi-line report")
    func extractsAWholeReport() {
        let report = """
        示例市第一人民医院 门诊病历
        就诊日期：2026年3月5日
        科室：普通内科
        主诉：咽痛、鼻塞两天
        诊断：急性上呼吸道感染
        医嘱：多饮水并充分休息
        """

        let fields = HealthFieldExtractor.extract(from: report)

        #expect(fields.hospitalName == "示例市第一人民医院")
        #expect(fields.department == "普通内科")
        #expect(fields.visitReason == "咽痛、鼻塞两天")
        #expect(fields.diagnosisOrConclusion == "急性上呼吸道感染")
        #expect(fields.doctorAdvice == "多饮水并充分休息")
        #expect(fields.occurredAt.map(Self.dayComponents) == DateComponents(year: 2026, month: 3, day: 5))
    }

    @Test("Text without any known label extracts nothing")
    func extractsNothingFromUnlabelledText() {
        let fields = HealthFieldExtractor.extract(from: "这是一段没有任何标签的文字")

        #expect(fields.occurredAt == nil)
        #expect(fields.hospitalName == nil)
        #expect(fields.department == nil)
        #expect(fields.doctorName == nil)
        #expect(fields.medicalRecordNumber == nil)
        #expect(fields.visitReason == nil)
        #expect(fields.diagnosisOrConclusion == nil)
        #expect(fields.examinationResults == nil)
        #expect(fields.medications == nil)
        #expect(fields.doctorAdvice == nil)
    }

    // MARK: Category

    @Test(
        "Report-type keywords suggest a category; checkup wins over test",
        arguments: [
            ("示例健康体检报告", HealthRecordCategory?.some(.checkup)),
            ("血常规 检验报告", .test),
            ("胸部 CT 检查报告", .test),
            ("年度体检 检查报告", .checkup),
            ("门诊病历", nil),
        ]
    )
    func suggestsCategory(text: String, expected: HealthRecordCategory?) {
        #expect(HealthFieldExtractor.extract(from: text).category == expected)
    }

    // MARK: Dates

    @Test(
        "Dates in 年月日, slash, dot and dash formats are parsed",
        arguments: [
            "就诊日期：2026年3月5日",
            "检查日期: 2026/03/05",
            "体检日期 2026.3.5",
            "报告日期：2026-03-05",
            "日期：2026年03月05",
        ]
    )
    func parsesDate(text: String) throws {
        let date = try #require(HealthFieldExtractor.extract(from: text).occurredAt)

        #expect(Self.dayComponents(date) == DateComponents(year: 2026, month: 3, day: 5))
    }

    @Test(
        "Impossible calendar dates are rejected",
        arguments: ["日期：2026-13-01", "日期：2026-02-30", "日期：2026-00-10"]
    )
    func rejectsImpossibleDate(text: String) {
        #expect(HealthFieldExtractor.extract(from: text).occurredAt == nil)
    }

    @Test("A year outside 20xx is not treated as a report date")
    func ignoresNonReportYears() {
        #expect(HealthFieldExtractor.extract(from: "日期：1999-03-05").occurredAt == nil)
    }

    private static func dayComponents(_ date: Date) -> DateComponents {
        Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date)
    }
}
