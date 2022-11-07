import Dependencies
import XCTestDynamicOverlay

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
