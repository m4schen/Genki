import SwiftData
import SwiftUI

@main
struct GenkiApp: App {
    /// A store that can't be opened is recoverable, because the data is
    /// still on disk. So it becomes a screen, not a `fatalError`.
    private let store = Result { try GenkiStore.makeContainer() }

    var body: some Scene {
        WindowGroup {
            switch store {
            case .success(let container):
                ContentView()
                    .modelContainer(container)
            case .failure(let error):
                StoreUnavailableView(error: error)
            }
        }
    }
}
