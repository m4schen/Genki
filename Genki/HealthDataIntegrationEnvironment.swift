import SwiftUI

private struct HealthDataIntegrationKey: EnvironmentKey {
    static let defaultValue = HealthDataIntegration.localOnly
}

extension EnvironmentValues {
    var healthDataIntegration: HealthDataIntegration {
        get { self[HealthDataIntegrationKey.self] }
        set { self[HealthDataIntegrationKey.self] = newValue }
    }
}
