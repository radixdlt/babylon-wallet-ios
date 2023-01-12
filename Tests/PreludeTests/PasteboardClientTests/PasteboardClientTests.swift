import Dependencies
import TestingPrelude

// MARK: - PasteboardClientTests
final class PasteboardClientTests: TestCase {
	func testCopyStringSetsStringToPasteboard() {
		DependencyValues.live.pasteboardClient.copyString("test")
		XCTAssertEqual(DependencyValues.live.pasteboardClient.getString(), "test")
	}
}
