import Testing

/// Temporary: proves CI turns red when a test fails (T-020). Reverted in the
/// next commit.
struct CIRedCheckTests {
    @Test("Deliberate failure to prove CI goes red")
    func deliberatelyFails() {
        #expect(Bool(false), "Deliberate failure for T-020; this commit gets reverted")
    }
}
