import Dependencies
import XCTestDynamicOverlay

// MARK: - PasteboardClient + TestDependencyKey
extension PasteboardClient: TestDependencyKey {
	public static let previewValue = Self(
		copyString: { _ in },
		getString: { nil }
	)

	public static let testValue = Self(
		copyString: unimplemented("\(Self.self).copyString"),
		getString: unimplemented("\(Self.self).getString")
	)
}

public extension DependencyValues {
	var pasteboardClient: PasteboardClient {
		get { self[PasteboardClient.self] }
		set { self[PasteboardClient.self] = newValue }
	}
}
