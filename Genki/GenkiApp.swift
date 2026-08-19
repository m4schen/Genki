import SwiftData
import SwiftUI

@main
struct GenkiApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            HealthRecord.self,
            RecordAttachment.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.healthDataIntegration, .localOnly)
        }
        .modelContainer(sharedModelContainer)
    }
}
