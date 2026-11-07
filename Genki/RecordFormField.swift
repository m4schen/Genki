/// The add-record form's text fields, and the order the keyboard's up and
/// down buttons move through them.
enum RecordFormField: Hashable {
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

    /// Fields in a collapsed section are skipped.
    static func focusOrder(isMoreExpanded: Bool, isOCRExpanded: Bool) -> [Self] {
        var fields: [Self] = [.hospital, .department, .conclusion]
        if isMoreExpanded {
            fields += [.reason, .results, .advice, .medications, .doctor, .recordNumber, .notes]
        }
        if isOCRExpanded {
            fields.append(.ocr)
        }
        return fields
    }

    /// The field `offset` steps away in `order`. Returns `nil` past either
    /// end, or when this field isn't in `order`.
    func adjacent(by offset: Int, in order: [Self]) -> Self? {
        guard let index = order.firstIndex(of: self) else { return nil }

        let destination = index + offset
        return order.indices.contains(destination) ? order[destination] : nil
    }
}
