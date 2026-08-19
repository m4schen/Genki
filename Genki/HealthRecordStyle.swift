import SwiftUI

extension HealthRecordCategory {
    var symbolName: String {
        switch self {
        case .visit: "cross.case.fill"
        case .checkup: "heart.text.clipboard.fill"
        case .test: "waveform.path.ecg"
        case .other: "folder.fill"
        }
    }

    var tint: Color {
        switch self {
        case .visit: .blue
        case .checkup: .green
        case .test: .purple
        case .other: .gray
        }
    }
}

extension AttachmentKind {
    var symbolName: String {
        switch self {
        case .document: "doc.text.fill"
        case .medicalImage: "viewfinder"
        case .photo: "photo.fill"
        case .other: "paperclip"
        }
    }
}
