import Foundation
import Vision

// MARK: - OCR

/// Boundary to Apple Vision. Recognition runs on the device and off the
/// main thread; nothing leaves the device (non-negotiable 1).
enum OCRService {
    nonisolated static let pageSeparator = "\n\n—— 下一页 ——\n\n"

    static func recognize(imageData: [Data]) async throws -> String {
        guard !imageData.isEmpty else {
            throw OCRError.noImages
        }

        return try await Task.detached(priority: .userInitiated) {
            try recognizeSynchronously(imageData: imageData)
        }.value
    }

    private nonisolated static func recognizeSynchronously(
        imageData: [Data]
    ) throws -> String {
        var pages: [String] = []

        for data in imageData {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]
            request.usesLanguageCorrection = true

            try VNImageRequestHandler(data: data).perform([request])

            let lines = (request.results ?? []).compactMap {
                $0.topCandidates(1).first?.string
            }
            let text = lines.joined(separator: "\n")
            if !text.isEmpty {
                pages.append(text)
            }
        }

        return pages.joined(separator: pageSeparator)
    }
}

enum OCRError: LocalizedError {
    case noImages

    var errorDescription: String? {
        switch self {
        case .noImages: String(localized: "没有可识别的图片。")
        }
    }
}

// MARK: - Field extraction

/// Suggestions parsed from OCR text. `nil` means "no suggestion". It
/// never means "the report says this field is empty".
nonisolated struct ExtractedHealthFields: Equatable, Sendable {
    var occurredAt: Date?
    var category: HealthRecordCategory?
    var hospitalName: String?
    var department: String?
    var doctorName: String?
    var medicalRecordNumber: String?
    var visitReason: String?
    var diagnosisOrConclusion: String?
    var examinationResults: String?
    var medications: String?
    var doctorAdvice: String?
}

/// Turns raw OCR text into typed suggestions, in one place (Boundary
/// Discipline). It's a pure function of its input, so every rule is unit-tested.
nonisolated enum HealthFieldExtractor {
    static func extract(from text: String) -> ExtractedHealthFields {
        ExtractedHealthFields(
            occurredAt: reportDate(in: text),
            category: category(in: text),
            hospitalName: firstValue(in: text, matching: FieldPattern.hospitalName),
            department: firstValue(in: text, matching: FieldPattern.department),
            doctorName: firstValue(in: text, matching: FieldPattern.doctorName),
            medicalRecordNumber: firstValue(in: text, matching: FieldPattern.medicalRecordNumber),
            visitReason: firstValue(in: text, matching: FieldPattern.visitReason),
            diagnosisOrConclusion: firstValue(in: text, matching: FieldPattern.diagnosisOrConclusion),
            examinationResults: firstValue(in: text, matching: FieldPattern.examinationResults),
            medications: firstValue(in: text, matching: FieldPattern.medications),
            doctorAdvice: firstValue(in: text, matching: FieldPattern.doctorAdvice)
        )
    }

    // MARK: Rules

    private static func firstValue(
        in text: String,
        matching pattern: Regex<(Substring, Substring)>
    ) -> String? {
        guard let match = text.firstMatch(of: pattern) else { return nil }

        let value = String(match.1).trimmed
        return value.isEmpty ? nil : value
    }

    /// A checkup report usually also contains the word "检查报告", so the
    /// checkup keyword wins.
    private static func category(in text: String) -> HealthRecordCategory? {
        if text.contains("体检") { return .checkup }
        if text.contains("检验报告") || text.contains("检查报告") { return .test }
        return nil
    }

    private static func reportDate(in text: String) -> Date? {
        // Captures year, month and day. The regex literal is checked by the
        // compiler, like the patterns in `FieldPattern`.
        let reportDate = #/(?:就诊日期|检查日期|体检日期|报告日期|日期)\s*[:：]?\s*(20\d{2})[年./-](\d{1,2})[月./-](\d{1,2})/#

        guard
            let match = text.firstMatch(of: reportDate),
            let year = Int(match.1),
            let month = Int(match.2),
            let day = Int(match.3)
        else {
            return nil
        }

        return validDate(year: year, month: month, day: day)
    }

    /// `Calendar` silently rolls an impossible date such as 2026-02-30 over
    /// to 2026-03-02, so a date is accepted only if it round-trips.
    private static func validDate(year: Int, month: Int, day: Int) -> Date? {
        let calendar = Calendar(identifier: .gregorian)
        let requested = DateComponents(year: year, month: month, day: day)

        guard
            let date = calendar.date(from: requested),
            calendar.dateComponents([.year, .month, .day], from: date) == requested
        else {
            return nil
        }

        return date
    }
}

// MARK: - Patterns

/// Regex literals are checked by the compiler, so a typo is a build
/// error, not a field that silently never matches.
///
/// A value must start with a visible character that isn't a colon, so a
/// bare "诊断：无" can't turn the colon into the value.
///
/// These are computed rather than stored: `Regex` isn't `Sendable`, so a
/// shared instance would be a data race under Swift 6.
private nonisolated enum FieldPattern {
    typealias OneCapture = Regex<(Substring, Substring)>

    static var hospitalName: OneCapture {
        #/([^\n]{2,30}(?:医院|卫生院|医疗中心|体检中心))/#
    }

    static var department: OneCapture {
        #/(?:就诊科室|检查科室|科室)\s*[:：]?\s*([^\s，,。;；:：]{2,20})/#
    }

    static var doctorName: OneCapture {
        #/(?:医生|医师|检查医师|报告医师)\s*[:：]?\s*([^\s，,。;；:：]{2,12})/#
    }

    static var medicalRecordNumber: OneCapture {
        #/(?:病历号|病案号|门诊号|住院号|报告编号)\s*[:：]?\s*([A-Za-z0-9-]+)/#
    }

    static var visitReason: OneCapture {
        #/(?:就诊原因|主诉)\s*[:：]?\s*([^\s:：][^\n]{1,199})/#
    }

    static var diagnosisOrConclusion: OneCapture {
        #/(?:诊断结果|临床诊断|初步诊断|检查结论|诊断|结论|印象)\s*[:：]?\s*([^\s:：][^\n]{1,299})/#
    }

    static var examinationResults: OneCapture {
        #/(?:检查所见|检查结果|检验结果|体检结果)\s*[:：]?\s*([^\s:：][^\n]{1,499})/#
    }

    static var medications: OneCapture {
        #/(?:处方|用药|药品名称)\s*[:：]?\s*([^\s:：][^\n]{1,299})/#
    }

    static var doctorAdvice: OneCapture {
        #/(?:医嘱|医生建议|处理意见|建议)\s*[:：]?\s*([^\s:：][^\n]{1,299})/#
    }
}
