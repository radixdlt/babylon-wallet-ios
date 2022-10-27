#if DEBUG
import Dependencies
import XCTestDynamicOverlay

extension PasteboardClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		copyString: XCTUnimplemented("\(Self.self).copyString"),
		getString: XCTUnimplemented("\(Self.self).getString")
	)
}

public extension PasteboardClient {
	static let noop = Self(
		copyString: { _ in },
		getString: { nil }
	)
}
#endif
