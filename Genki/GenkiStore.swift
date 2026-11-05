import SwiftData
import SwiftUI

/// Where the archive lives: one SwiftData store on the device, with CloudKit
/// off (D-001). The app and the tests both open it through here, so they use
/// the same schema.
enum GenkiStore {
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            HealthRecord.self,
            RecordAttachment.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}

/// Shown when the store can't be opened, for example after a failed
/// migration. The app explains the problem instead of crashing on every
/// launch, and it doesn't touch the data on disk (non-negotiable 3).
struct StoreUnavailableView: View {
    let error: any Error

    var body: some View {
        ContentUnavailableView {
            Label("无法打开健康记录", systemImage: "exclamationmark.triangle")
        } description: {
            Text("你的记录仍保存在本机，没有被删除。请重新打开应用；如果问题持续，请更新到最新版本。")
            Text(error.localizedDescription)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
