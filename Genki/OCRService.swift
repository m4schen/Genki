import Foundation
import Vision

enum OCRService {
    static func recognize(imageData: [Data]) async throws -> String {
        guard !imageData.isEmpty else {
            throw OCRError.invalidImage
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

        return pages.joined(separator: "\n\n—— 下一页 ——\n\n")
    }
}

enum OCRError: LocalizedError {
    case invalidImage

    var errorDescription: String? {
        "无法读取所选图片。"
    }
}

struct ExtractedHealthFields {
    var occurredAt: Date?
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

enum HealthFieldExtractor {
    static func extract(from text: String) -> ExtractedHealthFields {
        let dateText = firstMatch(
            in: text,
            patterns: [
                #"(?:就诊日期|检查日期|体检日期|报告日期|日期)\s*[:：]?\s*(20\d{2}[年./-]\d{1,2}[月./-]\d{1,2}日?)"#,
            ]
        )

        return ExtractedHealthFields(
            occurredAt: dateText.flatMap(parseDate),
            hospitalName: firstMatch(
                in: text,
                patterns: [#"([^\n]{2,30}(?:医院|卫生院|医疗中心|体检中心))"#]
            ),
            department: firstMatch(
                in: text,
                patterns: [
                    #"(?:就诊科室|检查科室|科室)\s*[:：]?\s*([^\s，,。;；]{2,20})"#,
                ]
            ),
            doctorName: firstMatch(
                in: text,
                patterns: [
                    #"(?:医生|医师|检查医师|报告医师)\s*[:：]?\s*([^\s，,。;；]{2,12})"#,
                ]
            ),
            medicalRecordNumber: firstMatch(
                in: text,
                patterns: [
                    #"(?:病历号|病案号|门诊号|住院号|报告编号)\s*[:：]?\s*([A-Za-z0-9-]+)"#,
                ]
            ),
            visitReason: firstMatch(
                in: text,
                patterns: [
                    #"(?:就诊原因|主诉)\s*[:：]?\s*([^\n]{2,200})"#,
                ]
            ),
            diagnosisOrConclusion: firstMatch(
                in: text,
                patterns: [
                    #"(?:诊断结果|临床诊断|初步诊断|检查结论|诊断|结论|印象)\s*[:：]?\s*([^\n]{2,300})"#,
                ]
            ),
            examinationResults: firstMatch(
                in: text,
                patterns: [
                    #"(?:检查所见|检查结果|检验结果|体检结果)\s*[:：]?\s*([^\n]{2,500})"#,
                ]
            ),
            medications: firstMatch(
                in: text,
                patterns: [
                    #"(?:处方|用药|药品名称)\s*[:：]?\s*([^\n]{2,300})"#,
                ]
            ),
            doctorAdvice: firstMatch(
                in: text,
                patterns: [
                    #"(?:医嘱|医生建议|处理意见|建议)\s*[:：]?\s*([^\n]{2,300})"#,
                ]
            )
        )
    }

    private static func firstMatch(in text: String, patterns: [String]) -> String? {
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                continue
            }

            let fullRange = NSRange(text.startIndex..., in: text)
            guard
                let match = regex.firstMatch(in: text, range: fullRange),
                match.numberOfRanges > 1,
                let valueRange = Range(match.range(at: 1), in: text)
            else {
                continue
            }

            let value = text[valueRange].trimmingCharacters(in: .whitespacesAndNewlines)
            if !value.isEmpty {
                return value
            }
        }

        return nil
    }

    private nonisolated static func parseDate(_ text: String) -> Date? {
        let normalized = text
            .replacingOccurrences(of: "年", with: "-")
            .replacingOccurrences(of: "月", with: "-")
            .replacingOccurrences(of: "日", with: "")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ".", with: "-")

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-M-d"
        return formatter.date(from: normalized)
    }
}
