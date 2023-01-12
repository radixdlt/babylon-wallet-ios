import Prelude
import XCTest

open class TestCase: XCTestCase {
	override open func setUp() {
		super.setUp()
		continueAfterFailure = false
	}
}
