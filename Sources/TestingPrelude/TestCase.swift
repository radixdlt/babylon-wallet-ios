import TestingPrelude

open class TestCase: XCTestCase {
	override open func setUp() {
		super.setUp()
		continueAfterFailure = false
	}
}
