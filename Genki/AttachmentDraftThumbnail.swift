import SwiftUI

/// A not-yet-saved attachment in the add-record form, with a remove button.
struct AttachmentDraftThumbnail: View {
    let attachment: AttachmentDraft
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let image = UIImage(data: attachment.data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "doc")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 88, height: 104)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.55))
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .padding(5)
            .accessibilityLabel("移除\(attachment.displayName)")
        }
    }
}
