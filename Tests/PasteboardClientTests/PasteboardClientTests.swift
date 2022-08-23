@testable import Common
import TestUtils

// MARK: - PasteboardClientTests
final class PasteboardClientTests: TestCase {
	private var sut: PasteboardClient!

	override func setUp() {
		super.setUp()
		sut = PasteboardClient.live
	}

	func testCopyStringSetsStringToPasteboard() {
		let aString = "test"
		sut.copyString(aString)
		XCTAssertEqual(sut.getString(), aString)
	}
}
