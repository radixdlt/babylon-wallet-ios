#if os(macOS) // testing on macOS only as iOS requires prompt approval to copy-paste 🤦‍♂️
import Dependencies
import TestingPrelude

// MARK: - PasteboardClientTests
final class PasteboardClientTests: TestCase {
	func testCopyStringSetsStringToPasteboard() {
		DependencyValues.live.pasteboardClient.copyString("test")
		XCTAssertEqual(DependencyValues.live.pasteboardClient.getString(), "test")
	}
}
#endif
