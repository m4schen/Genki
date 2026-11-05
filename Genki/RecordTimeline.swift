import Foundation

/// One month of the record list.
struct RecordMonthSection: Identifiable {
    let month: Date
    let records: [HealthRecord]

    var id: Date { month }
}

extension HealthRecord {
    /// Every field the search box looks in. Add a field here, and only here.
    var searchableFields: [String] {
        [
            hospitalName,
            department,
            doctorName,
            categoryTitle,
            visitReason,
            diagnosisOrConclusion,
            examinationResults,
            medications,
            doctorAdvice,
            notes,
            rawOCRText,
        ]
    }
}

/// The list screen's rules: which records match a search, and how they're
/// grouped by month. These are plain functions, so they're unit-tested.
enum RecordTimeline {
    /// Records whose searchable fields contain the query, in their original
    /// order. Matching ignores case and diacritics. A blank query matches
    /// everything.
    static func filter(_ records: [HealthRecord], matching query: String) -> [HealthRecord] {
        let query = query.trimmed
        guard !query.isEmpty else { return records }

        return records.filter { record in
            record.searchableFields.contains { $0.localizedStandardContains(query) }
        }
    }

    /// One section per calendar month, newest first. Records keep their order
    /// within a month.
    static func monthSections(
        of records: [HealthRecord],
        calendar: Calendar = .current
    ) -> [RecordMonthSection] {
        Dictionary(grouping: records) { record in
            calendar.dateInterval(of: .month, for: record.occurredAt)?.start
                ?? calendar.startOfDay(for: record.occurredAt)
        }
        .map { RecordMonthSection(month: $0.key, records: $0.value) }
        .sorted { $0.month > $1.month }
    }
}
