#if DEBUG
import Foundation
import XCTestDynamicOverlay

public extension PasteboardClient {
	static let noop = Self(
		copyString: { _ in },
		getString: { nil }
	)

	static let unimplemented = Self(
		copyString: XCTUnimplemented("\(Self.self).copyString"),
		getString: XCTUnimplemented("\(Self.self).getString")
	)
}
#endif
