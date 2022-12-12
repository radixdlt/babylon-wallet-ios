import Dependencies
import XCTestDynamicOverlay

// MARK: - PasteboardClient + TestDependencyKey
extension PlatformEnvironmentClient: TestDependencyKey {
        public static let testValue = Self(
                isSimulator: unimplemented("\(Self.self).copyString")
        )
}

public extension DependencyValues {
        var platformEnvironmnetClient: PlatformEnvironmnetClient {
                get { self[PlatformEnvironmnetClient.self] }
                set { self[PlatformEnvironmnetClient.self] = newValue }
        }
}
