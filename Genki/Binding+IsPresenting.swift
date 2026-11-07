import SwiftUI

extension Binding where Value == Bool {
    /// `true` while `optional` holds a value. Setting it to `false` clears the
    /// value. This drives an alert or dialog from an optional, so "showing"
    /// and "what to show" can't disagree.
    init<Wrapped>(isPresenting optional: Binding<Wrapped?>) {
        self.init(
            get: { optional.wrappedValue != nil },
            set: { isPresented in
                if !isPresented {
                    optional.wrappedValue = nil
                }
            }
        )
    }
}
